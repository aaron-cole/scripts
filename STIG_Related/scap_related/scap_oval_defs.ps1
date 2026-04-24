# Install the powershell-yaml module if it's not already installed
if (!(Get-Module -ListAvailable powershell-yaml)) {
    Install-Module powershell-yaml
}

# Import the powershell-yaml module
Import-Module powershell-yaml

# Function to recursively extract criterion and/or criteria elements
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
$scapXml = [xml](Get-Content -Path "RHEL_SCAP/rhel_scap-1.06-2024-10-26.xml")

# Create an XmlNamespaceManager
$nsmgr = New-Object System.Xml.XmlNamespaceManager($scapXml.NameTable)
$nsmgr.AddNamespace("ds", "http://checklists.nist.gov/xccdf/1.2")
$nsmgr.AddNamespace("oval-definitions", "http://oval.mitre.org/XMLSchema/oval-definitions-5")

# Select all the definition elements with class="compliance"
$definitions = $scapXml.SelectNodes("//oval-definitions:definition[@class='compliance']", $nsmgr)

# Create an ordered dictionary to store the output
$output = New-Object System.Collections.Specialized.OrderedDictionary

foreach ($definition in $definitions) {
    # Extract the id attribute
    $id = $definition.GetAttribute("id")

    # Create an ordered dictionary for the definition
    $definitionData = New-Object System.Collections.Specialized.OrderedDictionary

    # Extract the version attribute
    $definitionData.Version = $definition.GetAttribute("version")

    # Extract the title text
    $definitionData.Title = $definition.SelectSingleNode("./oval-definitions:metadata/oval-definitions:title", $nsmgr).InnerText

    # Extract the description text
    $definitionData.Description = $definition.SelectSingleNode("./oval-definitions:metadata/oval-definitions:description", $nsmgr).InnerText

    # Extract platform or platforms
    $definitionData.Platforms = ($definition.SelectNodes("./oval-definitions:metadata/oval-definitions:affected/oval-definitions:platform", $nsmgr) | ForEach-Object { $_.InnerText }) -join ','

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

# Export the output to a YAML file
$output | ConvertTo-Yaml | Out-File "scap_definitions.yaml"