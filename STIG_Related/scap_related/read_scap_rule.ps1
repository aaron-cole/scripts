# Install the yaml module if it's not already installed
Import-Module powershell-yaml

# Load the SCAP datastream XML file
$scapXml = [xml](Get-Content -Path "C:\Users\aaron\OneDrive\Applications\GitHub\Scap\RHEL_SCAP\rhel_scap-1.07-2025-03-08.xml")

# Create an XmlNamespaceManager
$nsmgr = New-Object System.Xml.XmlNamespaceManager($scapXml.NameTable)
$nsmgr.AddNamespace("ds", "http://checklists.nist.gov/xccdf/1.2")

# Load the YAML file
$yamlFile = "working_copy.yaml"
$yamlData = Get-Content $yamlFile | ConvertFrom-Yaml

# Select all the Rule elements using the namespace manager
$rules = $scapXml.SelectNodes("//ds:Rule", $nsmgr)

# Create a hashtable to store the rule versions and oval_defs
$ruleData = @{}

# Iterate over each rule and extract the desired information
foreach ($rule in $rules) {
    # Extract the rule ID
    $ruleId = $rule.GetAttribute("id")

    # Extract the rule title
    $version = $rule.SelectSingleNode("./ds:version", $nsmgr).InnerText

    # Skip if the version starts with "RHEL-07"
    #if ($version -match "^RHEL-07") {
    #    continue
    #}

    # Extract the rule description
    $oval_def = $rule.SelectSingleNode("./ds:check/ds:check-content-ref", $nsmgr).Attributes.GetNamedItem("name").Value

    # Extract the last part after "def:"
    $oval_def_parts = $oval_def -split ":"
    $oval_def_last = $oval_def_parts[-1] 

    # Store the oval_def with the version as the key
    $ruleData[$version] = $oval_def_last
}

# Update the oval_def for each STIG entry
foreach ($stig in $yamlData.stigs.GetEnumerator()) {
    $version = $stig.Value.version
    if ($ruleData.ContainsKey($version)) {
        $stig.Value.oval_def = $ruleData[$version]
    } else {
        # Add the oval_def key if it doesn't exist
        if (-not $stig.Value.ContainsKey("oval_def")) {
            $stig.Value.oval_def = $null 
        }
    }
}

# Convert the updated YAML data back to YAML format
$updatedYaml = $yamlData | ConvertTo-Yaml

# Write the updated YAML data back to the file
$updatedYaml | Set-Content $yamlFile