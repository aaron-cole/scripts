$stig_form = 'C:\Temp\My_Stuff-master\Powershell reword\Untitled1.pdf' 
$output_file = 'C:\Temp\My_Stuff-master\Powershell reword\testoutput1.pdf'
[System.Reflection.Assembly]::LoadFrom('C:\Temp\My_Stuff-master\Powershell reword\itextsharp.dll') | Out-Null 
$reader = New-Object iTextSharp.text.pdf.PdfReader -ArgumentList $stig_form 
$stamper = New-Object iTextSharp.text.pdf.PdfStamper($reader,[System.IO.File]::Create($output_file)) 

$pdf_fields =@{ 
    'Enclave' =  'home'; 
    'Date' = (Get-Date -Format 'MM/dd/yyyy'); 
    'Vul_ID' = 'V-71849'; 
    'STIG_ID' = 'RHEL-07-010010'; 
    'Rule_ID' = 'SV-86473r4_rule'; 
    'Severity' = 'CAT II'; 
    'RuleTitle' = 'The Red Hat Enterprise Linux operating system must be configured so that the file permissions, ownership, and group membership of system files and commands match the vendor values.'; 
    'DocFacts' = 'This is a test for documentable facts
Not sure if this will work';  
} 

foreach ($field in $pdf_fields.GetEnumerator()) { 
    $stamper.AcroFields.SetField($field.Key, $field.Value) | Out-Null 
} 

$stamper.close()
$reader.close()

