## LitmusChaos xUnit result XML format 

Note: 

- A native xUnit result schema for LitmusChaos (just like there is jUnit schema for jenkins et al)
- LitmusChaos can provide a parser for rendering this in a standardized/beautified html format

```xml
<?xml version="1.0" encoding="UTF-8"?>
<testcase probes="2" probefailures="1" name="catalogue-latency-10s">
   <properties>
      <property name="experiment.version" value="2.1.0" />
   </properties>
   <probes>
      <probe type="http-probe" name="frontend-availability-check" result="pass" />
      <probe type="cmd-probe" name="sock-shop-user-crud-check" result="pass" />
      <probe type="prom-probe" name="service-qps-check" result="fail">
         <probefailure status="Failed" message="actual value {180.99} less than {200}" />
      </probe>
   </probes>
   <fault name="pod-network-latency" targetkind="deployment" targetname="catalogue">
      <testfailure verdict="Failed" message="steady-state validation failed" />
   </fault>
</testcase>
```
## LitmusChaos jUnit result XML generated via litmus-sdk from chaosresult YAML input 

Note: 

- Output format based on jenkins/ant references 
- Offline rendering of an existing junit template based on fields parsed from input chaosresult using `litmus-sdk`
- Here the chaosengine corresponds to the testsuite that runs a specific fault 
- Probes map to individual tests or constraints 

```xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuite tests="1" failures="1" name="{{ .Metadata.Name }}"> <!-- catalogue-latency-10s -->
  <properties>
    <property name="fault.name" value="{{ .Spec.Experiment }}"></property> <!-- pod-network-latency --> 
    <property name="target.kind" value="{{ .Status.Targets[0].Kind }}"></property> <!-- deployment -->
    <property name="target.name" value="{{ .Status.Targets[0].Name }}"></property> <!-- catalogue -->
  </properties>
  <testcase classname="http-probe" name="frontend-availability-check">
    <failure message="Failed" type="Actual output does not meet criteria - 200 OK"></failure>
  </testcase>
  <testcase classname="cmd-probe" name="service-self-heal-under-mttr"></testcase>
</testsuite>
```								     

## LitmusChaos jUnit result XML format based on jenkins/ant - generated via experiment as an artifact

Note: 

- Very similar to previous schema
- Runtime generation of an existing junit template based on chaosdetails captured
- Since it is runtime generated, we will also have extra info - such as run_duration, app reschedule/startup/recovery time etc., (which is not available with offline render)
- This may be placed/written into a `configmap` at the end of the experiment for further format/extraction by users.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuite tests="1" failures="1" time="03.20" name="catalogue-latency-10s"> 
  <properties>
    <property name="fault.name" value="pod-network-latency"></property> 
    <property name="target.kind" value="deployment"></property> 
    <property name="target.name" value="catalogue"></property>
    <property name="app.recovery.time" value="00.30"></property>
  </properties>
  <testcase classname="http-probe" name="frontend-availability-check">
    <failure message="Failed" type="Actual output does not meet criteria - 200 OK"></failure>
  </testcase>
  <testcase classname="cmd-probe" name="service-self-heal-under-mttr"></testcase>
</testsuite>
```

## LitmusChaos ChaosResult converted to XML format 

Note: 

- Doesn't conform to regular xUnit/jUnit result format, but can be rendered if users employ generic xml-<format> parsers. 

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<root>
  <apiVersion>litmuschaos.io/v1alpha1</apiVersion>
  <kind>ChaosResult</kind>
  <metadata>
    <name>helloservice-pod-delete-pod-delete</name>
    <namespace>litmus</namespace>
    <resourceVersion>8315917</resourceVersion>
  </metadata>
  <spec>
    <engine>helloservice-pod-delete</engine>
    <experiment>pod-delete</experiment>
  </spec>
  <status>
    <experimentStatus>
      <failStep>N/A</failStep>
      <phase>Completed</phase>
      <probeSuccessPercentage>100</probeSuccessPercentage>
      <verdict>Pass</verdict>
    </experimentStatus>
    <history>
      <failedRuns>0</failedRuns>
      <passedRuns>1</passedRuns>
      <stoppedRuns>0</stoppedRuns>
      <targets>
        <chaosStatus>targeted</chaosStatus>
        <kind>deployment</kind>
        <name>hello</name>
      </targets>
    </history>
  </status>
</root>
```
