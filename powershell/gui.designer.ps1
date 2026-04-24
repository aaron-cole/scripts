$MenuStrip1_ItemClicked = {
}
$Form1_Load = {
}
Add-Type -AssemblyName System.Windows.Forms
. (Join-Path $PSScriptRoot 'gui.designer.designer.ps1')
$test.ShowDialog()