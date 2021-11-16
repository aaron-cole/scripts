function Get-PdfFieldNames
{
	[OutputType([string])]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidatePattern('\.pdf$')]
		[ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
		[string]$FilePath,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidatePattern('\.dll$')]
		[ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
		[string]$ITextLibraryPath = 'D:\Workdir\Powershell\itextsharp.dll'
	)
	begin
	{
		$ErrorActionPreference = 'Stop'
		## Load the iTextSharp DLL to do all the heavy-lifting 
		[System.Reflection.Assembly]::LoadFrom($ITextLibraryPath) | Out-Null
	}
	process
	{
		try
		{
			$reader = New-Object iTextSharp.text.pdf.PdfReader -ArgumentList $FilePath
			$reader.AcroFields.Fields.Key
		}
		catch
		{
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}
}