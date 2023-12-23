###################################################
#
# 
#
# Created By Aaron Cole
#
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
#        write-host "New file is $item, old file is $oldfile"
#Once we find the right OLD file we can copy it's contents
#To the New File
       $OldSTIG = Get-Content $OldDir\$oldfile
       $OldSTIGLinesToAdd = $OldSTIG[22..($OldSTIG.Count)]
       Add-Content $NewDir\$item $OldSTIGLinesToAdd
       Add-Content $Report "Updated STIG - $item Needs reviewed"
      }
     }
    }

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


