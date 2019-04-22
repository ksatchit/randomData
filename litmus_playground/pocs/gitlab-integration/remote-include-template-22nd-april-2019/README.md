## DEMO

### Intent

- PoC for reusing remote gitlab (chaos) templates from other repos (`include`)
- Presentation: [Gitlab-Integration](https://docs.google.com/presentation/d/1uxbpY45uaej7ZoLO0Rj9I0Nrh1bIGb4znce_U7TjR7E/edit#slide=id.g4d8fc3d7a4_1_0)

### Steps

- Env: GKE
- Setup repository mirror for dev repo (ksatchit/randomData) on https://gitlab.litmuschaos.io
- In a litmus fork (karthiksatchitanand/litmus) 
  - Create a litmus job that does general pod failure (pod-delete/pod-container-kill, no OpenEBS validation) 
  - Setup bash script to update, launch, monitor & derive result of above litmus job (simple_pod_failure.bash)
  - Setup gitlab yaml w/ chaos template definition & default app, chaos params that runs above script
- In the dev repo setup .gitlab-ci.yaml with steps for deploy-to-staging & inject-chaos, by including remote 
  chaostemplate
- Commit to dev repo to trigger pipelines 

### Notes

- Use `template` in remote gitlab yaml and `extend` in main gitlab-ci.yaml instead of defining a full job 
in remote template. This way, chaos can be injected in any stage.

- Two separate gitlab-runner images were used to simulate actual user's case. 
  - Local job: `ksatchit/appci:gitlab` 
  - Rempte chaos job: `ksatchit/ansible-runner:gitlabgke`

### Result 

- Pipeline ran both locally defined job (deploy to staging) & remote/included job, i.e, chaos
- https://gitlab.litmuschaos.io:9443/atul/randomData/pipelines/39

### Observations 

- Ensure artifacts passed to remote job in main pipeline are used properly (kubeconfig)
- Absolute paths have to be used everywhere (scripts) 
- The remote `include` feature seems to be in `gitlab-ee` only. Refer: https://gitlab.com/gitlab-org/gitlab-ce/issues/42861

### Feedback, Goals

- Create more ***general*** chaos templates (and thereby litmusbooks) (P0)
- Identify best structure to move into new github org (litmuschaos.io) (P0)
- Blog around this (P0)
- Attempt PRs into Gitlab Docs (P0) 
- Replace running scripts w/ operator actions (P1)
