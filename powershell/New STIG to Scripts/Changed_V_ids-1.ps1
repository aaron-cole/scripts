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
$OldDir = "C:\Users\aaron\Documents\GitHub\STIG_SCAN_RHEL7\STIGS\RHEL7"
$NewDir = "D:\Workdir\RHEL7"
$Report = "$NewDir\Report.txt"

#For each file in the New Directory
foreach ($item in Get-ChildItem $NewDir) { 
    
#See if the file exists in the OLD directory
#If it doesn't then it is new and we have to 
#Skip over it.
#    if (-Not (Test-Path $OldDir\$item)) {
#     Add-Content $Report "NEW STIG - $item Needs to be UPDATED"
#     Continue
#    } #Closing If

#Get STIGID from New File
    foreach($line in Get-Content $NewDir\$item) { 
     if($line -match "STIGID=") {
      $RHELID = $line
     }
    }

#Once we have our NEW FILE name which is $NewDir\$item
#And we have the RHELID from our NEW FILE which is $RHELID
#we can now read each old file for the RHELID in it.
    foreach($oldfile in Get-ChildItem $OldDir) {
     foreach($oldfileline in Get-Content $OldDir\$oldfile) {
      if($oldfileline -match $RHELID) {
       Add-Content $Report "New file is $item, old file is $oldfile"
#        write-host "New file is $item, old file is $oldfile"
      }
     }
    }

} #Closing Foreach