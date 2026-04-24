# Install the powershell-yaml module if it's not already installed
if (!(Get-Module -ListAvailable powershell-yaml)) {
    Install-Module powershell-yaml
}

# Import the powershell-yaml module
Import-Module powershell-yaml

# Function to recursively extract criterion, criteria, and extend_definition elements
function Get-Criteria {
    param(
        [System.Xml.XmlNode]$CriteriaNode,
        [System.Xml.XmlNamespaceManager]$Nsmgr
    )

    $result = @()

    # Extract operator and negate attributes if present
    $operator = $CriteriaNode.GetAttribute("operator")
    $negate = $CriteriaNode.GetAttribute("negate")

    # Create a hashtable for the current criteria level
    $criteriaData = [ordered]@{
        criteria = @{
            criteria_operator = $operator ?? "AND"  # Default operator
            criteria_negate = $negate ?? "false"    # Default negate
            criterion = @()
        }
    }

    # Extract criterion elements
    $criterionNodes = $CriteriaNode.SelectNodes("./oval-definitions:criterion", $Nsmgr)
    foreach ($criterionNode in $criterionNodes) {
        $criteriaData.criteria.criterion += [PSCustomObject]@{
            criterion_comment = $criterionNode.GetAttribute("comment")
            criterion_test = $criterionNode.GetAttribute("test_ref")
        }
    }

    # Extract extend_definition elements
    $extendDefinitionNodes = $CriteriaNode.SelectNodes("./oval-definitions:extend_definition", $Nsmgr)
    foreach ($extendDefinitionNode in $extendDefinitionNodes) {
        $criteriaData.criteria.criterion += @{
            extend_definition_comment = $extendDefinitionNode.GetAttribute("comment")
            extend_definition_ref = $extendDefinitionNode.GetAttribute("definition_ref")
        }
    }

    # Recursively extract nested criteria elements
    $nestedCriteriaNodes = $CriteriaNode.SelectNodes("./oval-definitions:criteria", $Nsmgr)
    foreach ($nestedCriteriaNode in $nestedCriteriaNodes) {
        $nestedResult = Get-Criteria -CriteriaNode $nestedCriteriaNode -Nsmgr $Nsmgr
        $criteriaData.criteria.criterion += $nestedResult
    }

    # Add the criteria data to the result
    $result += $criteriaData

    return $result
}

# Load the SCAP datastream XML file
$scapXml = [xml](Get-Content -Path "C:\Users\aaron\OneDrive\Applications\GitHub\Scap\RHEL_SCAP\rhel_scap-1.07-2025-3-08.xml")

# Create an XmlNamespaceManager
$nsmgr = New-Object System.Xml.XmlNamespaceManager($scapXml.NameTable)
$nsmgr.AddNamespace("ds", "http://checklists.nist.gov/xccdf/1.2")
$nsmgr.AddNamespace("oval-definitions", "http://oval.mitre.org/XMLSchema/oval-definitions-5")

# Select all the definition elements with class="compliance"
$definitions = $scapXml.SelectNodes("//oval-definitions:definition[@class='compliance']", $nsmgr)

# Create an ordered dictionary to store the output
$output = @{}

foreach ($definition in $definitions) {
    # Extract the id attribute
    $id = $definition.GetAttribute("id")

    # Create an ordered dictionary for the definition
    $definitionData = New-Object System.Collections.Specialized.OrderedDictionary

    # Extract the version attribute
    $definitionData.oval_def_vers = $definition.GetAttribute("version")

    # Extract the title text
    $definitionData.oval_def_title = $definition.SelectSingleNode("./oval-definitions:metadata/oval-definitions:title", $nsmgr).InnerText

    # Extract the description text
    $definitionData.oval_def_description = $definition.SelectSingleNode("./oval-definitions:metadata/oval-definitions:description", $nsmgr).InnerText

    # Extract platform or platforms
    $definitionData.oval_def_platforms = ($definition.SelectNodes("./oval-definitions:metadata/oval-definitions:affected/oval-definitions:platform", $nsmgr) | ForEach-Object { $_.InnerText }) -join ','

    # Extract criterion and/or criteria elements
    $criteria = @()
    $criteriaNodes = $definition.SelectNodes("./oval-definitions:criteria", $nsmgr)
    foreach ($criteriaNode in $criteriaNodes) {
        $criteria += Get-Criteria -CriteriaNode $criteriaNode -Nsmgr $nsmgr
    }

    $definitionData.criteria = $criteria

    # Add the definition data to the output dictionary with the ID as the key
    $output[$id] = $definitionData
}

# Load the YAML file
$yamlFile = "working_copy.yaml"
$yamlData = Get-Content $yamlFile | ConvertFrom-Yaml

# Update the YAML data with definition details
foreach ($stig in $yamlData.stigs.GetEnumerator()) {
    # Extract the oval_def number
    $ovalDefNumber = ($stig.Value.oval_def -split ':')[-1]

    # Check if the definition exists in the $output
    if ($output.ContainsKey("oval:rhel.stig:def:$ovalDefNumber")) {
        # Get the definition data
        $definitionData = $output["oval:rhel.stig:def:$ovalDefNumber"]

        # Add the definition data to the stig entry
        $stig.Value.oval_def_data = $definitionData
    }
}

# Convert the updated YAML data back to YAML format
$updatedYaml = $yamlData | ConvertTo-Yaml

# Write the updated YAML data back to the file
$updatedYaml | Set-Content $yamlFile -Encoding UTF8