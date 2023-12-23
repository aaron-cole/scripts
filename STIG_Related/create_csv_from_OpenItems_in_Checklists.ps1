####################################################################
#
# This script is designed to create a csv spreadsheet of findings
# gathered from ckl files. 
#
#
#
#####################################################################

#####################################################################
##Variables
##Static Section##
#$DesktopPath = Read-Host 'Enter File Path to Save the Report'
$DesktopPath = ([Environment]::GetFolderPath("Desktop"))
$ReportFile = "$DesktopPath\CKL_Vulnerabilities.csv"
$CKLDir = gci "D:\My Documents\##STIG_Checklists\files_updated"


##Dynamic Section##
#$inputCKLDir = Read-Host 'Enter the Path to the CKL files'
#$CKLDir = gci "$inputCKLDir"
#####################################################################


#For Each CKL File in the Directory
foreach ($file in $CkLDir) {

#Load Ckl File
[XML]$CKLFile = Get-Content $file.fullname

#Predefine array for report writing
[array]$report = $null

#Hostname
$HostName = $CKLFile.CHECKLIST.ASSET.HOST_NAME
$IP = $CKLFile.CHECKLIST.ASSET.HOST_IP

#STIG
$STIG = ($CKLFile.CHECKLIST.STIGS.iSTIG.STIG_INFO.SI_DATA | ? {$_.SID_NAME -eq "title"} | Select-Object SID_DATA)
$STIGDATE = $CKLFile.CHECKLIST.STIGS.iSTIG.STIG_INFO.SI_DATA | ? {$_.SID_NAME -eq "releaseinfo"} | Select-Object SID_DATA

#All findings that are not Fixed
#Other possible entries are Not_Reviewed and Open
$OPENSTIGS = ($CKLFile.CHECKLIST.STIGS.iSTIG.VULN | ? {($_.STATUS -notmatch "NotAFinding") -and ($_.STATUS -notmatch "Not_Applicable")})


#Loop through ckl file and get info for csv
Foreach ($OPENSTIG in $OPENSTIGS) {
    
    $vulnum = ($OPENSTIG.STIG_DATA | ? {$_.VULN_ATTRIBUTE -eq "Vuln_Num"} | Select-Object ATTRIBUTE_DATA)
    $severity = ($OPENSTIG.STIG_DATA | ? {$_.VULN_ATTRIBUTE -eq "Severity"} | Select-Object ATTRIBUTE_DATA)
    $grptitle = ($OPENSTIG.STIG_DATA | ? {$_.VULN_ATTRIBUTE -eq "Group_Title"} | Select-Object ATTRIBUTE_DATA)
    $ruleID = ($OPENSTIG.STIG_DATA | ? {$_.VULN_ATTRIBUTE -eq "Rule_ID"} | Select-Object ATTRIBUTE_DATA)
    $ruleVer = ($OPENSTIG.STIG_DATA | ? {$_.VULN_ATTRIBUTE -eq "Rule_Ver"} | Select-Object ATTRIBUTE_DATA)
    $ruleTitle = ($OPENSTIG.STIG_DATA | ? {$_.VULN_ATTRIBUTE -eq "Rule_Title"} | Select-Object ATTRIBUTE_DATA)
    $VulDiscuss = ($OPENSTIG.STIG_DATA | ? {$_.VULN_ATTRIBUTE -eq "Vuln_Discuss"} | Select-Object ATTRIBUTE_DATA)
    $checkcontent = ($OPENSTIG.STIG_DATA | ? {$_.VULN_ATTRIBUTE -eq "Check_Content"} | Select-Object ATTRIBUTE_DATA)
    $fixText = ($OPENSTIG.STIG_DATA | ? {$_.VULN_ATTRIBUTE -eq "Fix_Text"} | Select-Object ATTRIBUTE_DATA)
    $vuldetail = ($OPENSTIG | select FINDING_DETAILS) 
   
   
    $obj = New-Object psobject
    $obj | Add-Member noteproperty "STIG" $STIG.SID_DATA
    $obj | Add-Member noteproperty "STIG Date" $STIGDATE.SID_DATA
    $obj | Add-Member noteproperty "Host Name" $HostName
    #$obj | Add-Member noteproperty "IP Address" $IP
    $obj | Add-Member noteproperty "Vulnerability Number" $vulnum.ATTRIBUTE_DATA
    $obj | Add-Member noteproperty "Severity" $severity.ATTRIBUTE_DATA
    $obj | Add-Member noteproperty "Status" $OPENSTIG.STATUS
    #$obj | Add-Member noteproperty "Group Title" $grptitle.ATTRIBUTE_DATA
    #$obj | Add-Member noteproperty "Rule ID" $ruleID.ATTRIBUTE_DATA 
    #$obj | Add-Member noteproperty "Rule Version" $ruleVer.ATTRIBUTE_DATA
    $obj | Add-Member noteproperty "Rule Title" $ruleTitle.ATTRIBUTE_DATA
    #$obj | Add-Member noteproperty "Vulnerability Discussion" $VulDiscuss.ATTRIBUTE_DATA
    #$obj | Add-Member noteproperty "Check Content" $checkcontent.ATTRIBUTE_DATA
    #$obj | Add-Member noteproperty "Fix Text" $fixText.ATTRIBUTE_DATA
    #$obj | Add-Member noteproperty "Vulnerability finding" ($vuldetail.FINDING_DETAILS -replace "<.*>").Trim()

#Append to Array and prepare to output
    $report += $obj
}
    
#Export Report to CSV
$report | Export-Csv -Path $ReportFile -NoTypeInformation -Encoding UTF8 -Append
}    

#Open when Done.
#Invoke-Item -Path $ReportFile
