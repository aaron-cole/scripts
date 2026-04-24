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

# Select all the Rule elements using the namespace manager
$rules = $scapXml.SelectNodes("//ds:Rule", $nsmgr)

# Create a hashtable to store the rule IDs and platformIdrefs
$ruleData = @{}

# Iterate over each rule and extract the desired information
foreach ($rule in $rules) {
    # Extract the rule ID
    $ruleId = $rule.GetAttribute("id")

    # Extract the rule version
    $version = $rule.SelectSingleNode("./ds:version", $nsmgr).InnerText

    # Skip if the version starts with "RHEL-07"
    if ($version -match "^RHEL-07") {
        continue
    }

    # Extract the platformIdref
    $platformIdref = $rule.SelectSingleNode("./ds:platform", $nsmgr)?.GetAttribute("idref") ?? ""

    # Store the platformIdref with the rule ID as the key
    $ruleData[$version] = $platformIdref
}

# Load the YAML file
$yamlFile = "working_copy.yaml"
$yamlData = Get-Content $yamlFile | ConvertFrom-Yaml

# Update the platformIdref for each STIG entry
foreach ($stig in $yamlData.stigs.GetEnumerator()) {
    $version = $stig.Value.version
    if ($ruleData.ContainsKey($version)) {
        $stig.Value.platform_idref = $ruleData[$version]
    } else {
        # Add the oval_def key if it doesn't exist
        if (-not $stig.Value.ContainsKey("platform_idref")) {
            $stig.Value.platform_idref = $null 
        }
    }
}

# Convert the updated YAML data back to YAML format
$updatedYaml = $yamlData | ConvertTo-Yaml

# Write the updated YAML data back to the file
$updatedYaml | Set-Content $yamlFile -Encoding UTF8