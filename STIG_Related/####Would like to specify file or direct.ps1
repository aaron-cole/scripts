####Would like to specify file or directory with CKLs
##File Mode
    ## Display info about single CKL
    ## Be able to change info in CKL
        #hostname/IP/MAC
    ## Review Items
        #update text/comments/change to close/NA/NR/Open
## Diretory Mode
    ##Mass change text/comments/status
    ##??output info or edit single
#################################



$CKLFile=[xml] (Get-content -Path C:\SCAP\new\rhel8ansible.colehome.local-RHEL_8_V1R13-2024_03_10.ckl)
$CKLFile.PreserveWhitespace = $true

$STIGS = ($CKLFile.CHECKLIST.STIGS.iSTIG.VULN )
$STIGS_COUNT = $STIGS.Count
$STIGS_NF = $STIGS | ? {$_.STATUS -match "NotAFinding"}
$STIGS_NF_COUNT = $STIGS_NF.Count
$STIGS_OPEN = $STIGS | ? {$_.STATUS -match "Open"}
$STIGS_OPEN_COUNT = $STIGS_OPEN.Count
$STIGS_NA = $STIGS | ? {$_.STATUS -match "Not_Applicable"}
$STIGS_NA_COUNT = $STIGS_NA.Count
$STIGS_NR = $STIGS | ? {$_.STATUS -match "Not_Reviewed"}
$STIGS_NR_COUNT = $STIGS_NR.Count


Write-Host "################################"
Write-Host "STIG Has $STIGS_COUNT Items"
Write-Host "STIG CKL has"
Write-Host "Closed(C):  $STIGS_NF_COUNT"
Write-Host "Not Applicable(AN): $STIGS_NA_COUNT"
Write-Host "Not Reviewed(RN):   $STIGS_NR_COUNT"
Write-Host "Open(O):           $STIGS_OPEN_COUNT"
Write-Host "################################"

# PromptForChoice Args
$Title = "What Do You Want to deal with?"
$Prompt = "Enter your choice"
$Choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&Closed", "&AN", "&RN", "&Open", "&Quit")
$Default = 1

# Prompt for the choice
$Choice = $host.UI.PromptForChoice($Title, $Prompt, $Choices, $Default)

# Action based on the choice
switch($Choice)
{
    0 { Write-Host "Yes - Write your code"}
    1 { Write-Host "No - Write your code"}
    2 { Write-Host "Cancel - Write your code"}
    3 { Write-Host "Cancel - Write your code"}
    4 { Write-Host "Quit - Write your code"
        exit
      }
}