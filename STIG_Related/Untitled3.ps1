$Workingdir = "C:\Temp\STIGCKL"
$testfile = "server-RHEL6_V2R1_2020-10-30.ckl"

[xml]$CKLFile = Get-Content -Path "$Workingdir\$testfile"

##This is OPEN/Not Reviewed
$FINDINGS = $CKLFile.CHECKLIST.STIGS.iSTIG.VULN | ? {($_.STATUS -notmatch "NotAFinding") -and ($_.STATUS -notmatch "Not_Applicable")}

#We have to loop through each STIG
for ($i=0;$i -lt $FINDINGS.Count; $i++) {
$VULID = $FINDINGS[$i].STIG_DATA.Get(0).ATTRIBUTE_DATA
$SEVERITY = $FINDINGS[$i].STIG_DATA.Get(1).ATTRIBUTE_DATA
$RULEID = $FINDINGS[$i].STIG_DATA.Get(3).ATTRIBUTE_DATA
$STIGID = $FINDINGS[$i].STIG_DATA.Get(4).ATTRIBUTE_DATA
$RULETITLE = $FINDINGS[$i].STIG_DATA.Get(5).ATTRIBUTE_DATA
$FINDINGS = $FINDINGS[$i].FINDING_DETAILS
$COMMENTS = $FINDINGS[$i].COMMENTS
$STATUS = $FINDINGS[$i].STATUS

#Since the CKL file doesn't do CATs, we do it here
Switch ($SEVERITY)
{
    low {$SEVERITYID = "CAT III"}
    medium {$SEVERITYID = "CAT II"}
    high {$SEVERITYID = "CAT I"}
    default {$SEVERITYID = ""}
}
$item = @{}
$item.Status = $STATUS
$item.Vul_ID = $VULID
$item.STIG_ID = $STIGID 
$item.Rule_ID = $RULEID
$item.Severity = $SEVERITYID 
$item.RuleTitle = $RULETITLE 
$item.Findings = $FINDINGS
$item.Comments = $COMMENTS
$collection = New-Object psobject -Property $item
$collection | Export-Csv -LiteralPath C:\Temp\STIGCKL\workingfile.csv -NoTypeInformation -Encoding UTF8 -Append
} #End of For Loop

#$collection | Export-Csv -LiteralPath C:\Temp\STIGCKL\workingfile.csv -NoTypeInformation -Encoding UTF8
