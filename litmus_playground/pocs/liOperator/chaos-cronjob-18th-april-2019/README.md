## DEMO  

### Intent

- Mockup for eventual chaos operator that can schedule chaos

### Steps

- Env: GKE 
- Install Litmus RBAC & Litmus Result CRD
- Install OpenEBS Operator
- Install openebs-standalone SC
- Deploy stateful nginx in default namespace w/ standard app labels & chaos annotations
- Apply litmusExperiment & chaosTemplate CRD
- Create litmusExperiment (disappearing-targets) & chaosTemplate (openebs-target-failure) CRs
- Deploy chaosScheduler cron-job 

### Notes
- Uses rudimentary bash script to parse CR/precondition & launch tests

### Result 

- The K8s job spawned by cronjob controller parses litmusExperiment CR to get app info & 
  ChaosTemplate details, derives chaos params from chaostemplate CR. Uses this data to 
  precondition & launch the litmusbook mapped to this chaosTemplate. 

- Chaos experiment (pod delete) is repeated per schedule 

### Observations

- Used `forbid` concurrency policy in cronjob, i.e., chaos job is not launched if previous 
  is not terminated. Can cause a job never get scheduled afterwards if first one is stuck. 
  Need activeDeadlineSeconds

- `startingDeadlineSeconds` is good to give (esp small value). If cluster is down/cron job 
   could not be scheduled, than no of missed instances is validated against the duration of 
   this startingDeadlineSeconds. If > 100 misses, job will never be scheduled. If small, not 
   possible to miss so many schedules.

### Feedback, Goals

- The chaos schedule should be picked from experiment (P0)
- The chaos should be triggered/launched the moment `le` is applied (P0)
- The converse of above should also be true. Launching an annotation w/ existing `le` CRs 
  should also trigger chaos (P0)
- Annotation (litmus.io/chaos) should be checked (for true/false) to check if chaos should be 
  triggered (P0) 
- `ct` should be pre-defined and applied beforehand like storageclasses as part of litmus 
   setup (P0)
- There should be default `le` & `ct` as part of litmus setup (P0)
- Annotation (litmus.io/experiment) should take comma separated list of experiment names which 
  should be scheduled & managed independently (??) (P1)
- `le` & `lr` are independednt (??). How can a user derive results. Link job run instance with
   `lr`, say, via timestamps (P1)

