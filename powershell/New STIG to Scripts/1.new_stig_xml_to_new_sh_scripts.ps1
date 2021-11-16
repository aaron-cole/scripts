############################################################################
# new_stig_xml_to_new_sh_scripts.ps1
#
# This script will only take a DISA xml and transform them in to .sh files
# to be used on unix/linux systems.  This is to use in conjuction with 
# DISA STIG files only.  The resulting sh files are to be used in companion
# sciprts or self home-grown scripts to run the files.
#
# Created by Aaron Cole
# Date 10-23-2017
# Version 1
############################################################################

#Prompt for Dir/File Assignment
#$WorkDir = Read-Host "Please Enter the Working Directory that contains the xml"
#$STIGXML = Read-Host "Please Enter the name of the XML to read"

#Manual Assignment of Dir/File if necessary
#WorkDir is the path to the new xccdf.xml file
#$WorkDir = "D:\Workdir\RHEL8"
$WorkDir = "D:\Workdir\RHEL7"
$STIGXML = "U_RHEL_7_STIG_V3R5_Manual-xccdf.xml"

#Read XML
[xml]$XmlDocument = Get-Content -Path "$WorkDir\$STIGXML"

#Loop through XML and grab nodes/elements
foreach ($vnum in $XmlDocument.Benchmark.group.id)
{
#Variable Assignement for particular items
$VFILE = "$WorkDir\$vnum.sh"
$GrpID = "$vnum"
$GrpTitle = $XmlDocument.Benchmark.group | ? { $_.id -match "$vnum" } | Select-object -expand title
$RuleID = $XmlDocument.Benchmark.group | ? { $_.id -match "$vnum" } | Select-Object -expand Rule | Select-Object -expand id
$STIGID = $XmlDocument.Benchmark.group | ? { $_.id -match "$vnum" } | Select-Object -expand Rule | Select-Object -expand version
$VulDisc = $XmlDocument.Benchmark.group | ? { $_.id -match "$vnum" } | Select-Object -expand rule | Select-Object -expand description
$VulDiscText = [regex]::Match( $VulDisc, '(?<=\<VulnDiscussion\>).+(?=\</VulnDiscussion\>)' ).value

#Adding info to files
Add-Content $VFILE "#!/bin/sh" 
Add-Content $VFILE "##Automatically defined items##"  
Add-Content $VFILE ""
Add-Content $VFILE "#Vulnerability Discussion"
Add-Content $VFILE "#$VulDiscText"
Add-Content $VFILE "" 
Add-Content $VFILE "#STIG Identification" 
Add-Content $VFILE "GrpID=`"$GrpID`"" 
Add-Content $VFILE "GrpTitle=`"$GrpTitle`"" 
Add-Content $VFILE "RuleID=`"$RuleID`"" 
Add-Content $VFILE "STIGID=`"$STIGID`"" 
Add-Content $VFILE "Results=`"./Results/`$GrpID`"" 
Add-Content $VFILE "" 
Add-Content $VFILE "#Remove File if already there" 
Add-Content $VFILE "[ -e `$Results ] && rm -rf `$Results" 
Add-Content $VFILE "" 
Add-Content $VFILE "#Setup Results File" 
Add-Content $VFILE "echo `$GrpID >> `$Results" 
Add-Content $VFILE "echo `$GrpTitle >> `$Results" 
Add-Content $VFILE "echo `$RuleID >> `$Results" 
Add-Content $VFILE "echo `$STIGID >> `$Results"
Add-Content $VFILE "##END of Automatic Items##"

}


#This converts the files created from Windows Line Breaks (CR+LF) to Unix
#Line Breaks (LF) and makes sure it's in UTF8 format.
Get-ChildItem $WorkDir -Filter *.sh | ForEach-Object {
#   write-host $_
# get the contents and replace line breaks by U+000A
  $contents = [IO.File]::ReadAllText($_.fullname) -replace "`r`n?", "`n"
# create UTF-8 encoding without signature
  $utf8 = New-Object System.Text.UTF8Encoding $false
  # write the text back
  [IO.File]::WriteAllText($_.fullname, $contents, $utf8)
}