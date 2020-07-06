Hi everyone! I am Konda Reddy, an SRE with F5 Networks & an avid Chaos Engineering enthusiast. Of late, I have been playing around with the LitmusChaos framework to inject chaos on Kafka deployments. This is my first post on the DEV platform & I intend to share my experiences around Chaos Engineering with Kafka in a series of posts. This is the first one!

Stay tuned for more blogs around different chaos experiments on the various Kafka distributions and operators (kudos, confluent, Strimzi, Banzaicloud) for Kubernetes!

Before we begin, let us dwell a bit on the concept of "Data Engineering" & re-introduce ourselves to Kafka. 

# Evolution Of Data Engineering

Data Pipelines are the soul of Data-Driven Enterprises today, with analytics empowering organizations with crucial customer-experience information gathered via hyper-personalization. The data ecosystem has been evolving continuously, both in terms of processes as well as the infrastructure components supporting them as can be gauged from the paradigm shift from the old-world ETL to today’s distributed [data mesh](https://martinfowler.com/articles/data-monolith-to-mesh.html), where data is treated more like a “product” and less as an “aid” with domain-oriented data being managed by individual teams with cross-functional expertise.

This evolution has been accelerated in no small part due to the emergence of cloud-native architectures, more specifically, Kubernetes. With Kubernetes serving as the universal data plane substratum, the practices that are being applied to application development (DevOps) are being adopted for data engineering, resulting in “DataOps.” Therefore, the defining characteristic of DataOps is that the data infrastructure (typically comprising of end-to-end data-pipelines supported/fed by distributed message-queue and data-streaming platforms which in turn uses underlying cloud-native storage) is:

- Completely containerized
- Managed via versioned intent/(K8s) YAML files (GitOps)
- Subjected to the same principles of infra management (laid out by DevOps/SRE best-practices) as the so-called “business-logic” applications.

Refer to this [CNCF blog post](https://www.cncf.io/blog/2019/09/27/declarative-data-infrastructure-powers-the-data-driven-enterprise/) to understand more. 

# The Spectre Of Infra Failures

While the technical wisdom & accompanying cost-benefits of the approach mentioned above is apparent, it also comes with inherent challenges common to the migration of any distributed systems to Cloud/Kubernetes: Unanticipated Infrastructure Failures. Instance losses, pod failures, service crashes, network partitions, the latency on the pod-network, exhausted ephemeral storage, etc.., While the applications themselves are architected for resiliency, with Kubernetes also providing multiple constructs to maintain HA, there are still occasions when the data pipelines can misbehave, thereby resulting in an under-realized positive impact.

Having said that, one of the points mentioned above about DataOps, that the same SRE principles manage the data infrastructure as other applications makes it a candidate for Chaos Engineering. Periodic & deliberate fault injection, starting from the CI clusters, through staging, pre-pod & then to production environments, is necessary to validate hypotheses & ensure the desired behavior.

While application properties, state & dependencies of the data infrastructure components are managed in a declarative way, it is a natural expectation to manage the chaos intent against these in a declarative way too. Litmus, as you all know by now, is a cloud-native chaos engineering framework available for this very purpose. As a project gaining increasing traction within the chaos engineering community, it is beginning to add support for readily available application-specific chaos experiments, wherein the instance information, chaos tunables & result interface are all defined declaratively via Kubernetes Custom Resources, with a custom Chaos Operator executing the said chaos. To get a taste of chaos engineering with Litmus, try out the instructions in this excellent [Litmus Demo](https://dev.to/uditgaurav/get-started-with-litmuschaos-in-minutes-4ke1) blog by @uditgaurav.

*In this blog, we shall look at how Litmus, can be used to validate the deployment sanity of a Kafka statefulset, a real-time data streaming/message queueing platform which is a near-indispensable part of any data pipeline on Kubernetes*

# Kafka: The Backbone of Data Pipelines

In a recent survey conducted by Confluent, a leading streaming platform based on Apache Kafka®, more than 90% of respondents of data-driven organizations (across industries) rated Kafka as mission-critical and central to their business use-cases. A quick look at the Kafka [ecosystem](https://cwiki.apache.org/confluence/display/KAFKA/Ecosystem) suggests its popularity & proliferation in the world of data engineering.

At its core, a typical Kafka deployment consists of:

- **Kafka Broker Cluster**: The Kafka brokers store streams of data records in categories called “Topics.” Each Topic is maintained as one or more “Partitions,” which is an immutable ordered sequence of records; each record is assigned an “offset”. The partitions can be (often are) replicated with one of the brokers acting as the partition “leader.” A controller broker in the cluster assigns the leaders of partitions while also performing other administrative actions such as topic creation, and re-electing leaders from amongst In-Sync-Replicas (ISRs). The general practice is to run this as a Statefulset.

- **Kafka Producers & Consumers**: The producers are, in simple terms, the data sources, and publish data to the topics while the consumers are the subscribers of the topic partitions. The producers can be configured to write specific records to specific partitions based on policies (partitions are also a unit of parallelism in Kafka) while the consumers can be grouped with members subscribing to specific partitions. However, we shall not delve into the specifics here, and restrict ourselves to a test topic with a single partition and a simple producer/consumer relationship in the sample chaos experiment that we will demonstrate in this blog.

- **Zookeeper Cluster**: The zookeeper maintains configuration data of the Kafka Broker Cluster, including details of Kafka broker cluster membership, partition locations, leader-follower relationship for the topic partitions, ACLs for topics, etc. It notifies the Kafka Controller Broker in case of broker failures so that new replicas are assigned leaders for the affected partitions. Also typically deployed as a statefulset.

# Chaos On Kafka: Leader Broker Failure Experiment

Now that we know the basics of a Kafka deployment on Kubernetes, let us execute a chaos experiment to kill one of the Kafka Leader Brokers while a message stream is being actively produced/consumed & verify whether the data flow is interrupted. This example intends to introduce the user to the steps involved in carrying out a chaos experiment using Litmus.

## Pre-Requisites

- A (preferably) multi-node Kubernetes cluster. Ensure you are in the Kubernetes-admin context to setup RBAC for the various components involved.

- We shall use the KUDO operator to deploy the Kafka cluster. Kudo, one of the recent additions to the CNCF sandbox projects provides multiple nifty application operators to manage day-2 operations seamlessly. 

## Chaos Experiment Approach

The following steps are performed automatically upon execution of the Chaos Experiment:

- A test “liveness” message stream is setup where a single partition topic is created with replication factor 3. The producer container publishes a simple “message_index with timestamp” to the topic to be consumed by a consumer container that has been configured with a message consumption timeout. In case of a timeout, the consumer container terminates ungracefully with an exception.

- In its default mode, the experiment derives the leader broker for the liveness topic partition, performs a pod kill (delete), and checks if the consumer container is still alive, which implies that the message stream is uninterrupted, with a new leader broker being selected. If this is true, the experiment verdict is set to “pass,” indicating the current deployment is tolerant to pod-failures. A terminated consumer sets the verdict to “fail” and implies that the deployment is not resilient enough, demanding a closer inspection.

## Hypothesis

- Upon killing a leader broker, a new leader is assigned for the topic partition, and the data message stream is not affected.

- The killed pod could be the controller broker, in which case a new broker assumes controller responsibilities OR it could be a follower, in which case the controller re-assigns the leader duties to another ISR. 

## Preparing the Testbed

### Setup the Kafka Cluster

- Step-1: Setup KUDO Infrastructure

  ```
  root@demo:~# VERSION=0.12.0

  root@demo:~# OS=$(uname | tr '[:upper:]' '[:lower:]')

  root@demo:~# wget -O kubectl-kudo 
 https://github.com/kudobuilder/kudo/releases/download/v${VERSION}/kubectl-kudo_${VERSION}_${OS}_${ARCH}
  Resolving github.com (github.com)... 140.82.112.4
  Connecting to github.com (github.com)|140.82.112.4|:443... 
  connected.
  HTTP request sent, awaiting response... 302 Found
  :
  kubectl-kudo                      100% 
  [============================================================>]  
  37.03M  52.9MB/s    in 0.7s
  2020-07-06 11:24:22 (52.9 MB/s) - ‘kubectl-kudo’ saved 
  [38830080/38830080]

  root@demo:~# chmod +x kubectl-kudo

  root@demo:~# sudo mv kubectl-kudo /usr/local/bin/kubectl-kudo

  root@demo:~# kubectl kudo init
  $KUDO_HOME has been configured at /root/.kudo
  ✅ installed cards
  ✅ installed service accounts and other requirements for 
  controller to run
  ✅ installed kudo controller
  ```

- Step-2: Install KUDO-Kafka Cluster
 
  ```
  root@demo:~# kubectl create ns Kafka
  namespace/kafka created
  ```

  ```
  root@demo:~# kubectl kudo install zookeeper --instance=zookeeper-instance -n Kafka
  operator.kudo.dev/v1beta1/zookeeper created
  operatorversion.kudo.dev/v1beta1/zookeeper-0.3.0 created
  instance.kudo.dev/v1beta1/zookeeper-instance created
  ```

  ```
  root@demo:~# kubectl kudo install kafka --instance=kafka -n Kafka
  operator.kudo.dev/v1beta1/kafka created
  operatorversion.kudo.dev/v1beta1/kafka-1.3.1 created
  instance.kudo.dev/v1beta1/kafka created
  ```

- Step-3: Verify that the Kafka cluster is up 

  ```
  root@demo:~# kubectl kudo plan status --instance=kafka -n Kafka
 Plan(s) for "kafka" in namespace "kafka":
.
└── kafka (Operator-Version: "kafka-1.3.1" Active-Plan: "deploy")
    ├── Plan cruise-control (serial strategy) [NOT ACTIVE]
    │   └── Phase cruise-addon (serial strategy) [NOT ACTIVE]
    │       └── Step deploy-cruise-control [NOT ACTIVE]
    ├── Plan deploy (serial strategy) [COMPLETE], last updated 2020-07-06 12:06:07
    │   ├── Phase deploy-kafka (serial strategy) [COMPLETE]
    │   │   ├── Step generate-tls-certificates [COMPLETE]
    │   │   ├── Step configuration [COMPLETE]
    │   │   ├── Step service [COMPLETE]
    │   │   └── Step app [COMPLETE]
    │   └── Phase addons (parallel strategy) [COMPLETE]
    │       ├── Step monitoring [COMPLETE]
    │       ├── Step mirror [COMPLETE]
    │       └── Step load [COMPLETE]
    ├── Plan external-access (serial strategy) [NOT ACTIVE]
    │   └── Phase resources (serial strategy) [NOT ACTIVE]
    │       └── Step deploy [NOT ACTIVE]
    ├── Plan kafka-connect (serial strategy) [NOT ACTIVE]
    │   └── Phase deploy-kafka-connect (serial strategy) [NOT ACTIVE]
    │       ├── Step deploy [NOT ACTIVE]
    │       └── Step setup [NOT ACTIVE]
    ├── Plan mirrormaker (serial strategy) [NOT ACTIVE]
    │   └── Phase app (serial strategy) [NOT ACTIVE]
    │       └── Step deploy [NOT ACTIVE]
    ├── Plan not-allowed (serial strategy) [NOT ACTIVE]
    │   └── Phase not-allowed (serial strategy) [NOT ACTIVE]
    │       └── Step not-allowed [NOT ACTIVE]
    ├── Plan service-monitor (serial strategy) [NOT ACTIVE]
    │   └── Phase enable-service-monitor (serial strategy) [NOT ACTIVE]
    │       └── Step deploy [NOT ACTIVE]
    ├── Plan update-instance (serial strategy) [NOT ACTIVE]
    │   └── Phase app (serial strategy) [NOT ACTIVE]
    │       ├── Step conf [NOT ACTIVE]
    │       ├── Step svc [NOT ACTIVE]
    │       └── Step sts [NOT ACTIVE]
    └── Plan user-workload (serial strategy) [NOT ACTIVE]
        └── Phase workload (serial strategy) [NOT ACTIVE]
            └── Step toggle-workload [NOT ACTIVE]
  ``` 

 ```
 root@demo:~# kubectl get pods -n Kafka
 NAME                             READY   STATUS    RESTARTS   
 AGE
 kafka-kafka-0                    2/2     Running   2          
 11m
 kafka-kafka-1                    2/2     Running   0          
 9m50s
 kafka-kafka-2                    2/2     Running   0          
 8m55s
 zookeeper-instance-zookeeper-0   1/1     Running   0          
 11m
 zookeeper-instance-zookeeper-1   1/1     Running   0          
 11m
 zookeeper-instance-zookeeper-2   1/1     Running   0          
 11m
 ```

### Setup the Litmus Infrastructure

- Step-1: Install Litmus Chaos CRDs, Operator & RBAC 

  ```
  
root@demo:~# kubectl apply -f https://litmuschaos.github.io/pages/litmus-operator-v1.5.0.yaml
namespace/litmus created
serviceaccount/litmus created
clusterrole.rbac.authorization.k8s.io/litmus created
clusterrolebinding.rbac.authorization.k8s.io/litmus created
deployment.apps/chaos-operator-ce created customresourcedefinition.apiextensions.k8s.io/chaosengines.litmuschaos.io created
customresourcedefinition.apiextensions.k8s.io/chaosexperiments.litmuschaos.io created
customresourcedefinition.apiextensions.k8s.io/chaosresults.litmuschaos.io created
```
```  
kubectl apply -f https://raw.githubusercontent.com/litmuschaos/pages/master/docs/litmus-admin-rbac.yaml
```

- Step-2: Create the Kafka-Broker-Pod-Failure ChaosExperiment CR

```
root@demo:~# kubectl apply -f https://hub.litmuschaos.io/api/chaos/master?file=charts/kafka/kafka-broker-pod-failure/experiment.yaml -n litmus
chaosexperiment.litmuschaos.io/kafka-broker-pod-failure created
```

- Step-3: Annotate the Kafka statefulset for Chaos

```
root@demo:~# kubectl annotate sts/kafka-kafka litmuschaos.io/chaos="true" -n kafka
statefulset.apps/kafka-kafka annotated
```

### Run the Chaos Experiment

- Step-1: Construct the ChaosEngine for the Kafka Leader Broker Failure experiment: 

```
root@demo:~# cat <<EOF > kafka-chaos.yaml
>   apiVersion: litmuschaos.io/v1alpha1
>   kind: ChaosEngine
>   metadata:
>     name: kafka-chaos
>     namespace: litmus
>   spec:
>     annotationCheck: 'true'
>     engineState: 'active'
>     appinfo:
>       appns: 'kafka'
>       applabel: 'app=kafka'
>       appkind: 'statefulset'
>     chaosServiceAccount: litmus-admin
>     monitoring: false
>     jobCleanUpPolicy: 'delete'
>     experiments:
>       - name: kafka-broker-pod-failure
>         spec:
>           components:
>             env:
>               - name: KAFKA_REPLICATION_FACTOR
>                 value: '3'
>
>               - name: KAFKA_LABEL
>                 value: 'app=kafka'
>
>               - name: KAFKA_NAMESPACE
>                 value: 'kafka'
>
>               - name: KAFKA_SERVICE
>                 value: 'kafka-svc'
>
>               - name: KAFKA_PORT
>                 value: '9092'
>
>               - name: KAFKA_CONSUMER_TIMEOUT
>                 value: '40000' # in milliseconds
>
>               - name: KAFKA_INSTANCE_NAME
>                 value: 'kafka'
>
>               - name: ZOOKEEPER_NAMESPACE
>                 value: 'kafka'
>
>               - name: ZOOKEEPER_LABEL
>                 value: 'app=zookeeper'
>
>               - name: ZOOKEEPER_SERVICE
>                 value: 'zookeeper-instance-hs'
>
>               - name: ZOOKEEPER_PORT
>                 value: '2181'
>
>               - name: TOTAL_CHAOS_DURATION
>                 value: '60'
>
>               - name: CHAOS_INTERVAL
>                 value: '20'
>
>               - name: FORCE
>                 value: 'false'
EOF
```

- Step-2: Apply the ChaosEngine to launch the experiment 

```
root@demo:~# kubectl apply -f kafka-chaos.yaml -n litmus
chaosengine.litmuschaos.io/kafka-chaos created 
``` 

- Step-3: Observe experiment execution 

  Watch the pods on the app namespace (kafka) to view the chaos actions in progress.

  ```
  watch -n 1 kubectl get pods -n kafka
  ```

  Look out for the following events.

  - The experiment job, as part of the experiment execution, 
    launches a liveness pod (kafka-liveness) that creates a 
    continuous message stream, the producer/consumer running 
    as separate containers of the same pod.

  - The message stream is expected to continue without 
    interruption, with partition leaders being switched. View 
    the kafka-liveness pod logs during the broker-kills to verify 
    uninterrupted message stream

 ```
 kubectl logs -f kafka-liveness -c kafka-consumer -n kafka-system
 ```
 
- Step-4: Verify Result Of the Chaos Experiment 

  View the verdict (spec.experimentStatus.verdict)of the kafka- 
  broker-pod-failure chaos experiment to check whether the Kafka 
  cluster is resilient to the broker loss. 

```
root@demo:~# kubectl describe chaosresult kafka-chaos-kafka-broker-pod-failure -n litmus
Name:         kafka-chaos-kafka-broker-pod-failure
Namespace:    litmus
Labels:       chaosUID=22d5ba06-1fe8-4b01-bdbb-6246e1cdb2c9
              type=ChaosResult
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"litmuschaos.io/v1alpha1","kind":"ChaosResult","metadata":{"annotations":{},"labels":{"chaosUID":"22d5ba06-1fe8-4b01-bdbb-62...
API Version:  litmuschaos.io/v1alpha1
Kind:         ChaosResult
Metadata:
  Creation Timestamp:  2020-07-06T12:28:00Z
  Generation:          10
  Resource Version:    20451
  Self Link:           /apis/litmuschaos.io/v1alpha1/namespaces/litmus/chaosresults/kafka-chaos-kafka-broker-pod-failure
  UID:                 32ea5093-47ee-41d8-bc34-e513edb46660
Spec:
  Engine:      kafka-chaos
  Experiment:  kafka-broker-pod-failure
Status:
  Experimentstatus:
    Fail Step:  N/A
    Phase:      Completed
    Verdict:    Pass
Events:         <none>
```

In case the experiment is "failed", try re-running the experiment with a higher consumer timeout, say 50000ms and verify if the liveness stream runs unaffected. 

# Conclusion

The Kafka chaos experiments are a good way to determine a potential breach of SLAs in terms of data consistency, performance & timeouts due to unexpected broker loss/reschedule and also help with applying corrective measures in the deployment patterns of the data pipelines. This could be one of or a combination of measures such as usage of faster/better CNI, improved storage backends (SSDs), latest Kafka versions which don't depend on Zookeeper for the state, etc.,  Do try this experiment & let me know your findings! 

Are you an SRE or a Kubernetes enthusiast? Does Chaos Engineering excite you?

Join Our Community On Slack For Detailed Discussion, Feedback & Regular Updates On Chaos Engineering For Kubernetes: https://kubernetes.slack.com/messages/CNXNB0ZTN
(#litmus channel on the Kubernetes workspace)
Check out the Litmus Chaos GitHub repo and do share your feedback: https://github.com/litmuschaos/litmus
Submit a pull request if you identify any necessary changes.
