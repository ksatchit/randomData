$ kubectl run -i -t alps --image=alpine:latest --restart=Never --command /bin/ash
Waiting for pod default/alps to be running, status is Pending, pod ready: false
If you don't see a command prompt, try pressing enter.
/ # 
/ # <data-stream> | nc nc-pod.nc-pod-svc 26500
