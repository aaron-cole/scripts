


#$Vnums_TO_Update = "V-204460","V-204598"#,"V-932","V-11947","V-72771"
$Vnums_TO_Update = "V-204422","V-204427", "V-204428"

$CKLDir = gci "C:\Temp\STIGCKLS\tests"

Foreach ($file in $CKLDir) {

#Load Each CKL File
[XML]$CKLFile=Get-Content $file.fullname
$CKLFile.PreserveWhitespace = $true
$CKLUpdated = "false"

$STIGS = ($CKLFile.CHECKLIST.STIGS.iSTIG.VULN ) #| ? {$_.STATUS -notmatch "NotAFinding"})

Foreach ($STIG in $STIGS) {

    foreach ($vnum_TO_Update in $Vnums_TO_Update) {

        $cknum = ($STIG.STIG_DATA | ? {$_.VULN_ATTRIBUTE -eq "Vuln_Num"} | Select-Object ATTRIBUTE_DATA).ATTRIBUTE_DATA

        if ($cknum -like $Vnum_TO_Update) {

       
            $STIG.STATUS = "NotAFinding"
            $STIG.FINDING_DETAILS = ""
            $STIG.COMMENTS = "Documented with ISSM - AC 5/10/2021"
            $CKLUpdated = "true"
            
        }
    }
}


##Only save the ckl if it was changed.
if ($CKLUpdated -eq "true") {
    $CKLFILE.Save($file.FullName)
}
}
           