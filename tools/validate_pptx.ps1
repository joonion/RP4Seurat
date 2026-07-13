param(
  [string]$InputDirectory = "_site/slides"
)

$ErrorActionPreference = "Stop"

$inputFullPath = [System.IO.Path]::GetFullPath(
  (Join-Path (Get-Location) $InputDirectory)
)

$files = Get-ChildItem -LiteralPath $inputFullPath -Filter "*.pptx" |
  Sort-Object Name

if ($files.Count -eq 0) {
  throw "No PPTX files found in $inputFullPath"
}

$powerPoint = $null
$results = @()

try {
  $powerPoint = New-Object -ComObject PowerPoint.Application
  $powerPoint.Visible = -1

  foreach ($file in $files) {
    $presentation = $null

    try {
      # ReadOnly, Untitled, WithWindow
      $presentation = $powerPoint.Presentations.Open(
        $file.FullName,
        0,
        0,
        -1
      )

      $waitCount = 0
      while ($presentation.Slides.Count -eq 0 -and $waitCount -lt 20) {
        Start-Sleep -Milliseconds 250
        $waitCount++
      }

      if ($presentation.Slides.Count -eq 0) {
        throw "PowerPoint loaded zero slides from $($file.Name)"
      }

      $slideWidth = $presentation.PageSetup.SlideWidth
      $slideHeight = $presentation.PageSetup.SlideHeight
      $outOfBounds = @()
      $textOverflow = @()
      $fonts = New-Object System.Collections.Generic.HashSet[string]

      foreach ($slide in $presentation.Slides) {
        foreach ($shape in $slide.Shapes) {
          $right = $shape.Left + $shape.Width
          $bottom = $shape.Top + $shape.Height

          if (
            $shape.Left -lt -1 -or
            $shape.Top -lt -1 -or
            $right -gt ($slideWidth + 1) -or
            $bottom -gt ($slideHeight + 1)
          ) {
            $outOfBounds += "slide $($slide.SlideIndex): $($shape.Name)"
          }

          if (-not $shape.HasTextFrame -or -not $shape.TextFrame.HasText) {
            continue
          }

          $textRange = $shape.TextFrame.TextRange
          if (-not [string]::IsNullOrWhiteSpace($textRange.Text)) {
            if (-not [string]::IsNullOrWhiteSpace($textRange.Font.Name)) {
              $fonts.Add($textRange.Font.Name) | Out-Null
            }

            try {
              $availableHeight =
                $shape.Height -
                $shape.TextFrame2.MarginTop -
                $shape.TextFrame2.MarginBottom

              $boundHeight = $shape.TextFrame2.TextRange.BoundHeight

              if (
                $shape.TextFrame2.AutoSize -eq 0 -and
                $boundHeight -gt ($availableHeight + 2)
              ) {
                $textOverflow += "slide $($slide.SlideIndex): $($shape.Name)"
              }
            } catch {
              # Some non-standard placeholders do not expose BoundHeight.
            }
          }
        }
      }

      $results += [PSCustomObject]@{
        File = $file.Name
        Slides = $presentation.Slides.Count
        Ratio = [Math]::Round($slideWidth / $slideHeight, 3)
        OutOfBounds = $outOfBounds.Count
        TextOverflow = $textOverflow.Count
        Fonts = ($fonts | Sort-Object) -join ", "
        OutOfBoundsDetails = $outOfBounds -join "; "
        TextOverflowDetails = $textOverflow -join "; "
      }
    }
    finally {
      if ($presentation -ne $null) {
        $presentation.Close()
        [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject(
          $presentation
        ) | Out-Null
      }
    }
  }
}
finally {
  if ($powerPoint -ne $null) {
    $powerPoint.Quit()
    [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject(
      $powerPoint
    ) | Out-Null
  }

  [GC]::Collect()
  [GC]::WaitForPendingFinalizers()
}

$results | Format-Table File, Slides, Ratio, OutOfBounds, TextOverflow, Fonts -AutoSize

$failures = @($results | Where-Object {
  $_.Slides -eq 0 -or
  $_.Ratio -ne 1.778 -or
  $_.OutOfBounds -gt 0 -or
  $_.TextOverflow -gt 0
})

if ($failures.Count -gt 0) {
  $failures | Format-List
  throw "PPTX validation found layout issues."
}

Write-Output "Validated $($results.Count) PPTX files without detected layout overflow."
