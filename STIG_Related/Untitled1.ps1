Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to create a basic XCCDF file
function Create-XCCDF {
  param(
    [string]$BenchmarkName,
    [string]$Description
  )

  $xccdf = @"
<?xml version="1.0" encoding="UTF-8"?>
<Benchmark xmlns="http://checklists.nist.gov/xccdf/1.2" id="$BenchmarkName" resolved="1">
  <status>draft</status>
  <title>$BenchmarkName</title>
  <description>$Description</description>
  <version>1.0</version>
</Benchmark>
"@

  return $xccdf
}

# Function to create a basic OVAL definition
function Create-OVAL {
  param(
    [string]$DefinitionId,
    [string]$Description
  )

  $oval = @"
<?xml version="1.0" encoding="UTF-8"?>
<oval_definitions xmlns="http://oval.mitre.org/XMLSchema/oval-definitions-5" xmlns:oval="http://oval.mitre.org/XMLSchema/oval-common-5">
  <definitions>
    <definition id="$DefinitionId" version="1" class="compliance">
      <metadata>
        <title>$DefinitionId</title>
        <description>$Description</description>
      </metadata>
      <criteria operator="AND">
        </criteria>
    </definition>
  </definitions>
</oval_definitions>
"@

  return $oval
}

# Create the main form
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "SCAP Content Generator"
$mainForm.Size = New-Object System.Drawing.Size(400, 300)

# Create labels and text boxes for XCCDF
$benchmarkNameLabel = New-Object System.Windows.Forms.Label
$benchmarkNameLabel.Text = "Benchmark Name:"
$benchmarkNameLabel.Location = New-Object System.Drawing.Point(10, 20)
$mainForm.Controls.Add($benchmarkNameLabel)

$benchmarkNameTextBox = New-Object System.Windows.Forms.TextBox
$benchmarkNameTextBox.Location = New-Object System.Drawing.Point(120, 20)
$benchmarkNameTextBox.Size = New-Object System.Drawing.Size(200, 20)
$mainForm.Controls.Add($benchmarkNameTextBox)

$descriptionLabel = New-Object System.Windows.Forms.Label
$descriptionLabel.Text = "Description:"
$descriptionLabel.Location = New-Object System.Drawing.Point(10, 50)
$mainForm.Controls.Add($descriptionLabel)

$descriptionTextBox = New-Object System.Windows.Forms.TextBox
$descriptionTextBox.Location = New-Object System.Drawing.Point(120, 50)
$descriptionTextBox.Size = New-Object System.Drawing.Size(200, 20)
$mainForm.Controls.Add($descriptionTextBox)

# Create labels and text boxes for OVAL
$definitionIdLabel = New-Object System.Windows.Forms.Label
$definitionIdLabel.Text = "Definition ID:"
$definitionIdLabel.Location = New-Object System.Drawing.Point(10, 80)
$mainForm.Controls.Add($definitionIdLabel)

$definitionIdTextBox = New-Object System.Windows.Forms.TextBox
$definitionIdTextBox.Location = New-Object System.Drawing.Point(120, 80)
$definitionIdTextBox.Size = New-Object System.Drawing.Size(200, 20)
$mainForm.Controls.Add($definitionIdTextBox)

$ovalDescriptionLabel = New-Object System.Windows.Forms.Label
$ovalDescriptionLabel.Text = "Description:"
$ovalDescriptionLabel.Location = New-Object System.Drawing.Point(10, 110)
$mainForm.Controls.Add($ovalDescriptionLabel)

$ovalDescriptionTextBox = New-Object System.Windows.Forms.TextBox
$ovalDescriptionTextBox.Location = New-Object System.Drawing.Point(120, 110)
$ovalDescriptionTextBox.Size = New-Object System.Drawing.Size(200, 20)
$mainForm.Controls.Add($ovalDescriptionTextBox)

# Load OVAL schema
$schemaSet = New-Object System.Xml.Schema.XmlSchemaSet
$schemaSet.Add("http://oval.mitre.org/XMLSchema/oval-definitions-5", "C:\Users\aaron\Downloads\OVALRepo\oval_schemas\5.11.2\all-oval-definitions.xsd")
#$schemaSet = [System.Xml.Schema.XmlSchema]::Read((Get-Item "C:\Users\aaron\Downloads\OVALRepo\oval_schemas\5.11.2\sch"), $null)

# Extract object types
$objectTypes = @()
foreach ($schema in $schemaSet.Schemas()) {
  $objectTypes += $schema.Elements | Where-Object { $_.Name -match "^oval:.*_object$" } | ForEach-Object { $_.Name }
}

# Populate dropdown list with object types
$objectTypeDropdown = New-Object System.Windows.Forms.ComboBox
$objectTypeDropdown.DataSource = $objectTypes
$mainForm.Controls.Add($objectTypeDropdown)

# Create a button to generate the SCAP content
$generateButton = New-Object System.Windows.Forms.Button
$generateButton.Text = "Generate SCAP Content"
$generateButton.Location = New-Object System.Drawing.Point(100, 150)
$generateButton.Size = New-Object System.Drawing.Size(150, 30)
$mainForm.Controls.Add($generateButton)

# Add an event handler to the button
$generateButton.Add_Click({
  $xccdfContent = Create-XCCDF -BenchmarkName $benchmarkNameTextBox.Text -Description $descriptionTextBox.Text
  $ovalContent = Create-OVAL -DefinitionId $definitionIdTextBox.Text -Description $ovalDescriptionTextBox.Text

  # Save the content to files
  $xccdfContent | Out-File -FilePath "MyBenchmark.xccdf"
  $ovalContent | Out-File -FilePath "MyDefinition.xml"

  Write-Host "XCCDF and OVAL files created successfully."
})


# Display the form
$mainForm.ShowDialog()