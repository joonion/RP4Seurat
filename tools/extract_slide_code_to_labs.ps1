param(
  [string]$SlidesDirectory = "slides",
  [string]$LabsDirectory = "labs"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot

if ([System.IO.Path]::IsPathRooted($SlidesDirectory)) {
  $slidesFullPath = $SlidesDirectory
} else {
  $slidesFullPath = Join-Path $projectRoot $SlidesDirectory
}

if ([System.IO.Path]::IsPathRooted($LabsDirectory)) {
  $labsFullPath = $LabsDirectory
} else {
  $labsFullPath = Join-Path $projectRoot $LabsDirectory
}

[System.IO.Directory]::CreateDirectory($labsFullPath) | Out-Null

$slideFiles = Get-ChildItem -LiteralPath $slidesFullPath -Filter "*.qmd" |
  Where-Object { $_.BaseName -match '^\d{2}_' } |
  Sort-Object Name

if ($slideFiles.Count -eq 0) {
  throw "No numbered QMD slide files found in $slidesFullPath"
}

$results = @()
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

foreach ($slideFile in $slideFiles) {
  $lines = Get-Content -LiteralPath $slideFile.FullName -Encoding utf8
  $output = New-Object System.Collections.Generic.List[string]
  $currentHeading = "슬라이드 코드"
  $blockNumber = 0
  $inCodeBlock = $false
  $codeLines = New-Object System.Collections.Generic.List[string]

  $output.Add("# $($slideFile.BaseName).R")
  $output.Add("")

  foreach ($line in $lines) {
    if (-not $inCodeBlock -and $line -match '^##\s+(.+?)(?:\s+\{.*\})?\s*$') {
      $currentHeading = $Matches[1].Trim()
      continue
    }

    if (-not $inCodeBlock -and $line.Trim() -eq '```r') {
      $inCodeBlock = $true
      $codeLines.Clear()
      continue
    }

    if ($inCodeBlock -and $line.Trim() -eq '```') {
      $inCodeBlock = $false
      $blockNumber++
      $safeHeading = $currentHeading -replace '[#{}]', ''
      $output.Add("# ---- $safeHeading · 코드 $blockNumber ----")
      foreach ($codeLine in $codeLines) {
        $output.Add($codeLine)
      }
      $output.Add("")
      continue
    }

    if ($inCodeBlock) {
      $codeLines.Add($line)
    }
  }

  if ($inCodeBlock) {
    throw "Unclosed R code block in $($slideFile.Name)"
  }

  $outputPath = Join-Path $labsFullPath ($slideFile.BaseName + ".R")
  [System.IO.File]::WriteAllLines($outputPath, $output, $utf8NoBom)

  $results += [PSCustomObject]@{
    File = [System.IO.Path]::GetFileName($outputPath)
    CodeBlocks = $blockNumber
    Lines = $output.Count
  }
}

$results | Format-Table File, CodeBlocks, Lines -AutoSize
Write-Output "Created $($results.Count) lab files in $labsFullPath"


