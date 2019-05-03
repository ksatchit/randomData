## VIA HELM
===========


### PROS: 

- No need to define a chart resource 
- No need to include gitOps Controller into our operator
- Helm works with CRD/CRs - including runtime configuration / values.yml support & ability to "order" install
- Native versioning 
- Availability of automated helm upgrade operators like flux/keel
- Concept of "Hub" can be realized by using concept of "Remote Repositories". 
  For example: GH-Pages (Github-Pages) (Reference: OpenEBS)

- Enterprise Hub can be on a dedicated webserver - such as litmuschaos.io/charts w/ Key/license workflow

- Main inspiration: Velero


### CONS: 

- CRD version changes on upgrades is not clean (hacky) - https://github.com/helm/helm/issues/4697 (proposals are ON)
- Impact: Less (We have passive resources. No problem if CRDs are "replaced") 
- Future - we may handle CRDs in operator & leave charts to be solely CRs

