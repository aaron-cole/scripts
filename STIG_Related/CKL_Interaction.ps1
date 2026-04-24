## Parameters for CLI operation
param ($inputckl)

# Check for input cli parameter or ask for


###################
#Functions

function Open-CKL ($load_ckl) {
  Write-Host "Opening $load_ckl..."
  $script:LOADEDCKLFile = [xml] (Get-content -Path $load_ckl)
  $LOADEDCKLFile.PreserveWhitespace = $true    
}
function CKL-Prompt {
  while ($CKLChoice -ne 4) {
    $CKLTitle = "What would you like to do with the CKL File?"
    $CKLPrompt = " - Changes will not be save until told to or close of the CKL`n - Current CKL file is $inputckl`n "
    $CKLChoices = [System.Management.Automation.Host.ChoiceDescription[]] @("&Info_Review_&_Update", "&Save_CKL", "&RN", "&Open", "&Previous_Menu")
    $CKLDefault = 4
    $CKLChoice = $host.UI.PromptForChoice($CKLTitle, $CKLPrompt, $CKLChoices, $CKLDefault)
    switch($CKLChoice) {
      0 { Write-Host "Loading CKL Info..."
          while ($CKLChoice -ne 4) {
            $reply = $null
            $confirm_reply = $null
            Get-CKLInfo
            $CKLTitle = "Current CKL File is $inputckl`n "
            $CKLPrompt = " - Current Hostname: $CKL_HOSTNAME`n - Current FQDN: $CKL_FQDN`n - Current IP: $CKL_IP`n - Current MAC: $CKL_MAC`n "
            $CKLChoices = [System.Management.Automation.Host.ChoiceDescription[]] @("&Hostname", "&FQDN", "&IP", "&MAC", "&Previous_Menu")
            $CKLDefault = 4
            $CKLChoice = $host.UI.PromptForChoice($CKLTitle, $CKLPrompt, $CKLChoices, $CKLDefault)
            switch($CKLChoice) {
              0 { Write-Host "Current Hostname: $CKL_HOSTNAME"
                  $reply = Read-Host -Prompt "Change?[y/n]"
                  if ($reply -eq 'y') {
                    $script:NEW_HOSTNAME = Read-Host "New Hostname:"
                    Write-Host "Please Review Changes:"
                    Write-Host "Old Hostname: $CKL_HOSTNAME"
                    Write-Host "New Hostname: $NEW_HOSTNAME"
                    Write-Host "`n"
                    $confirm_reply = Read-Host -Prompt "Confirm Changes?[y/n]"
                    if ($confirm_reply -eq 'y') {
                      $LOADEDCKLFile.CHECKLIST.ASSET.HOST_NAME = $NEW_HOSTNAME
                      Close-CKL
                    } else {
                      Write-Host "No Changes Processed"
                    }
                  }
                }
              1 { Close-CKL }
              2 { Write-Host "Cancel - Write your code"}
              3 { Write-Host "Cancel - Write your code"}
              4 { break }
            }
          }
        }
      1 { Close-CKL }
      2 { Write-Host "Cancel - Write your code"}
      3 { Write-Host "Cancel - Write your code"}
      4 { break }
    }
  }
}
function Get-CKLInfo {
  $script:CKL_FQDN = $LOADEDCKLFile.CHECKLIST.ASSET.HOST_FQDN
  $script:CKL_HOSTNAME = $LOADEDCKLFile.CHECKLIST.ASSET.HOST_NAME
  $script:CKL_IP = $LOADEDCKLFile.CHECKLIST.ASSET.HOST_IP
  $script:CKL_MAC = $LOADEDCKLFile.CHECKLIST.ASSET.HOST_MAC
  $script:CKL_VERSION = ($LOADEDCKLFile.CHECKLIST.STIGS.iSTIG.STIG_INFO.SI_DATA | ? {$_.SID_NAME -eq "version"} | Select-Object SID_DATA).SID_DATA
  $script:CKL_STIGID = ($LOADEDCKLFile.CHECKLIST.STIGS.iSTIG.STIG_INFO.SI_DATA | ? {$_.SID_NAME -eq "stigid"} | Select-Object SID_DATA).SID_DATA
  $script:CKL_RELEASEINFO = ($LOADEDCKLFile.CHECKLIST.STIGS.iSTIG.STIG_INFO.SI_DATA | ? {$_.SID_NAME -eq "releaseinfo"} | Select-Object SID_DATA).SID_DATA
  $script:CKL_TITLE = ($LOADEDCKLFile.CHECKLIST.STIGS.iSTIG.STIG_INFO.SI_DATA | ? {$_.SID_NAME -eq "title"} | Select-Object SID_DATA).SID_DATA
  $script:STIGS = ($LOADEDCKLFile.CHECKLIST.STIGS.iSTIG.VULN )
  $script:STIGS_COUNT = $STIGS.Count
  $script:STIGS_NF = $STIGS | ? {$_.STATUS -match "NotAFinding"}
  $script:STIGS_NF_COUNT = $STIGS_NF.Count
  $script:STIGS_OPEN = $STIGS | ? {$_.STATUS -match "Open"}
  $script:STIGS_OPEN_COUNT = $STIGS_OPEN.Count
  $script:STIGS_NA = $STIGS | ? {$_.STATUS -match "Not_Applicable"}
  $script:STIGS_NA_COUNT = $STIGS_NA.Count
  $script:STIGS_NR = $STIGS | ? {$_.STATUS -match "Not_Reviewed"}
  $script:STIGS_NR_COUNT = $STIGS_NR.Count
}

function Close-CKL { 
  Write-Host "Saving $LOADEDCKLFILE..."
  $LOADEDCKLFile.PreserveWhitespace = $true
  $LOADEDCKLFile.Save($inputckl) 
}
##############################################################
# Start of Script...

$Choice = $null
# Stay in a loop until we want to exit
while ($Choice -ne 3) {
  $Title = "What would you like to do"
  if ($inputckl -eq $null)
    { $Prompt = "Enter your choice`n " } 
  else
    { $Prompt = "Loaded CKL is $inputckl`n " }
  $Choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&Load_&_Edit_CKL", "&Save_CKL", "&Mass_Update", "&Quit")
  $Default = 3
  $Choice = $host.UI.PromptForChoice($Title, $Prompt, $Choices, $Default)
  switch($Choice) {
    0 { #HMMM Before we load new file do we want to see if we changed it????
        if ($inputckl -eq $null) { 
          Write-Host "CKL File not Provided`n"
          $inputckl = Read-Host "Full Path to CKL"
          while (!(Test-Path $inputckl -PathType Leaf)) { 
            Write-Host "File Does not Exist`n"
            $inputckl = Read-Host "Full Path to CKL"
          }
        }
        Open-CKL $inputckl
        CKL-Prompt
      }
    1 { Close-CKL }
    2 { Write-Host "Cancel - Write your code"}
    3 { ##HMMM do we want to prompt to save?
        Write-Host "Exiting...."
        exit
      }
  }
}