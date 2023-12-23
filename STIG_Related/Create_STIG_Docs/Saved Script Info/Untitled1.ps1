﻿Add-Type -Path "C:\Temp\My_Stuff-master\Powershell reword\itextsharp.dll"

$PDF = New-Object iTextSharp.text.pdf.pdfreader -ArgumentList "C:\Temp\My_Stuff-master\Powershell reword\Blank-1.1.pdf"
$PDF = New-Object iTextSharp.text.pdf.pdfreader -ArgumentList "C:\Temp\My_Stuff-master\Powershell reword\Untitled.pdf"
#$PDF.AcroFields.XFA.DomDocument.XDP.DataSets.Data.TopMostSubForm | Get-Member
$PDF.AcroFields.Fields


$PDF.AcroFields.XFA.DomDocument.XDP.DataSets.Data.TopMostSubForm | Select-Object -Property "*"

Approved    iTextSharp.text.pdf.AcroFields+Item
Disapproved iTextSharp.text.pdf.AcroFields+Item
Date        iTextSharp.text.pdf.AcroFields+Item
Rule_Title  iTextSharp.text.pdf.AcroFields+Item
STIG_DESC   iTextSharp.text.pdf.AcroFields+Item
Doc_Facts   iTextSharp.text.pdf.AcroFields+Item
Comments    iTextSharp.text.pdf.AcroFields+Item
Reviewer    iTextSharp.text.pdf.AcroFields+Item
Chief       iTextSharp.text.pdf.AcroFields+Item
ISSM        iTextSharp.text.pdf.AcroFields+Item


Enclave      iTextSharp.text.pdf.AcroFields+Item
Date         iTextSharp.text.pdf.AcroFields+Item
Vul_ID       iTextSharp.text.pdf.AcroFields+Item
STIG_ID      iTextSharp.text.pdf.AcroFields+Item
Rule_ID      iTextSharp.text.pdf.AcroFields+Item
Severity     iTextSharp.text.pdf.AcroFields+Item
RuleTitle    iTextSharp.text.pdf.AcroFields+Item
DocFacts     iTextSharp.text.pdf.AcroFields+Item
Reviewer     iTextSharp.text.pdf.AcroFields+Item
Branch Chief iTextSharp.text.pdf.AcroFields+Item
ISSM         iTextSharp.text.pdf.AcroFields+Item