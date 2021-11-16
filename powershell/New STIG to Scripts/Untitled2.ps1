Add-Type -Path .\itextsharp.dll
[System.Reflection.Assembly]::LoadFrom('.\itextsharp.dll') | Out-Null 

$reader = New-Object iTextSharp.text.pdf.pdfreader -ArgumentList 'D:\Workdir\Powershell\Blank.pdf'

$output_file = 'test.pdf'

## Instantiate the PdfStamper object to insert the form fields to 
$stamper = New-Object iTextSharp.text.pdf.PdfStamper($reader,[System.IO.File]::Create($output_file)) 