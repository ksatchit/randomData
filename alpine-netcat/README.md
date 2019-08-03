## Alpine-based Custom Application 

- Replace busybox on openebs e2e pipelines to a better solution in order to get a better "synthentic"  
app to simulate real-world workloads. 

### App Requirements 

- Quickly installed, small image sizes
- Have minimal footprint in terms of resource consumption
- Extensible, i.e., reasonable package management & library support available


- *Solution: alpine*

### Workflow Requirements

- Ensure app fails when storage turns read-only
  - *Solution: Setup liveness probe with a touch/write/modify/delete (crud) file ops on mount point*

- Ensure app has local load generation capabilities 
  - *Solution: fio (either on the app, or over network in client-server model) to create heavy load on app*
  - Note: Needs to be able to by-pass cache OR Perform separate write/read jobs with cache invalidation

- Ensure app has an external loadgen 
  - *Solution: Setup nc server on a pre-determined port on app. Run nc client on another alpine pod with data streamed/piped* 

- Ensure app has an external liveness check
  - *Solution: Exposing a port over which nc will listen can create a simple hello/ping-liveness chek from another alpine pod running nc client*

### Artifacts

- **nc-sts.yaml**: Single replica sts which runs an entrypoint script to setup ncat server listening on a port for TCP traffic & `tee` data
  into a file on the storage mount point

- **clinet-app.cmd**: Example of a sample external loadgen pod. It can be used for a external liveness check by using a wrapper script to do 
  a ping check

- **Dockerfile.alpine**: Base image for alpine-app. `nc` & `fio` packages can be used on need-basis

- **run-nc.sh**: `ash` script to start ncat listener and dump data on mount point

 

