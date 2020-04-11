## Simple external liveness server

- Create your own liveness business logic and place status codes in /var/tmp/status.action
  - Cycle Success, Cycle Failure, Cycle InProgress
  - Setup business logic to crash/fail upon loss of access/CRUD failure

- Post Checks from calling experiment business logic
  - Check for availability of the liveness deployment. CrashLoopBackOff/error containers indicates liveness failure
  - Check for status code via `curl http://<liveness-service-cluster-ip>:8080` to determine clean removal (w/ stale liveness data in app)

See [MySQL liveness client](https://github.com/litmuschaos/test-tools/blob/master/app_clients/mysql-client/mysql-liveness-check.yaml) for reference on what liveness params are typically used (init, timeouts, retries etc.,) and how it can be changed into the model described here.

## Uses

- Many of our liveness scripts do periodic data CRUD ops on user apps (create/delete databases etc., example: mysql, cassandra). 
  We need a graceful way to remove the liveness data/residue created on the apps before cleaning up these liveness pods.

- The liveness status is available over a service endpoint. Other hooks can be setup based on this

