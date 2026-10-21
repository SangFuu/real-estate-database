param([Parameter(Mandatory=$true)][string]$HsqldbJar, [string]$Java='java')
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$jar=(Resolve-Path -LiteralPath $HsqldbJar).Path
$temp=Join-Path ([System.IO.Path]::GetTempPath()) ('bdd-check-'+[guid]::NewGuid())
New-Item -ItemType Directory -Path $temp | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
try {
    $archive=[System.IO.Compression.ZipFile]::OpenRead((Join-Path $repo 'agence-immobiliere.odb'))
    try {
        $xmlCount=0
        foreach($entry in $archive.Entries) {
            if($entry.FullName -match '^database/(data|properties|script|backup)$') {
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry,(Join-Path $temp ('base.'+[System.IO.Path]::GetFileName($entry.FullName))),$false)
            }
            if($entry.FullName.EndsWith('.xml')) {
                $reader=[System.IO.StreamReader]::new($entry.Open())
                try {$xml=[System.Xml.XmlDocument]::new();$xml.XmlResolver=$null;$xml.LoadXml($reader.ReadToEnd());$xmlCount++} finally {$reader.Dispose()}
            }
        }
        Write-Output "$xmlCount documents XML lisibles."
    } finally {$archive.Dispose()}
    Add-Content -LiteralPath (Join-Path $temp 'base.properties') -Value "`nreadonly=true" -Encoding ascii
    & $Java --class-path $jar (Join-Path $PSScriptRoot 'CheckDatabase.java') (Join-Path $temp 'base') (Join-Path $repo 'schema.sql') (Join-Path $repo 'requetes.sql')
    if($LASTEXITCODE -ne 0){throw 'Verification de la base echouee.'}
} finally {
    Get-ChildItem -LiteralPath $temp -File | ForEach-Object {Remove-Item -LiteralPath $_.FullName}
    Remove-Item -LiteralPath $temp
}
