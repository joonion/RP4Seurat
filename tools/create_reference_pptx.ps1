param(
  [string]$OutputPath = "assets/seurat-r-reference.pptx"
)

$ErrorActionPreference = "Stop"

function Convert-ToOfficeRgb {
  param(
    [int]$Red,
    [int]$Green,
    [int]$Blue
  )

  return $Red + (256 * $Green) + (65536 * $Blue)
}

function Set-TextStyle {
  param(
    $TextRange,
    [string]$FontName,
    [float]$FontSize,
    [int]$Color,
    [bool]$Bold = $false
  )

  $TextRange.Font.Name = $FontName
  $TextRange.Font.NameFarEast = $FontName
  $TextRange.Font.Size = $FontSize
  $TextRange.Font.Color.RGB = $Color
  $TextRange.Font.Bold = if ($Bold) { -1 } else { 0 }
}

function Set-VerticalCodeExplanationLayout {
  param(
    $Layout,
    [int]$TextColor,
    [int]$CodeBackground,
    [int]$BorderColor,
    [int]$PrimaryColor
  )

  $contentPlaceholders = @()

  foreach ($shape in $Layout.Shapes) {
    if ($shape.Type -ne 14 -or -not $shape.HasTextFrame) {
      continue
    }

    $placeholderType = $shape.PlaceholderFormat.Type

    if ($placeholderType -in @(1, 3, 5)) {
      $shape.Left = 40
      $shape.Top = 24
      $shape.Width = 880
      $shape.Height = 64
      Set-TextStyle $shape.TextFrame.TextRange "Pretendard" 28 $TextColor $true
    } elseif ($placeholderType -notin @(4, 13, 14, 15, 16)) {
      $contentPlaceholders += $shape
    }
  }

  if ($contentPlaceholders.Count -lt 2) {
    throw "Layout '$($Layout.Name)' does not contain two content placeholders."
  }

  # Pandoc fills the first column with code and the second with explanation.
  $codePlaceholder = $contentPlaceholders[0]
  $codePlaceholder.Left = 48
  $codePlaceholder.Top = 106
  $codePlaceholder.Width = 864
  $codePlaceholder.Height = 202
  $codePlaceholder.TextFrame.MarginLeft = 10
  $codePlaceholder.TextFrame.MarginRight = 10
  $codePlaceholder.TextFrame.MarginTop = 8
  $codePlaceholder.TextFrame.MarginBottom = 8
  Set-TextStyle $codePlaceholder.TextFrame.TextRange "Consolas" 16 $TextColor $false

  $explanationPlaceholder = $contentPlaceholders[1]
  $explanationPlaceholder.Left = 48
  $explanationPlaceholder.Top = 330
  $explanationPlaceholder.Width = 864
  $explanationPlaceholder.Height = 168
  $explanationPlaceholder.TextFrame.MarginLeft = 4
  $explanationPlaceholder.TextFrame.MarginRight = 4
  $explanationPlaceholder.TextFrame.MarginTop = 4
  $explanationPlaceholder.TextFrame.MarginBottom = 4
  Set-TextStyle $explanationPlaceholder.TextFrame.TextRange "Pretendard" 16 $TextColor $false

  # Neutral panel behind the upper code placeholder.
  $codePanel = $Layout.Shapes.AddShape(1, 36, 96, 888, 224)
  $codePanel.Fill.Solid()
  $codePanel.Fill.ForeColor.RGB = $CodeBackground
  $codePanel.Line.ForeColor.RGB = $BorderColor
  $codePanel.Line.Weight = 1
  $accent = $Layout.Shapes.AddShape(1, 36, 96, 6, 224)
  $accent.Fill.Solid()
  $accent.Fill.ForeColor.RGB = $PrimaryColor
  $accent.Line.Visible = 0
  $codePanel.ZOrder(1)
  $accent.ZOrder(1)
}

$background = Convert-ToOfficeRgb 248 250 252
$text = Convert-ToOfficeRgb 23 32 51
$primary = Convert-ToOfficeRgb 37 99 235
$secondary = Convert-ToOfficeRgb 15 118 110
$warning = Convert-ToOfficeRgb 180 83 9
$codeBackground = Convert-ToOfficeRgb 241 245 249
$border = Convert-ToOfficeRgb 203 213 225
$white = Convert-ToOfficeRgb 255 255 255
$muted = Convert-ToOfficeRgb 82 96 119

$outputFullPath = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputPath))
$outputDirectory = Split-Path -Parent $outputFullPath
[System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null

$powerPoint = $null
$presentation = $null
$generationError = $null

try {
  $powerPoint = New-Object -ComObject PowerPoint.Application
  $powerPoint.Visible = -1
  $presentation = $powerPoint.Presentations.Add()

  # 16:9 widescreen at 1600 x 900 logical proportion.
  $presentation.PageSetup.SlideWidth = 960
  $presentation.PageSetup.SlideHeight = 540

  $master = $presentation.SlideMaster
  $master.Background.Fill.Solid()
  $master.Background.Fill.ForeColor.RGB = $background

  # Master typography. PowerPoint applies these levels to generated content.
  $titleStyle = $master.TextStyles.Item(1)
  Set-TextStyle $titleStyle.Levels.Item(1) "Pretendard" 30 $text $true

  $bodyStyle = $master.TextStyles.Item(2)
  $bodySizes = @(20, 18, 16, 15, 14)
  for ($levelIndex = 1; $levelIndex -le 5; $levelIndex++) {
    $level = $bodyStyle.Levels.Item($levelIndex)
    Set-TextStyle $level "Pretendard" $bodySizes[$levelIndex - 1] $text $false
    $level.ParagraphFormat.SpaceAfter = 7
    $level.ParagraphFormat.SpaceWithin = 1.08
  }

  $defaultStyle = $master.TextStyles.Item(3)
  for ($levelIndex = 1; $levelIndex -le 5; $levelIndex++) {
    Set-TextStyle $defaultStyle.Levels.Item($levelIndex) "Pretendard" 18 $text $false
  }

  # Normalize built-in layout names so Pandoc can resolve them on Korean Office.
  $layoutNames = @(
    "Title Slide",
    "Title and Content",
    "Section Header",
    "Two Content",
    "Comparison",
    "Title Only",
    "Blank",
    "Content with Caption",
    "Picture with Caption"
  )

  $layoutCount = [Math]::Min($master.CustomLayouts.Count, $layoutNames.Count)
  for ($layoutIndex = 1; $layoutIndex -le $layoutCount; $layoutIndex++) {
    $master.CustomLayouts.Item($layoutIndex).Name = $layoutNames[$layoutIndex - 1]
  }

  # Additional education-specific layouts remain available for manual authoring.
  $codeLayout = $master.CustomLayouts.Item(2).Duplicate()
  $codeLayout.Name = "Code / Demonstration"

  $exerciseLayout = $master.CustomLayouts.Item(2).Duplicate()
  $exerciseLayout.Name = "Exercise"

  foreach ($layout in $master.CustomLayouts) {
    $layout.FollowMasterBackground = 0
    $layout.Background.Fill.Solid()
    $layout.Background.Fill.ForeColor.RGB = $background

    foreach ($shape in $layout.Shapes) {
      if ($shape.Type -ne 14 -or -not $shape.HasTextFrame) {
        continue
      }

      $placeholderType = $shape.PlaceholderFormat.Type
      $range = $shape.TextFrame.TextRange

      if ($placeholderType -in @(1, 3, 5)) {
        Set-TextStyle $range "Pretendard" 30 $text $true
      } elseif ($placeholderType -eq 4) {
        Set-TextStyle $range "Pretendard" 17 $secondary $false
      } elseif ($placeholderType -in @(13, 14, 15, 16)) {
        Set-TextStyle $range "Pretendard" 9 $muted $false
      } else {
        Set-TextStyle $range "Pretendard" 20 $text $false
        $range.ParagraphFormat.SpaceAfter = 7
        $range.ParagraphFormat.SpaceWithin = 1.08
      }
    }

    # A thin top rule creates hierarchy without decorative effects.
    if ($layout.Name -notin @("Blank", "Section Header")) {
      $rule = $layout.Shapes.AddShape(1, 0, 0, 960, 6)
      $rule.Fill.Solid()
      $rule.Fill.ForeColor.RGB = if ($layout.Name -eq "Exercise") { $secondary } else { $primary }
      $rule.Line.Visible = 0
    }
  }

  # Pandoc selects these layouts for a two-column AST. Their placeholders are
  # intentionally positioned vertically: code above, explanation below.
  $twoContentLayout = $null
  $comparisonLayout = $null
  foreach ($layout in $master.CustomLayouts) {
    if ($layout.Name -eq "Two Content") {
      $twoContentLayout = $layout
    } elseif ($layout.Name -eq "Comparison") {
      $comparisonLayout = $layout
    }
  }

  if ($twoContentLayout -eq $null -or $comparisonLayout -eq $null) {
    throw "Required Two Content or Comparison layout was not found."
  }

  Set-VerticalCodeExplanationLayout $twoContentLayout $text $codeBackground $border $primary
  Set-VerticalCodeExplanationLayout $comparisonLayout $text $codeBackground $border $primary

  # Title slide: restrained accent and generous white space.
  $titleLayout = $master.CustomLayouts.Item(1)
  foreach ($shape in $titleLayout.Shapes) {
    if ($shape.Type -eq 14 -and $shape.HasTextFrame) {
      $placeholderType = $shape.PlaceholderFormat.Type
      if ($placeholderType -in @(1, 3)) {
        Set-TextStyle $shape.TextFrame.TextRange "Pretendard" 36 $text $true
      } elseif ($placeholderType -eq 4) {
        Set-TextStyle $shape.TextFrame.TextRange "Pretendard" 18 $secondary $false
      }
    }
  }

  # Section header: dark field for a clear chapter transition.
  $sectionLayout = $master.CustomLayouts.Item(3)
  $sectionLayout.Background.Fill.Solid()
  $sectionLayout.Background.Fill.ForeColor.RGB = $text
  $sectionRule = $sectionLayout.Shapes.AddShape(1, 0, 0, 12, 540)
  $sectionRule.Fill.Solid()
  $sectionRule.Fill.ForeColor.RGB = $primary
  $sectionRule.Line.Visible = 0
  foreach ($shape in $sectionLayout.Shapes) {
    if ($shape.Type -eq 14 -and $shape.HasTextFrame) {
      $placeholderType = $shape.PlaceholderFormat.Type
      if ($placeholderType -in @(1, 3)) {
        Set-TextStyle $shape.TextFrame.TextRange "Pretendard" 34 $white $true
      } elseif ($placeholderType -eq 4) {
        Set-TextStyle $shape.TextFrame.TextRange "Pretendard" 18 $border $false
      }
    }
  }

  # Code layout: neutral code panel and monospace body placeholder.
  $codePanel = $codeLayout.Shapes.AddShape(1, 36, 112, 888, 360)
  $codePanel.Fill.Solid()
  $codePanel.Fill.ForeColor.RGB = $codeBackground
  $codePanel.Line.ForeColor.RGB = $border
  foreach ($shape in $codeLayout.Shapes) {
    if ($shape.Type -eq 14 -and $shape.HasTextFrame) {
      $placeholderType = $shape.PlaceholderFormat.Type
      if ($placeholderType -notin @(1, 3, 4, 13, 14, 15, 16)) {
        Set-TextStyle $shape.TextFrame.TextRange "Consolas" 16 $text $false
      }
    }
  }

  # Exercise layout: teal rule and an instruction label.
  $exerciseLabel = $exerciseLayout.Shapes.AddTextbox(1, 40, 78, 180, 24)
  $exerciseLabel.TextFrame.TextRange.Text = "PRACTICE"
  Set-TextStyle $exerciseLabel.TextFrame.TextRange "Pretendard" 11 $secondary $true
  $exerciseLabel.Line.Visible = 0
  $exerciseLabel.Fill.Visible = 0

  # Footer and slide numbers use a quiet neutral tone.
  foreach ($shape in $master.Shapes) {
    if ($shape.Type -eq 14 -and $shape.HasTextFrame) {
      $placeholderType = $shape.PlaceholderFormat.Type
      if ($placeholderType -in @(13, 14, 15, 16)) {
      Set-TextStyle $shape.TextFrame.TextRange "Pretendard" 9 $muted $false
      }
    }
  }

  # Pandoc requires a valid slide list in presentation.xml. A seed slide
  # provides that structure; Pandoc replaces reference content when rendering.
  $seedSlide = $presentation.Slides.AddSlide(1, $titleLayout)
  foreach ($shape in $seedSlide.Shapes) {
    if ($shape.Type -eq 14 -and $shape.HasTextFrame) {
      $placeholderType = $shape.PlaceholderFormat.Type
      if ($placeholderType -in @(1, 3)) {
        $shape.TextFrame.TextRange.Text = "Seurat 분석을 위한 R 프로그래밍"
      } elseif ($placeholderType -eq 4) {
        $shape.TextFrame.TextRange.Text = "PowerPoint Reference Template"
      }
    }
  }

  # 24 = ppSaveAsOpenXMLPresentation.
  $presentation.SaveAs($outputFullPath, 24)
}
catch {
  $generationError = $_
  Write-Output "Reference PPTX generation failed: $($_.Exception.Message)"
  Write-Output $_.ScriptStackTrace
}
finally {
  if ($presentation -ne $null) {
    try {
      Start-Sleep -Milliseconds 800
      $presentation.Close()
    } catch {
      Write-Warning "PowerPoint presentation close was deferred: $($_.Exception.Message)"
    }

    try {
      [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($presentation) | Out-Null
    } catch {
      Write-Warning "Presentation COM release was deferred."
    }
  }

  if ($powerPoint -ne $null) {
    try {
      Start-Sleep -Milliseconds 800
      $powerPoint.Quit()
    } catch {
      Write-Warning "PowerPoint quit was deferred: $($_.Exception.Message)"
    }

    try {
      [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($powerPoint) | Out-Null
    } catch {
      Write-Warning "PowerPoint COM release was deferred."
    }
  }

  [GC]::Collect()
  [GC]::WaitForPendingFinalizers()
}

if ($generationError -ne $null) {
  throw $generationError
}

Write-Output "Created $outputFullPath"



