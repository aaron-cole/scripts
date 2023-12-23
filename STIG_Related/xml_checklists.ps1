[xml]$XmlDocument = Get-content -Path d.ckl
$XmlDocument.GetType().FullName
$XmlDocument

$XmlDocument.CHECKLIST.VULN.Count

$XmlDocument.CHECKLIST.VULN

V2 - 
[xml]$XmlDocument = Get-content -Path server.ckl
$XmlDocument.GetType().FullName
$XmlDocument

#Asset information
$XmlDocument.CHECKLIST.ASSET

#Stig info
$XmlDocument.CHECKLIST.STIGS.iSTIG.STIG_INFO.SI_DATA

