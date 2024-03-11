Foreach ($STIG in $CKLSTIGS) {

  $CKLRULE = ($STIG.STIG_DATA | ? {$_.VULN_ATTRIBUTE -eq "Rule_ID"} | Select-Object ATTRIBUTE_DATA).ATTRIBUTE_DATA
  $scap_stig_result = ($scap_test_results.'rule-result' | ? {$_.idref -match "$CKLRULE"} | Select-Object result).result
  #$scap_stig_result_time = ($scap_test_results.'rule-result' | ? {$_.idref -match "$CKLRULE"} | Select-Object time).time

  if ($scap_stig_result -ne $null){
    switch ($scap_stig_result) {
      "fail" { $stig_status = "Open" }
      "pass" { $stig_status = "NotAFinding" }
      "notapplicable" { $stig_status = "Not_Applicable" }
    }

    $STIG.STATUS = $stig_status
    $STIG.FINDING_DETAILS = "Tool: " + $scap_test_results.'test-system' + "`n" + "Time: $scap_start_time"+ "`n" + "Result: $scap_stig_result"
  }



Get rule reference rule for result:
($scap_test_results.'rule-result' | ? {$_.idref -match "$CKLRULE"} | Select-Object idref).idref


Get check reference from xccdf
$scapdata.'asset-report-collection'.'report-requests'.'report-request'.content.'data-stream-collection'.component
($scapdata.'asset-report-collection'.'report-requests'.'report-request'.content.'data-stream-collection'.component | ? {$_.id -match "-xccdf.xml"}).benchmark.group

#Oval ID
$scap_oval_id = (($scapdata.'asset-report-collection'.'report-requests'.'report-request'.content.'data-stream-collection'.component | ? {$_.id -match "-xccdf.xml"}).benchmark.group.group.rule  | ? {$_.id -match "$CKLRULE"}).check.'check-content-ref'.name

#OVAL
($scapdata.'asset-report-collection'.'report-requests'.'report-request'.content.'data-stream-collection'.component | ? {$_.id -match "Benchmark-oval.xml"}).oval_definitions
