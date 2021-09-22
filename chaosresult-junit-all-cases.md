## LitmusChaos xUnit result XML format 

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
----

<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
	<testsuite tests={{ .Spec.Context }} failures="1" time="0.151" name="package/name">
		<properties>
			<property name="go.version" value="1.0"></property>
		</properties>
		<testcase classname="name" name="{{ metadata.name }} " time="0.020">
			<failure message="Failed" type="">file_test.go:11: Error message&#xA;file_test.go:11: Longer&#xA;&#x9;error&#xA;&#x9;message.</failure>
		</testcase>
		<testcase classname="name" name="TestTwo" time="0.130"></testcase>
	</testsuite>
</testsuites>
