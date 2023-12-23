﻿## Path to the PDF form you'd like to fill in 
$change_form = 'c:\users\aaroncole\desktop\test.pdf' 
  
## Create the unique control number 
$control_number = (Get-Date -Format 'yyyyMMddmmss') 
$urgency = Read-Host -Prompt "What's the urgency? (Standard (S), Urgent (U), Emergency (E))" 
$title = Read-Host -Prompt 'Title?' 
$system = Read-Host -Prompt 'Systems affected?' 
$change_justification = Read-Host 'Change and justification?' 
$impact_testing = Read-Host 'Potential impact and testing?' 
$backout_plan = Read-Host 'Back out plan?' 
$imp_date = Read-Host 'Proposed implementation date?' 
  
$my_name = 'Aaron Cole' 
## The PDF that will be saved with the filled-in forms. 
## In my instance, the file is saved as the unique control number we use 
$output_file = "FILE_PATH\$control_number.pdf" 
  
## Load the iTextSharp DLL to do all the heavy-lifting 
[System.Reflection.Assembly]::LoadFrom('c:\ausers\aaron.cole\desktop\itextsharp.dll') | Out-Null 
  
## Instantiate the PdfReader object to open the PDF 
$reader = New-Object iTextSharp.text.pdf.PdfReader -ArgumentList $change_form 
  
## Instantiate the PdfStamper object to insert the form fields to 
$stamper = New-Object iTextSharp.text.pdf.PdfStamper($reader,[System.IO.File]::Create($output_file)) 
  
## Create a hash table with all field names and properties 
$pdf_fields =@{ 
    'Control Number' =  $control_number; 
    'Change Proposal Title' = $title; 
    'Date Created' = (Get-Date -Format 'MM/dd/yyyy'); 
    'Originator' = $my_name; 
    'System' = $system; 
    'Proposed Change and Justification' = $change_justification; 
    'Potential Impact and Testing Performed' = $impact_testing; 
    'Back out Plan' = $backout_plan; 
    'Review Date' = (Get-Date -Format 'MM/dd/yyyy');  
    'System Owner' = $my_name; 
    'Approve1' = 'Yes'; 
    'Assigned to' = $my_name; 
    'Proposed Implementation Date' = $imp_date; 
    'Log' = 'Yes'; 
} 
  
switch ($urgency) { 
    'S' {$pdf_fields.Set_Item('Standard','Yes')} 
    'U' {$pdf_fields.Set_Item('Urgent','Yes')} 
    'E' {$pdf_fields.Set_Item('Emergency','Yes')} 
    Default {} 
} 
  
## Apply all hash table elements into the PDF form 
foreach ($field in $pdf_fields.GetEnumerator()) { 
    $stamper.AcroFields.SetField($field.Key, $field.Value) | Out-Null 
} 
  
## Close up shop 
$stamper.Close()