# Monitoring Notes for Kubernetes Cluster (w/ focus on OpenEBS Volumes)

THe monitoring & observability artifacts provided in the OpenEBS repo as aids to the Kubernetes developers/SREs cover the following areas: 

- Metrics Collection & Visualization 
- Logging 
- Alerting

This README summarizes recommended usage steps & provides notes on specific components. This doc will be updated periodically as newer components are 
introduced, or solutions found to challenges listed. Mostly, these manifests are collections of standard deployment specs of popular opensource tools, 
tweaked slightly to suit the OpenEBS context, where necessary. 

## Metrics Collection & Visualization

The metrics are collected by a set of prometheus exporters & pulled periodically (scrape_interval) by the Prometheus server. Grafana is used to 
visualize the metrics collected by prometheus, with dashboards constructed using appropriate prom queries. 

- Manifest: https://github.com/openebs/openebs/blob/master/k8s/openebs-monitoring-pg.yaml (prometheus, grafana)
  
- Areas to note: 
  
  - Prometheus TSDB uses emptyDir{} as the storage backendm with 24 hr retention. 
  - Has prometheus configmaps for both both alert-rules and scrape job configuration for all exporters (list detailed below) 
  - Grafana uses basic auth

The metrics collected from the cluster are: 
 
- **OpenEBS volume & pool metrics**: Available for Jiva and cStor. These are collected by prometheus exporters that are launched as sidecars 
  in the volume target and pool deployments by Maya

  - Areas to note: 

      - Monitoring is enabled by default for the OpenEBS storage class

  - Grafana dashboard: 

      - Volume stats: https://github.com/openebs/openebs/blob/master/k8s/openebs-pg-dashboard.json
      - Pool stats: https://github.com/openebs/openebs/blob/master/k8s/openebs-pool-exporter.json

- **Node metrics**: Collected by the prometheus node exporter, launched as a daemonset. 

  - Manifest: https://github.com/openebs/openebs/blob/master/k8s/openebs-monitoring-pg.yaml#L369

  - Areas to note: 
 
      - root fs ("/") is mounted with mountPropagation `HostToContainer`& as Read-Only mount. This is to enable detecting fs mounts made 
      after launching the ds.

      - Ignored mounted fs include "/var/lib" (instead of the default /var/lib/docker) and "/home/kubernetes" to avoid monitoring transient mounts 
      into the /var/lib/kubelet. The idea is they are anyways tracked under the "/" which is mounted on the root disk (typically partition of sda or lvm)

  - Grafana dashboard: https://github.com/openebs/openebs/blob/master/k8s/openebs-node-exporter.json

- **Kubernetes (Object) resource metrics**: Collected by the kube-state-metrics which generates the metrics from the kubernetes APIs. 

  - Manifest: https://github.com/openebs/openebs/blob/master/k8s/openebs-kube-state-metrics.yaml
  
  - Grafana dashboard: https://github.com/openebs/openebs/blob/master/k8s/openebs-kube-state-metrics.json

- **Kubelet & Container metrics**: cAdvisor (Container Advisor) provides resource usage and performance characteristics of the running containers

    - Manifest (scrape job): https://github.com/openebs/openebs/blob/master/k8s/openebs-monitoring-pg.yaml#L129

    - Grafana dashboard: https://github.com/openebs/openebs/blob/master/k8s/openebs-kubelet-cAdvisor.json

### Challenges

One of the challenges is in obtaining the utilization metrics for individual (specifically, Local) PV mounts, though the impact of aggregated usage 
can be obtained from the pool (mounted) disk, i.e., one contributing to the backend storage of PVs. Ideal requirement is to gauge utilization per mount
as in the way of other mounted disks. The current limitation in achieving this with the current node-exporter daemonset (as is) is:

- The PV is mounted at `/var/lib/kubelet/<pod_id>/<plugin_path>/<pv_name>`. While with mountPropagation set on the node-exporter container, these mounts can be
  auto-detected/monitored, the `/var/lib/kubelet` contains several other mounts whose monitoring may not be *desired* or is *redundant*. Such as: `/var/lib/kubelet` 
  parent path itself,which is mounted on the root disk typically.

- Note: The PVC/PV size is obtained from the kube-state-metrics though

Some of the issues & articles around obtaining volume utilization metrics include: 
  
- https://github.com/coreos/prometheus-operator/issues/2359
- https://stackoverflow.com/questions/55899797/how-to-monitor-disk-usage-of-persistent-volumes
- https://bugzilla.redhat.com/show_bug.cgi?id=1373288

Alternate ways to do this:


#### Case-1: Using the textfile collector of node-exporter:

- This approach uses a custom collection script that queries the following & places them in textfiles in a format understood by the textfile collector of the 
  node-exporter, which then renders them as prometheus metrics. This needs the script to run as a sidecar to the node-exporter and share a similar set of volume 
  mounts. 

  - PV size via kubectl
  - PV utilization via a `du` command on the PV mount points

- Explained in detail at: https://github.com/litmuschaos/test-tools/pull/93

- May need to run as a deployment sidecar, with maincar as node-exporter with **only** `--collector.textfile` arg enabled.

#### Case-2: Query the kubelet `/metrics` endpoint via another exporter (need to explore):

- https://github.com/google/cadvisor/issues/1702 (useful). There is a way do to this by constructing queries around `kubelet_volume_stats_available_bytes` & 
  `kubelet_volume_stats_capacity_bytes` --> This needs to be explored (metrics are not available from cAdvisor endpoint, seems like need to query separately from *kubelet's*
  */metrics* endpoints

- Related:
  - https://github.com/kubernetes/kubernetes/issues/62644

- O/P of kubelet_volume metrics query (with OpenEBS volumes)on a node: 

```
root@gke-playground-default-pool-37e10f0d-ffkx:~# curl -s localhost:10255/metrics | grep volume | grep persistent

kubelet_volume_stats_available_bytes{namespace="default",persistentvolumeclaim="demo-vol1-claim"} 2.333954048e+09
kubelet_volume_stats_available_bytes{namespace="default",persistentvolumeclaim="demo-vol2-claim"} 2.884583424e+09
kubelet_volume_stats_capacity_bytes{namespace="default",persistentvolumeclaim="demo-vol1-claim"} 5.21732096e+09
kubelet_volume_stats_capacity_bytes{namespace="default",persistentvolumeclaim="demo-vol2-claim"} 5.21732096e+09
kubelet_volume_stats_inodes{namespace="default",persistentvolumeclaim="demo-vol1-claim"} 327680
kubelet_volume_stats_inodes{namespace="default",persistentvolumeclaim="demo-vol2-claim"} 327680
kubelet_volume_stats_inodes_free{namespace="default",persistentvolumeclaim="demo-vol1-claim"} 327372
kubelet_volume_stats_inodes_free{namespace="default",persistentvolumeclaim="demo-vol2-claim"} 327379
kubelet_volume_stats_inodes_used{namespace="default",persistentvolumeclaim="demo-vol1-claim"} 308
kubelet_volume_stats_inodes_used{namespace="default",persistentvolumeclaim="demo-vol2-claim"} 301
kubelet_volume_stats_used_bytes{namespace="default",persistentvolumeclaim="demo-vol1-claim"} 2.866589696e+09
kubelet_volume_stats_used_bytes{namespace="default",persistentvolumeclaim="demo-vol2-claim"} 2.31596032e+09
```


