param(
  [string]$InputDirectory = "_site/slides"
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

if ([System.IO.Path]::IsPathRooted($InputDirectory)) {
  $inputFullPath = [System.IO.Path]::GetFullPath($InputDirectory)
} else {
  $inputFullPath = [System.IO.Path]::GetFullPath(
    (Join-Path (Get-Location) $InputDirectory)
  )
}

$files = Get-ChildItem -LiteralPath $inputFullPath -Filter "*.pptx" |
  Sort-Object Name

if ($files.Count -eq 0) {
  throw "No PPTX files found in $inputFullPath"
}

$totalReplacements = 0

foreach ($file in $files) {
  $archive = [System.IO.Compression.ZipFile]::Open(
    $file.FullName,
    [System.IO.Compression.ZipArchiveMode]::Update
  )

  try {
    $targets = @($archive.Entries | Where-Object {
      $_.FullName -like "ppt/slides/slide*.xml"
    })

    $fileReplacements = 0

    foreach ($entry in $targets) {
      $entryName = $entry.FullName
      $reader = New-Object System.IO.StreamReader(
        $entry.Open(),
        [System.Text.Encoding]::UTF8,
        $true
      )
      $content = $reader.ReadToEnd()
      $reader.Dispose()

      $count = ([regex]::Matches($content, 'typeface="Courier"')).Count
      if ($count -eq 0) {
        continue
      }

      $content = $content.Replace(
        'typeface="Courier"',
        'typeface="Consolas"'
      )

      $entry.Delete()
      $newEntry = $archive.CreateEntry(
        $entryName,
        [System.IO.Compression.CompressionLevel]::Optimal
      )
      $writer = New-Object System.IO.StreamWriter(
        $newEntry.Open(),
        (New-Object System.Text.UTF8Encoding($false))
      )
      $writer.Write($content)
      $writer.Dispose()

      $fileReplacements += $count
    }

    $totalReplacements += $fileReplacements
    Write-Output "$($file.Name): replaced $fileReplacements code font runs"
  }
  finally {
    $archive.Dispose()
  }
}

Write-Output "Applied Consolas to $totalReplacements code font runs across $($files.Count) PPTX files."
