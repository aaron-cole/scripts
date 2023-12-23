
#$CKLFile.CHECKLIST.STIGS.iSTIG.VULN
#$CKLFile.CHECKLIST.STIGS.iSTIG.VULN.STIG_DATA
#$CKLFile.CHECKLIST.STIGS.iSTIG.VULN | ? {$_.STATUS -match "Open"}

#Load XML
[xml]$CKLFile = Get-Content -Path 'C:\Temp\My_Stuff-master\Powershell reword\server.ckl'

#Get the Open Findings
$OPENFINDINGS = $CKLFile.CHECKLIST.STIGS.iSTIG.VULN | ? {$_.STATUS -match "Open"}

#Count of Findings
$OPENFINDINGS.Count

$OPENFINDINGS[0].STIG_DATA

#Vuln_Num = VUL ID
$OPENFINDINGS[0].STIG_DATA.Get(0).ATTRIBUTE_DATA

#Severity
#high=CAT I
#medium=CAT II
#low=CAT III
$OPENFINDINGS[0].STIG_DATA.Get(1).ATTRIBUTE_DATA

#Rule ID
$OPENFINDINGS[3].STIG_DATA.Get(3).ATTRIBUTE_DATA
#Rule_Version = STIG ID
$OPENFINDINGS[3].STIG_DATA.Get(4).ATTRIBUTE_DATA
#Rule Title
$OPENFINDINGS[3].STIG_DATA.Get(5).ATTRIBUTE_DATA

#Comments
$OPENFINDINGS[3].COMMENTS

#Finding Details
$OPENFINDINGS[3].FINDING_DETAILS




for ($i=0;$i -lt $OPENFINDINGS.Count; $i++) {
$VULID = $OPENFINDINGS[$i].STIG_DATA.Get(0).ATTRIBUTE_DATA
$SEVERITY = $OPENFINDINGS[$i].STIG_DATA.Get(1).ATTRIBUTE_DATA
$RULEID = $OPENFINDINGS[$i].STIG_DATA.Get(3).ATTRIBUTE_DATA
$STIGID = $OPENFINDINGS[$i].STIG_DATA.Get(4).ATTRIBUTE_DATA
$RULETITLE = $OPENFINDINGS[$i].STIG_DATA.Get(5).ATTRIBUTE_DATA
$FINDINGS = $OPENFINDINGS[$i].FINDING_DETAILS
$COMMENTS = $OPENFINDINGS[$i].COMMENTS


Switch ($SEVERITY)
{
    low {$SEVERITYID = "CAT III"}
    medium {$SEVERITYID = "CAT II"}
    high {$SEVERITYID = "CAT I"}
    default {$SEVERITYID = ""}
}

$outputfile = $VULID.pdf

$pdf_fields =@{ 
    'Date' = (Get-Date -Format 'MM/dd/yyyy'); 
    'Vul_ID' = $VULID; 
    'STIG_ID' = $STIGID; 
    'Rule_ID' = $RULEID; 
    'Severity' = $SEVERITYID; 
    'RuleTitle' = $RULETITLE; 
    'DocFacts' = $FINDINGS + $COMMENTS;  
} 

}


$CKLFile.CHECKLIST.ASSET.HOST_NAME
 Switch ($host_name) 
 { 
    d* {"$enclave = "home'"} 
 }