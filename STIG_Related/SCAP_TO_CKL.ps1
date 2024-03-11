## Parameters for CLI operation
param ($blankckl, $destination_dir, $scapfile, $scapdir)

if (($scapfile -ne $null) -and ($scapdir -ne $null)) { 
  Write-Host "Both scapfile and scapdir can't be used..."
  Write-Host "Only Provide one or none of the parameters"
  Write-Host "scapfile is for a single file and is the default if nothing provided`n"
  Write-Host "scapdir is for a directory containing scap .xml files"
  Write-Host "scapdir will process any .xml file in directory so be careful..."
  exit 3 
}

# Check for BlankCKL cli parameter
# Assign or Ask for
if ($blankckl -ne $null)
  { $BLANK_CKL_FILE = $blankckl }
else 
  { $BLANK_CKL_FILE = Read-Host "Full Path to Blank CKL" }

# WE are going to test the file existence 
# Otherwise Keep trying until a file that exists is given
while (!(Test-Path $BLANK_CKL_FILE -PathType Leaf)) { 
  Write-Host "File Does not Exist`n"
  $BLANK_CKL_FILE = Read-Host "Full Path to Blank CKL"
}

# Check if destination_dir cli parameter exists
# Assign or Ask for and Assign
if ($destination_dir -ne $null)
  { $DESTINATION_PATH = $destination_dir }
else 
  { $DESTINATION_PATH = Read-Host "Destination Directory (no trailing \)" }

#Create destination directory if it doesn't exist
if (!(Test-Path $DESTINATION_PATH -PathType Container)) { 
  Write-Host "Destination Directory Does Not Exist"
  Write-Host "Creating..."
  New-Item -ItemType Directory -Path $DESTINATION_PATH
  Write-Host "Created $DESTINATION_PATH`n"
}

if (($scapfile -ne $null) -or ($scapdir -eq $null)) { 
  if ($scapfile -eq $null) { 
    Write-Host "SCAP File Needed"
    $scapfile = Read-Host "Full Path to SCAP File" 
  }
  $scap_file_list = $scapfile
  while (!(Test-Path $scap_file_list -PathType Leaf) ) { 
    Write-Host "SCAP File Does not Exist or NOT PROVIDED`n"
    $scap_file_list = Read-Host "Full Path to SCAP File"      
  }
}

if ($scapdir -ne $null) { 
  if (!(Test-Path $scapdir -PathType Container)) { 
    Write-Host "SCAP DIRECTORY Provided does not exist"
    Write-Host "Exiting"
    Exit 3
  }
  $scap_file_list = (Get-ChildItem -Path "$scapdir\*.xml" -File).fullname
  if ($scap_file_list -eq $null) { 
    Write-Host "SCAP DIRECTORY DOES NOT CONTAIN .XML FILES"
    Write-Host "Exiting"
    Exit 3
  }
}

###################
#Functions
function Save-CKL { 
  $NEW_CKL.PreserveWhitespace = $true
  $NEW_CKL.Save($NEW_CKL_FILE)
  Write-Host "" 
  Write-Host "###  Using $scap_file_to_use.."
  Write-Host "###  The following CKL was created $NEW_CKL_FILE"
}

###################
# DeBug Vars
#$BLANK_CKL_FILE = "C:\SCAP\new.ckl"
#$scap_file_to_use = "C:\Users\aaron\Downloads\rhel8ansible.colehome.local-20230723163139.xml"
#$DESTINATION_PATH = "C:\SCAP"

# Variables
$CURRENT_DATE = Get-Date -Format "yyyy_MM_dd"
$BLANK_CKL = [xml] (Get-content -Path $BLANK_CKL_FILE)
$BLANK_CKL.PreserveWhitespace = $true
$BLANK_CKL_FULL_VERS = ($BLANK_CKL.CHECKLIST.STIGS.iSTIG.STIG_INFO.SI_DATA | ? {$_.SID_NAME -eq "filename"} | Select-Object SID_DATA).SID_DATA
$BlANK_CKL_SLIM_VERS = (((($BLANK_CKL_FULL_VERS.split('-')[0]).replace('_Manual','')).replace('U_','')).replace('_STIG',''))

###################
# We Need to Now sort if we have a single file or directory
Foreach ($scap_file_to_use in $scap_file_list) {

  #Variables From SCAP File
  [xml]$scapdata = Get-content -Path "$scap_file_to_use"
  $scap_test_results = $scapdata.'asset-report-collection'.reports.report.content.TestResult
  # We will use this for the moment
  $scap_fqdn = ($scap_test_results.target)
  $scap_hostname = $scap_fqdn
  #These only work on SCAP for RHEL8+
  #$scap_fqdn = ($scap_test_results.'target-facts'.fact | ? { $_.name -eq "urn:xccdf:fact:asset:identifier:fqdn" }).'#text'
  #$scap_hostname = ($scap_test_results.'target-facts'.fact | ? { $_.name -eq "urn:xccdf:fact:asset:identifier:host_name" }).'#text'
  $scap_start_time = $scap_test_results.'start-time'
  #$scap_stop_time = $scap_test_results.'end-time'
  
#######################
  #Create New File based on defined parameters
  $DESTINATION_FILE_NAME = "$scap_hostname-$BLANK_CKL_SLIM_VERS-$CURRENT_DATE.ckl"
  $NEW_CKL_FILE = "$DESTINATION_PATH\$DESTINATION_FILE_NAME"
  Copy-Item "$BLANK_CKL_FILE" -Destination "$NEW_CKL_FILE"
  $NEW_CKL = New-Object xml.xmldocument
  $NEW_CKL.PreserveWhitespace = $true
  $NEW_CKL.Load($NEW_CKL_FILE)

  ######################
  #NEW CKL Base Updates for Machine
  $NEW_CKL.CHECKLIST.ASSET.HOST_FQDN = $scap_fqdn
  $NEW_CKL.CHECKLIST.ASSET.HOST_NAME = $scap_hostname
  $NEW_CKL.CHECKLIST.ASSET.HOST_MAC = ($scap_test_results.'target-facts'.ChildNodes | ? {$_.name -eq "urn:xccdf:fact:ethernet:MAC"} | ? {$_.'#text' -ne "00:00:00:00:00:00"}).'#text'[0]
  $NEW_CKL.CHECKLIST.ASSET.HOST_IP = ($scap_test_results.'target-address' | ? {$_ -ne "127.0.0.1"})[0]
  # Only Works for RHEL8 SCAP
  #$NEW_CKL.CHECKLIST.ASSET.HOST_IP = ($scap_test_results.'target-facts'.ChildNodes | ? {$_.name -eq "urn:xccdf:fact:asset:identifier:ipv4"} | ? {$_.'#text' -ne "127.0.0.1"}).'#text'[0]
  
#######################
  #Time to add in Pass/Fail
  $CKLSTIGS = $NEW_CKL.CHECKLIST.STIGS.iSTIG.VULN
  
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
      
  
  ###            $STIG.FINDING_DETAILS = ""
  ###            $STIG.COMMENTS = "Documented with ISSM - AC 5/10/2021"
  
  
  }
  Save-CKL
}
