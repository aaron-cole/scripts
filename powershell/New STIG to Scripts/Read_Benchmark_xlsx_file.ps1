#Declare the file path and sheet name
$file = "D:\Documents\STIGs\NOT_REVIEWED_of RHEL7_Benchmark(AutoRecovered).xlsx"
$sheetName = "RHEL7_Benchmark"
#Create an instance of Excel.Application and Open Excel file
$objExcel = New-Object -ComObject Excel.Application
$workbook = $objExcel.Workbooks.Open($file)
$sheet = $workbook.Worksheets.Item($sheetName)
$objExcel.Visible=$false
#Count max row
$rowMax = ($sheet.UsedRange.Rows).count
#Declare the starting positions
$rowcolVuln_ID,$colVuln_ID = 1,1
$rowSeverity,$colSeverity = 1,2
$rowGRP_TITLE,$colGRP_TITLE = 1,3
$rowRule_ID,$colRule_ID = 1,4
$rowSTIG_ID,$colSTIG_ID = 1,5
$rowRule_Title,$colRule_Title = 1,6
$rowDiscussion,$colDiscussion = 1,7
$rowFix_Text,$colFix_Text = 1,8
#loop to get values and store it
for ($i=1; $i -le $rowMax-1; $i++)
{
$Vuln_ID = $sheet.Cells.Item($rowcolVuln_ID+$i,$colVuln_ID).text
$Severity = $sheet.Cells.Item($rowSeverity+$i,$colSeverity).text
$GRP_TITLE = $sheet.Cells.Item($rowGRP_TITLE+$i,$colGRP_TITLE).text
$Rule_ID = $sheet.Cells.Item($rowRule_ID+$i,$colRule_ID).text
$STIG_ID = $sheet.Cells.Item($rowSTIG_ID+$i,$colSTIG_ID).text
$Rule_Title = $sheet.Cells.Item($rowRule_Title+$i,$colRule_Title).text
$Discussion = $sheet.Cells.Item($rowDiscussion+$i,$colDiscussion).text
$Fix_Text = $sheet.Cells.Item($rowFix_Text+$i,$colFix_Text).text
$OUTPUTFILE = "$Vuln_ID.txt"


Add-Content $OUTPUTFILE "<xccdf:select idref=`"xccdf_mil.disa.stig_group_$Vuln_ID`" selected=`"true`" />"
Add-Content $OUTPUTFILE ""
Add-Content $OUTPUTFILE "<xccdf:Group id=`"xccdf_mil.disa.stig_group_$Vuln_ID`">
        <xccdf:title>$GRP_TITLE</xccdf:title>
        <xccdf:description>&lt;GroupDescription&gt;&lt;/GroupDescription&gt;</xccdf:description>
        <xccdf:Rule id=`"xccdf_mil.disa.stig_rule_$Rule_ID`" severity=`"$Severity`" weight=`"10.0`">
          <xccdf:version update=`"http://iase.disa.mil/stigs`">$STIG_ID</xccdf:version>
          <xccdf:title>$Rule_Title</xccdf:title>
          <xccdf:description>&lt;VulnDiscussion&gt;$Discussion&lt;/VulnDiscussion&gt;&lt;FalsePositives&gt;&lt;/FalsePositives&gt;&lt;FalseNegatives&gt;&lt;/FalseNegatives&gt;&lt;Documentable&gt;false&lt;/Documentable&gt;&lt;Mitigations&gt;&lt;/Mitigations&gt;&lt;SeverityOverrideGuidance&gt;&lt;/SeverityOverrideGuidance&gt;&lt;PotentialImpacts&gt;&lt;/PotentialImpacts&gt;&lt;ThirdPartyTools&gt;&lt;/ThirdPartyTools&gt;&lt;MitigationControl&gt;&lt;/MitigationControl&gt;&lt;Responsibility&gt;&lt;/Responsibility&gt;&lt;IAControls&gt;&lt;/IAControls&gt;</xccdf:description>
          <xccdf:reference>
            <dc:title>DPMS Target Red Hat 7</dc:title>
            <dc:publisher>DISA</dc:publisher>
            <dc:type>DPMS Target</dc:type>
           <dc:subject>Red Hat 7</dc:subject>
            <dc:identifier>2777</dc:identifier>
          </xccdf:reference>
          <xccdf:ident system=`"http://iase.disa.mil/cci`">ADD_CCI#_HERE</xccdf:ident>
          <xccdf:fixtext fixref=`"F-$Vuln_ID_fix`">$Fix_Text</xccdf:fixtext>
          <xccdf:fix id=`"F-$Vuln_ID_fix`" />
          <xccdf:check system=`"http://oval.mitre.org/XMLSchema/oval-definitions-5`">
            <xccdf:check-content-ref name=`"oval:mil.disa.stig.rhel7:def:$i`" href=`"U_Red_Hat_Enterprise_Linux_7_V2R2_STIG_SCAP_1-2_Benchmark-oval.xml`" />
          </xccdf:check>
        </xccdf:Rule>
      </xccdf:Group>"
Add-Content $OUTPUTFILE ""

Add-Content $OUTPUTFILE "        <definition class=`"compliance`" id=`"oval:mil.disa.stig.rhel7:def:$i`" version=`"1`">
          <metadata>
            <title>$Rule_Title</title>
            <affected family=`"unix`">
              <platform>Red Hat Enterprise Linux 7</platform>
            </affected>
            <description>$Rule_Title</description>
            <reference source=`"mil.disa.stig.rhel7`" ref_id=`"{REPLACE_ME}`" />
          </metadata>
          <criteria>
            <criterion test_ref=`"oval:mil.disa.stig.rhel7:tst:$i`" comment=`"{REPLACE_ME}`" negate=`"true`"  />
          </criteria>
        </definition>	"
Add-Content $OUTPUTFILE ""
#Write-Host $Vuln_ID
#Write-Host $Severity
#Write-Host $GRP_TITLE
#Write-Host $Rule_ID
#Write-Host $STIG_ID
#Write-Host $Rule_Title
#Write-Host $Discussion
#Write-Host $Fix_Text
}
#close excel file
$objExcel.quit()