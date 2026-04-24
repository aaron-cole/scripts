$test = New-Object -TypeName System.Windows.Forms.Form
[System.Windows.Forms.Button]$Button1 = $null
[System.Windows.Forms.Button]$Button2 = $null
[System.Windows.Forms.MenuStrip]$MenuStrip1 = $null
[System.Windows.Forms.ToolStripMenuItem]$ToolStripMenuItem1 = $null
[System.Windows.Forms.ToolStripMenuItem]$AsdfToolStripMenuItem = $null
[System.Windows.Forms.ToolStripMenuItem]$AsdfToolStripMenuItem1 = $null
[System.Windows.Forms.ToolStripMenuItem]$AfsToolStripMenuItem = $null
[System.Windows.Forms.ToolStripMenuItem]$SdfToolStripMenuItem = $null
[System.Windows.Forms.ToolStripMenuItem]$ToolStripMenuItem2 = $null
[System.Windows.Forms.ToolStripMenuItem]$ToolStripMenuItem3 = $null
function InitializeComponent
{
$Button1 = (New-Object -TypeName System.Windows.Forms.Button)
$Button2 = (New-Object -TypeName System.Windows.Forms.Button)
$MenuStrip1 = (New-Object -TypeName System.Windows.Forms.MenuStrip)
$ToolStripMenuItem1 = (New-Object -TypeName System.Windows.Forms.ToolStripMenuItem)
$ToolStripMenuItem2 = (New-Object -TypeName System.Windows.Forms.ToolStripMenuItem)
$ToolStripMenuItem3 = (New-Object -TypeName System.Windows.Forms.ToolStripMenuItem)
$AsdfToolStripMenuItem = (New-Object -TypeName System.Windows.Forms.ToolStripMenuItem)
$AsdfToolStripMenuItem1 = (New-Object -TypeName System.Windows.Forms.ToolStripMenuItem)
$AfsToolStripMenuItem = (New-Object -TypeName System.Windows.Forms.ToolStripMenuItem)
$SdfToolStripMenuItem = (New-Object -TypeName System.Windows.Forms.ToolStripMenuItem)
$MenuStrip1.SuspendLayout()
$test.SuspendLayout()
#
#Button1
#
$Button1.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]134,[System.Int32]125))
$Button1.Name = [System.String]'Button1'
$Button1.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]8,[System.Int32]8))
$Button1.TabIndex = [System.Int32]0
$Button1.Text = [System.String]'Button1'
$Button1.UseVisualStyleBackColor = $true
#
#Button2
#
$Button2.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]177,[System.Int32]259))
$Button2.Name = [System.String]'Button2'
$Button2.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]255,[System.Int32]82))
$Button2.TabIndex = [System.Int32]2
$Button2.Text = [System.String]'Button2'
$Button2.UseVisualStyleBackColor = $true
#
#MenuStrip1
#
$MenuStrip1.Items.AddRange([System.Windows.Forms.ToolStripItem[]]@($ToolStripMenuItem1,$ToolStripMenuItem2,$ToolStripMenuItem3))
$MenuStrip1.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]0,[System.Int32]0))
$MenuStrip1.Name = [System.String]'MenuStrip1'
$MenuStrip1.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]661,[System.Int32]24))
$MenuStrip1.TabIndex = [System.Int32]3
$MenuStrip1.Text = [System.String]'MenuStrip1'
$MenuStrip1.add_ItemClicked($MenuStrip1_ItemClicked)
#
#ToolStripMenuItem1
#
$ToolStripMenuItem1.DropDownItems.AddRange([System.Windows.Forms.ToolStripItem[]]@($AsdfToolStripMenuItem,$SdfToolStripMenuItem))
$ToolStripMenuItem1.Name = [System.String]'ToolStripMenuItem1'
$ToolStripMenuItem1.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]126,[System.Int32]20))
$ToolStripMenuItem1.Text = [System.String]'ToolStripMenuItem1'
#
#ToolStripMenuItem2
#
$ToolStripMenuItem2.Name = [System.String]'ToolStripMenuItem2'
$ToolStripMenuItem2.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]126,[System.Int32]20))
$ToolStripMenuItem2.Text = [System.String]'ToolStripMenuItem2'
#
#ToolStripMenuItem3
#
$ToolStripMenuItem3.Name = [System.String]'ToolStripMenuItem3'
$ToolStripMenuItem3.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]126,[System.Int32]20))
$ToolStripMenuItem3.Text = [System.String]'ToolStripMenuItem3'
#
#AsdfToolStripMenuItem
#
$AsdfToolStripMenuItem.DropDownItems.AddRange([System.Windows.Forms.ToolStripItem[]]@($AsdfToolStripMenuItem1,$AfsToolStripMenuItem))
$AsdfToolStripMenuItem.Name = [System.String]'AsdfToolStripMenuItem'
$AsdfToolStripMenuItem.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]152,[System.Int32]22))
$AsdfToolStripMenuItem.Text = [System.String]'asdf'
#
#AsdfToolStripMenuItem1
#
$AsdfToolStripMenuItem1.Name = [System.String]'AsdfToolStripMenuItem1'
$AsdfToolStripMenuItem1.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]152,[System.Int32]22))
$AsdfToolStripMenuItem1.Text = [System.String]'asdf'
#
#AfsToolStripMenuItem
#
$AfsToolStripMenuItem.Name = [System.String]'AfsToolStripMenuItem'
$AfsToolStripMenuItem.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]152,[System.Int32]22))
$AfsToolStripMenuItem.Text = [System.String]'afs'
#
#SdfToolStripMenuItem
#
$SdfToolStripMenuItem.Name = [System.String]'SdfToolStripMenuItem'
$SdfToolStripMenuItem.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]152,[System.Int32]22))
$SdfToolStripMenuItem.Text = [System.String]'sdf'
#
#test
#
$test.ClientSize = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]661,[System.Int32]425))
$test.Controls.Add($Button2)
$test.Controls.Add($Button1)
$test.Controls.Add($MenuStrip1)
$test.MainMenuStrip = $MenuStrip1
$test.Name = [System.String]'test'
$test.Text = [System.String]'test'
$test.add_Load($Form1_Load)
$MenuStrip1.ResumeLayout($false)
$MenuStrip1.PerformLayout()
$test.ResumeLayout($false)
$test.PerformLayout()
Add-Member -InputObject $test -Name Button1 -Value $Button1 -MemberType NoteProperty
Add-Member -InputObject $test -Name Button2 -Value $Button2 -MemberType NoteProperty
Add-Member -InputObject $test -Name MenuStrip1 -Value $MenuStrip1 -MemberType NoteProperty
Add-Member -InputObject $test -Name ToolStripMenuItem1 -Value $ToolStripMenuItem1 -MemberType NoteProperty
Add-Member -InputObject $test -Name AsdfToolStripMenuItem -Value $AsdfToolStripMenuItem -MemberType NoteProperty
Add-Member -InputObject $test -Name AsdfToolStripMenuItem1 -Value $AsdfToolStripMenuItem1 -MemberType NoteProperty
Add-Member -InputObject $test -Name AfsToolStripMenuItem -Value $AfsToolStripMenuItem -MemberType NoteProperty
Add-Member -InputObject $test -Name SdfToolStripMenuItem -Value $SdfToolStripMenuItem -MemberType NoteProperty
Add-Member -InputObject $test -Name ToolStripMenuItem2 -Value $ToolStripMenuItem2 -MemberType NoteProperty
Add-Member -InputObject $test -Name ToolStripMenuItem3 -Value $ToolStripMenuItem3 -MemberType NoteProperty
}
. InitializeComponent
