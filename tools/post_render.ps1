$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$renderedSlides = Join-Path $projectRoot "_site\slides"
$distributionDirectory = Join-Path $projectRoot "powerpoint"
$fontScript = Join-Path $PSScriptRoot "apply_pptx_code_font.ps1"
$lessonLabelScript = Join-Path $PSScriptRoot "apply_pptx_lesson_labels.ps1"

$pptxFiles = @(
  Get-ChildItem -LiteralPath $renderedSlides -Filter "*.pptx" -ErrorAction SilentlyContinue |
    Sort-Object Name
)

if ($pptxFiles.Count -eq 0) {
  Write-Output "No rendered PPTX files found; PowerPoint post-processing skipped."
  exit 0
}

& $fontScript -InputDirectory $renderedSlides
& $lessonLabelScript -InputDirectory $renderedSlides

[System.IO.Directory]::CreateDirectory($distributionDirectory) | Out-Null

foreach ($file in $pptxFiles) {
  $destination = Join-Path $distributionDirectory $file.Name
  $copied = $false

  for ($attempt = 1; $attempt -le 5; $attempt++) {
    try {
      Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
      $copied = $true
      break
    } catch [System.IO.IOException] {
      if ($attempt -lt 5) {
        Start-Sleep -Milliseconds 600
      }
    }
  }

  if (-not $copied) {
    $fallbackDirectory = Join-Path $distributionDirectory "_updated"
    [System.IO.Directory]::CreateDirectory($fallbackDirectory) | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $fallbackDirectory -Force
    Write-Warning "$($file.Name) was locked; wrote the current version to $fallbackDirectory"
  }
}

Write-Output "Copied $($pptxFiles.Count) finalized PPTX files to $distributionDirectory"
