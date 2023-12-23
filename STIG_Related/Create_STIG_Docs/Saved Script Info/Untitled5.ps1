##################################
#Stuff to Load before we go forth#
##################################
#Load XML
[xml]$CKLFile = Get-Content -Path 'C:\Temp\My_Stuff-master\Powershell reword\server.ckl'

#Get the Open Findings
$OPENFINDINGS = $CKLFile.CHECKLIST.STIGS.iSTIG.VULN | ? {$_.STATUS -match "Open"}

#Load PDF Reader DLL
[System.Reflection.Assembly]::LoadFrom('C:\Temp\My_Stuff-master\Powershell reword\itextsharp.dll') | Out-Null 

#Blank PDF Documentable Form
$blank_form = 'C:\Temp\My_Stuff-master\Powershell reword\Untitled1.pdf' 


##################################
###HEAVY LIFTING NOW###

#We have to loop through each STIG
for ($i=0;$i -lt $OPENFINDINGS.Count; $i++) {

#Assigning Variables of the Data that we are going to write to the pdf
$VULID = $OPENFINDINGS[$i].STIG_DATA.Get(0).ATTRIBUTE_DATA
$SEVERITY = $OPENFINDINGS[$i].STIG_DATA.Get(1).ATTRIBUTE_DATA
$RULEID = $OPENFINDINGS[$i].STIG_DATA.Get(3).ATTRIBUTE_DATA
$STIGID = $OPENFINDINGS[$i].STIG_DATA.Get(4).ATTRIBUTE_DATA
$RULETITLE = $OPENFINDINGS[$i].STIG_DATA.Get(5).ATTRIBUTE_DATA
$FINDINGS = $OPENFINDINGS[$i].FINDING_DETAILS
$COMMENTS = $OPENFINDINGS[$i].COMMENTS

#Since the CKL file doesn't do CATs, we do it here
Switch ($SEVERITY)
{
    low {$SEVERITYID = "CAT III"}
    medium {$SEVERITYID = "CAT II"}
    high {$SEVERITYID = "CAT I"}
    default {$SEVERITYID = ""}
}

#This will be our output file
$outputfile = "C:\Temp\My_Stuff-master\$VULID.pdf"

#Setup our fields we are going to write to
$pdf_fields =@{ 
    'Date' = (Get-Date -Format 'MM/dd/yyyy'); 
    'Vul_ID' = $VULID; 
    'STIG_ID' = $STIGID; 
    'Rule_ID' = $RULEID; 
    'Severity' = $SEVERITYID; 
    'RuleTitle' = $RULETITLE; 
    'DocFacts' = "$FINDINGS

$COMMENTS";  
} 

#Reader to read the PDF
$reader = New-Object iTextSharp.text.pdf.PdfReader -ArgumentList $blank_form 

#This is how we write to the PDF
$stamper = New-Object iTextSharp.text.pdf.PdfStamper($reader,[System.IO.File]::Create($outputfile)) 

#This is where we actually do the writting to the PDF
foreach ($field in $pdf_fields.GetEnumerator()) { 
    $stamper.AcroFields.SetField($field.Key, $field.Value) | Out-Null 
} 

#PDF isn't available until we close it out
$stamper.close()
$reader.close()
}

