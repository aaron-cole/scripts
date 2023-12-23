###################################################
#
# Compare_STIG_files.ps1
#
# Created By Aaron Cole
#
# This is made to compare previous STIG files
# that were created for STIG_SCAN to NEW STIG files
# created from new_stig_xml_to_new_sh_scripts.ps1 and
# Update the Content/or copy over if no update and 
# Provide a report of what needs to be reviewed.
####################################################
#Replace Directories Below with correct path
#$OldDir = "C:\Users\aaron\Documents\GitHub\STIG_SCAN_RHEL8\STIGS\RHEL8"
#$NewDir = "D:\Workdir\RHEL8"
$OldDir = "C:\Users\aaron\Documents\GitHub\STIG_SCAN_RHEL7\STIGS\RHEL7"
$NewDir = "D:\Workdir\RHEL7"
$Report = "$NewDir\Report.txt"

#For each file in the New Directory
foreach ($item in Get-ChildItem $NewDir) { 
    
#See if the file exists in the OLD directory
#If it doesn't then it is new and we have to 
#Skip over it.
    if (-Not (Test-Path $OldDir\$item)) {
     Add-Content $Report "NEW STIG - $item Needs to be UPDATED"
     Continue
    } #Closing If

#Since RuleId's are updated when the STIGs are changed
#We are going to grab each from the files and then
#Compare to see if there is a change.
$NewRuleID = Get-Content $NewDir\$item | Select-String -Pattern "RuleID="
$OldRuleID = Get-Content $OldDir\$item | Select-String -Pattern "RuleID="

#If the STIG didn't change we just need to copy
#the file of the old STIG to the NEW 
#STIG directory and be done with it.
    if ("$NewRuleID" -eq "$OldRuleID") {
#    Copy-Item $OldDir\$item -Destination $NewDir\$item
    Continue
    }#End of IF

#If we made it this far then the STIG has changed
#So Now we need to copy the contents after 
#"##END of Automatic Items##" to the new file and
#Then we will probably have to edit to update check
#If necessary
    $OldSTIG = Get-Content $OldDir\$item
    $OldSTIGLinesToAdd = $OldSTIG[22..($OldSTIG.Count)]
    Add-Content $NewDir\$item $OldSTIGLinesToAdd
    Add-Content $Report "Updated STIG - $item Needs reviewed"

} #Closing Foreach

#This converts the files created from Windows Line Breaks (CR+LF) to Unix
#Line Breaks (LF) and makes sure it's in UTF8 format.
Get-ChildItem $NewDir -Filter *.sh | ForEach-Object {

#   write-host $_
# get the contents and replace line breaks by U+000A
  $contents = [IO.File]::ReadAllText($_.fullname) -replace "`r`n?", "`n"
# create UTF-8 encoding without signature
  $utf8 = New-Object System.Text.UTF8Encoding $false
  # write the text back
  [IO.File]::WriteAllText($_.fullname, $contents, $utf8)
}