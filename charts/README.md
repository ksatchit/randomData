## HELM SETUP

- Get Helm

```curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh```

- Give permissions 

```chmod 700 get_helm.sh```

- Execute Helm installtion scripts

```./get_helm.sh```

- Create cluster-admin clusterrole (if not present) w/ permissions for all actions on all resources

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: cluster-admin
rules:
- apiGroups:
  - '*'
  resources:
  - '*'
  verbs:
  - '*'
- nonResourceURLs:
  - '*'
  verbs:
  - '*'

kubectl create -f clusterrole.yaml

```

- Create Tiller service account in kube-system namespace, bind to clusterrole w/ clusterrolebinding

```
kubectl create serviceaccount -n kube-system tiller

kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
```

- Initialize helm w/ service account Tiller

```
helm init --service-account tiller

kubectl --namespace kube-system get pods | grep tiller
  tiller-deploy-2885612843-xrj5m   1/1       Running   0   2d
```

## CREATE & PUBLISH YOUR OWN CHARTS

- Create helm chart

```helm create mychart```

- Define Templates Structure

- Define Values.yml

- Update the Templates w/ placeholders from Values

- Lint the chart

```helm lint ./<chart-directory>```

- Install the chart with desired runtime values

```
karthik_satchitanand@cloudshell:~/helm_trials (argon-tractor-237811)$ helm install ./k8schaos --set configuration.podDelete.executorLib=litmus --set configuration.containerKill.executorImage=ansible-runner:ci

NAME:   giggly-tarsier
LAST DEPLOYED: Fri May  3 15:12:08 2019
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1alpha1/ChaosExperiment
NAME            AGE
container-kill  0s
pod-delete      0s


NOTES:
##TODO: Describe helpfule chaos-related kubectl commands constructed using templates
```

- Upgrade helm release w/ some changed values  

```
karthik_satchitanand@cloudshell:~/helm_trials (argon-tractor-237811)$ helm upgrade giggly-tarsier ./k8schaos --set configuration.podDelete.e
xecutorLib=chaostoolkit                                                                                                                     
Release "giggly-tarsier" has been upgraded. Happy Helming!
LAST DEPLOYED: Fri May  3 15:28:54 2019
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1alpha1/ChaosExperiment
NAME            AGE
container-kill  16m
pod-delete      16m


NOTES:
##TODO: Describe helpfule chaos-related kubectl commands constructed using templates
```

- Package helm chart to share w/ users 

```
karthik_satchitanand@cloudshell:~/helm_trials (argon-tractor-237811)$ helm package ./k8schaos
Successfully packaged chart and saved it to: /home/karthik_satchitanand/helm_trials/k8schaos-0.1.0.tgz
```


- Setup GH (githubPages) based helm-repository
  - Procedure: https://github.com/int128/helm-github-pages


- helm repo list - shows mapped to stable charts by default


```
karthik_satchitanand@cloudshell:~/helm_trials/randomData/.circleci (argon-tractor-237811)$ helm repo list
NAME    URL
stable  https://kubernetes-charts.storage.googleapis.com
local
```   


- Add our remote repo: 

```
karthik_satchitanand@cloudshell:~/helm_trials/randomData/.circleci (argon-tractor-237811)$ helm repo add ksatchit https://ksatchit.github.io/chaos-charts
"ksatchit" has been added to your repositories


karthik_satchitanand@cloudshell:~/helm_trials/randomData/.circleci (argon-tractor-237811)$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Skip local chart repository
...Successfully got an update from the "ksatchit" chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈ Happy Helming!⎈```


- Inspect presence of charts via `helm inspect ksatchit/k8schaos`

- Install chart from remote repo 

```karthik_satchitanand@cloudshell:~/helm_trials/randomData/.circleci (argon-tractor-237811)$ helm install ksatchit/k8schaos
NAME:   kneeling-dingo
LAST DEPLOYED: Fri May  3 16:20:30 2019
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1alpha1/ChaosExperiment
NAME            AGE
container-kill  1s
pod-delete      1s


NOTES:
##TODO: Describe helpfule chaos-related kubectl commands constructed using templates
```
