# Install the powershell-yaml module if it's not already installed
if (!(Get-Module -ListAvailable powershell-yaml)) {
    Install-Module powershell-yaml
}

# Import the powershell-yaml module
Import-Module powershell-yaml

# Load the SCAP datastream XML file
$scapXml = [xml](Get-Content -Path "RHEL_SCAP/rhel_scap-1.06-2024-10-26.xml")

# Create an XmlNamespaceManager
$nsmgr = New-Object System.Xml.XmlNamespaceManager($scapXml.NameTable)
$nsmgr.AddNamespace("ds", "http://checklists.nist.gov/xccdf/1.2")

# Select only the top-level Group elements
$groups = $scapXml.SelectNodes("//ds:Benchmark/ds:Group", $nsmgr)

# Create an ordered dictionary to store the output
$output = New-Object System.Collections.Specialized.OrderedDictionary

# Iterate over each top-level group
foreach ($group in $groups) {
    # Extract the group ID
    $groupId = $group.GetAttribute("id")

    # Extract the title
    $groupTitle = $group.SelectSingleNode("./ds:title", $nsmgr).InnerText

    # Extract the description
    $groupDescription = $group.SelectSingleNode("./ds:description", $nsmgr).InnerText

    # Create an ordered dictionary for SubgroupIds
    $subgroupIds = New-Object System.Collections.Specialized.OrderedDictionary

    # Extract the subgroup IDs
    $group.SelectNodes("./ds:Group", $nsmgr) | ForEach-Object {
        $subgroupId = $_.GetAttribute("id")
        $subgroupTitle = $_.SelectSingleNode("./ds:title", $nsmgr).InnerText
        $subgroupDescription = $_.SelectSingleNode("./ds:description", $nsmgr).InnerText
        $subgroupPlatform = $_.SelectSingleNode("./ds:platform", $nsmgr).GetAttribute("idref")
        
        # Create an ordered dictionary for the subgroup
        $subgroupData = New-Object System.Collections.Specialized.OrderedDictionary
        $subgroupData["GroupId"] = $subgroupId
        $subgroupData["SubgroupTitle"] = $subgroupTitle
        $subgroupData["SubgroupDescription"] = $subgroupDescription
        $subgroupData["subgroupPlatform"] = $subgroupPlatform

        # Extract the rule IDs and platform IDs
        $ruleIds = $_.SelectNodes(".//ds:Rule", $nsmgr) | ForEach-Object {
            $ruleId = $_.GetAttribute("id")
            $platformNode = $_.SelectSingleNode("./ds:platform", $nsmgr)
            $platformId = if ($platformNode) { $platformNode.GetAttribute("idref") } else { "" }
            [PSCustomObject]@{
                RuleId = $ruleId
                Platform = $platformId
            }
        }
        $subgroupData["RuleId"] = $ruleIds        

        # Add the subgroup data to the $subgroupIds dictionary
        $subgroupIds[$subgroupId] = $subgroupData 
    }

    # Create an ordered dictionary for the group
    $groupData = New-Object System.Collections.Specialized.OrderedDictionary
    $groupData["GroupId"] = $groupId
    $groupData["GroupTitle"] = $groupTitle  # Added title
    $groupData["GroupDescription"] = $groupDescription
    $groupData["SubgroupIds"] = $subgroupIds

    # Add the group data to the output dictionary
    $output[$groupId] = $groupData
}

# Export the output to a YAML file
$output | ConvertTo-Yaml | Out-File "scap_groups.yaml"