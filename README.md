### randomData

Random snippets & artifacts on test automation, CI/CD, tools, kubernetes, etc..,

### TestData

[embedmd]:# (https://raw.githubusercontent.com/ksatchit/talk-chaos/master/sample-engine.yaml yaml) 
```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: nginx-chaos
  namespace: default
spec:
  # It can be app/infra
  annotationCheck: "true"
  #ex. values: ns1:name=percona,ns2:run=nginx
  auxiliaryAppInfo: ""
  appinfo:
    appns: default
    applabel: "app=nginx"
    appkind: deployment
  chaosServiceAccount: nginx-sa
  monitoring: false
  components:
    runner:
      image: "litmuschaos/chaos-executor:1.0.0"
      type: "go"
  # It can be delete/retain
  jobCleanUpPolicy: delete
  experiments:
    - name: container-kill
      spec:
        components:
          # specify the name of the container to be killed
          - name: TARGET_CONTAINER
            value: "nginx"
```
