## State of Log Rotation in Kubernetes

- Not natively handled by Kubernetes. Kubernetes uses container runtime's logging drivers for `kubectl logs`
- Use deployment tools or tune container runtime on the node to achieve this 

### Resources/Background

- logging-drivers in docker: https://docs.docker.com/config/containers/logging/configure/

- Default logging driver: `json-file`. Logs are typically stdout/stderr streams that are placed 
  by default into .log files at /var/lib/docker/containers (symlink at /var/log/containers)

- How to check which logging-driver is in use: `docker info`. For individual container, `docker inspect` 

- Apart from the pod (app container) logs stored as discussed above, there are kubernetes system components 
(kubelet, scheduler, proxy). These either log to journald if they are systemd services, or to /var/log if
they are running in containers (not pods)

- Generally, logging agents such as fluentd are configured to _read off these_ files and stream it to remote 
search systems like ElasticSearch.  

## Suggestions/Workarounds to achieve Log-Rotation:

- Having a separate partition on the root disk for `/var` so that 100% usage of root partition doesn't occur

### logrotate

  - About logrotate: https://kubernetes.io/docs/concepts/cluster-administration/logging/#logging-at-the-node-level
  - Man Page: https://linux.die.net/man/8/logrotate
  - Example setup: https://github.com/kubernetes/kubernetes/blob/master/cluster/gce/gci/configure-helper.sh#L358
    
  - cons: 
      - copytruncate mode causes broken/truncated lines can cause logging agents like fluentd (which parse these files) 
        to enter CrashLoopBackOff
      - logging agents make use of read offsets, but copytruncate mode renders some offsets invalid
      - not a 'highly scalable' solution for verbose applications (if set hourly etc.,)
       
        - https://github.com/kubernetes/kubernetes/issues/28369
        - https://github.com/kubernetes/kubernetes/issues/37292
        - https://github.com/kubernetes/kubernetes/issues/29715

  - pros: 
      - can take care of node-level log space consumption concerns 
      - based on directory - can be used with script modifications 

### Docker logging driver configuration

- Configure native docker logging driver `--log-driver` with options `--log-opt` to enforce log rotation
  `max-size`, `max-file`
  
  Ref: https://docs.docker.com/config/containers/logging/json-file/#options

- pros: 
    - settable per container or node-wide (daemon-level - /etc/docker/daemon.json) 
    - cleaner than logrotate scripts - no broken lines or invalidated offsets 
    - supported by: local, json-file
  
- cons: 
    - this is a manual cluster setup action (node-wide/daemon-level change has to be recommended to admin)
    - pod-level log-opts cannot be done by kubelet 

- Log options `--log-opt` are automatically configured for clusters brought up via *kube-up.sh* OR ones brought up by GKE 
  (refer: https://github.com/kubernetes/kubernetes/pull/40634). Default values are: *10MB* size, retention upto *5* 
  logfiles. Similar step has to be performed by others in their deployment/bring-up scripts.

  ```
  root@gke-playground-default-pool-1b790f33-bktt:~# docker ps | grep node-disk-manager
  6eb93137cc84        quay.io/openebs/node-disk-manager-amd64@sha256:0b278b49c18698d8f1bb85b8dfe66e22be33ee7a157cc061900eb300dfa13a7f               "/usr/local/bin/en..."   4 days ago          Up 4 days                               k8s_node-disk-manager_openebs-ndm-fx5mv_openebs_907fae78-8037-11e9-b6bb-42010a8000f6_0

  root@gke-playground-default-pool-1b790f33-bktt:~# docker inspect -f '{{.HostConfig.LogConfig}}' 6eb93137cc84
  {json-file map[max-file:5 max-size:10m]}
  ```
### Notes: 

  - Seems that this is being enforced by popular baremetal/cloud provisioning tools like kubespray/kops: 

    - https://github.com/kubernetes-sigs/kubespray/blob/master/inventory/sample/group_vars/all/docker.yml#L24
    - https://github.com/kubernetes/kops/blob/083e29e510c20cc92dfe22a5d7e118f24cca3e43/nodeup/pkg/model/docker_test.go#L59 

  - In case of OpenShift, docs recommend updating the /etc/docker/daemon.json (which, by default, is empty). 
    The terminology used here is "aggregated-logging" to differentiate it from the logging tunables specified
    in the openshift-ansible inventory file for EFK.
    
    - https://docs.openshift.com/container-platform/3.11/install_config/aggregate_logging.html#fluentd-update-source

## Possible Actions wrt OpenEBS Users

- Encourage tuning the docker daemons on the clusters via methods specified above

- Update K8s bring up playbooks in Litmus (packet, openshift) to take logging-driver & log-opts as variables

- Create a ready to use logrotate service template for use/sharing w/ users 

- In case the logs are not the ones streamed to stdout - and are maintained in separate logfiles in the container, 
  a logrotate sidecar should be attempted. 

  Ref: https://stackoverflow.com/questions/52814951/kubernetes-with-logrotate-sidecar-mount-point-issue

- A logrotate daemonset is another approach.
   
## Other Useful Info On Kubernetes Logging 

An aggregated list of resources for sub-topics under Kubernetes logging that are being discussed/worked-on in the 
community is placed here. Broad categorization is as below: 

- How to 'capture' these logs (in other words, which logging driver to use by default) 
  - Stream stdout/stderr to logfiles & parse them (today's default)
  - Stream to journald 
  - Stream to fluentd over network directly rather than have it parse logfiles like today

  Ref: https://github.com/kubernetes/kubernetes/issues/24677

- Location of logfiles 
  - Default before 1.12.6 - `/var/lib/docker/containers`. There were symlinks in `/var/log/containers`
  - 1.12.6+ -> `/var/lib/docker/containers` is replaced by `/var/log/pods/UID.../*logs`
  - Apparently this breaks fluentd (the default config looks for files in `/var/lib/docker/containers` to parse)

  Ref: https://github.com/kubernetes/kubernetes/issues/53022

- Metadata injection to the default logs (stdout/strerr) 

  - Logs need enrichment before being pushed out. 
    Ref: https://github.com/kubernetes/kubernetes/issues/24677#issuecomment-215968351

- Proposal to define a `LogDir` field in containerSpec or `LoggingVolume` volume plugin type in Kubernetes
  Make it a "first-class" citizen in Kubernetes. 

  Ref: https://github.com/kubernetes/kubernetes/pull/13010

  Another elaborate proposal (more of requirement doc) for LoggingVolumes is here:

  Ref: https://docs.google.com/document/d/1K2hh7nQ9glYzGE-5J7oKBB7oK3S_MKqwCISXZK-sB2Q/edit#

- New Kubernetes Logging Proposal by CRI addressing a subset of the above issues:

  - Ref: https://github.com/kubernetes/community/blob/master/contributors/design-proposals/node/kubelet-cri-logging.md
  - Related Issues: https://github.com/kubernetes/kubernetes/issues/59902

## Storage for Logs 

- While logging systems are being proposed & workarounds are being found, there are requests for disk-quota 
(runtime storage) specification for a pod (as docker already supports quotas in its storage-drivers, i,e., overlayfs)

- Refer:
  - https://github.com/kubernetes/kubernetes/issues/54384 
  - https://github.com/kubernetes/kubernetes/pull/66928




