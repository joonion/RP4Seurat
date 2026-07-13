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

$files = @(
  Get-ChildItem -LiteralPath $inputFullPath -Filter "*.pptx" |
    Where-Object { $_.BaseName -match '^\d{2}_' } |
    Sort-Object Name
)

if ($files.Count -eq 0) {
  Write-Output "No lesson PPTX files found in $inputFullPath"
  exit 0
}

$presentationNamespace =
  "http://schemas.openxmlformats.org/presentationml/2006/main"
$drawingNamespace =
  "http://schemas.openxmlformats.org/drawingml/2006/main"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$updated = 0

function Set-ShapeBounds {
  param(
    [System.Xml.XmlElement]$Shape,
    [System.Xml.XmlNamespaceManager]$Namespaces,
    [string]$X,
    [string]$Y,
    [string]$Width,
    [string]$Height
  )

  $shapeProperties = $Shape.SelectSingleNode("p:spPr", $Namespaces)
  $transform = $shapeProperties.SelectSingleNode("a:xfrm", $Namespaces)

  if ($transform -eq $null) {
    $transform = $Shape.OwnerDocument.CreateElement(
      "a",
      "xfrm",
      $drawingNamespace
    )
    $shapeProperties.PrependChild($transform) | Out-Null
  }

  $offset = $transform.SelectSingleNode("a:off", $Namespaces)
  if ($offset -eq $null) {
    $offset = $Shape.OwnerDocument.CreateElement(
      "a",
      "off",
      $drawingNamespace
    )
    $transform.AppendChild($offset) | Out-Null
  }

  $extent = $transform.SelectSingleNode("a:ext", $Namespaces)
  if ($extent -eq $null) {
    $extent = $Shape.OwnerDocument.CreateElement(
      "a",
      "ext",
      $drawingNamespace
    )
    $transform.AppendChild($extent) | Out-Null
  }

  $offset.SetAttribute("x", $X)
  $offset.SetAttribute("y", $Y)
  $extent.SetAttribute("cx", $Width)
  $extent.SetAttribute("cy", $Height)
}

foreach ($file in $files) {
  $archive = [System.IO.Compression.ZipFile]::Open(
    $file.FullName,
    [System.IO.Compression.ZipArchiveMode]::Update
  )

  try {
    $entry = $archive.GetEntry("ppt/slides/slide1.xml")
    if ($entry -eq $null) {
      throw "slide1.xml was not found in $($file.Name)"
    }

    $entryName = $entry.FullName
    $reader = New-Object System.IO.StreamReader(
      $entry.Open(),
      [System.Text.Encoding]::UTF8,
      $true
    )
    [xml]$document = $reader.ReadToEnd()
    $reader.Dispose()

    $namespaces = New-Object System.Xml.XmlNamespaceManager(
      $document.NameTable
    )
    $namespaces.AddNamespace("p", $presentationNamespace)
    $namespaces.AddNamespace("a", $drawingNamespace)

    $lessonNumber = [int]$file.BaseName.Substring(0, 2)
    $lessonLabel = "${lessonNumber}회차"

    $titleShape = $document.SelectSingleNode(
      "//p:sp[p:nvSpPr/p:nvPr/p:ph[@type='ctrTitle' or @type='title']]",
      $namespaces
    )

    if ($titleShape -eq $null) {
      throw "Title placeholder was not found in $($file.Name)"
    }

    $titleTextNodes = $titleShape.SelectNodes(".//a:t", $namespaces)
    foreach ($textNode in $titleTextNodes) {
      $textNode.InnerText = $textNode.InnerText -replace (
        '^\s*\d+\s*회차\s*:\s*'
      ), ''
    }

    # 120, 150, 720, 112 points expressed in English Metric Units.
    Set-ShapeBounds $titleShape $namespaces `
      "1524000" "1905000" "9144000" "1422400"

    $subtitleShape = $document.SelectSingleNode(
      "//p:sp[p:nvSpPr/p:nvPr/p:ph[@type='subTitle']]",
      $namespaces
    )

    if ($subtitleShape -ne $null) {
      $subtitleRuns = @($subtitleShape.SelectNodes(".//a:r", $namespaces))
      foreach ($run in $subtitleRuns) {
        if ($run.InnerText.Trim() -match '^\d+\s*회차$') {
          $run.ParentNode.RemoveChild($run) | Out-Null
        }
      }

      # Pandoc inserts line breaks before the author on the title slide.
      $breaks = @($subtitleShape.SelectNodes(".//a:br", $namespaces))
      foreach ($break in $breaks) {
        $break.ParentNode.RemoveChild($break) | Out-Null
      }
    }

    $existingLabels = @($document.SelectNodes(
      "//p:sp[p:nvSpPr/p:cNvPr[@name='Lesson Label']]",
      $namespaces
    ))
    foreach ($existingLabel in $existingLabels) {
      $existingLabel.ParentNode.RemoveChild($existingLabel) | Out-Null
    }

    $maximumShapeId = 1
    foreach ($idNode in $document.SelectNodes("//p:cNvPr/@id", $namespaces)) {
      $shapeId = 0
      if ([int]::TryParse($idNode.Value, [ref]$shapeId)) {
        $maximumShapeId = [Math]::Max($maximumShapeId, $shapeId)
      }
    }
    $labelShapeId = $maximumShapeId + 1

    $escapedLabel = [System.Security.SecurityElement]::Escape($lessonLabel)
    $labelXml = @"
<root xmlns:p="$presentationNamespace" xmlns:a="$drawingNamespace">
  <p:sp>
    <p:nvSpPr>
      <p:cNvPr id="$labelShapeId" name="Lesson Label" />
      <p:cNvSpPr txBox="1" />
      <p:nvPr />
    </p:nvSpPr>
    <p:spPr>
      <a:xfrm>
        <a:off x="1524000" y="863600" />
        <a:ext cx="9144000" cy="787400" />
      </a:xfrm>
      <a:prstGeom prst="rect"><a:avLst /></a:prstGeom>
      <a:noFill />
      <a:ln><a:noFill /></a:ln>
    </p:spPr>
    <p:txBody>
      <a:bodyPr lIns="0" tIns="0" rIns="0" bIns="0">
        <a:spAutoFit />
      </a:bodyPr>
      <a:lstStyle />
      <a:p>
        <a:pPr algn="l" />
        <a:r>
          <a:rPr lang="ko-KR" sz="3600" b="1">
            <a:solidFill><a:srgbClr val="2563EB" /></a:solidFill>
            <a:latin typeface="Pretendard" />
            <a:ea typeface="Pretendard" />
            <a:cs typeface="Pretendard" />
          </a:rPr>
          <a:t>$escapedLabel</a:t>
        </a:r>
        <a:endParaRPr lang="ko-KR" sz="3600" />
      </a:p>
    </p:txBody>
  </p:sp>
</root>
"@

    [xml]$labelDocument = $labelXml
    $labelNode = $document.ImportNode(
      $labelDocument.DocumentElement.FirstChild,
      $true
    )
    $shapeTree = $document.SelectSingleNode("//p:spTree", $namespaces)
    $shapeTree.AppendChild($labelNode) | Out-Null

    $settings = New-Object System.Xml.XmlWriterSettings
    $settings.Encoding = $utf8NoBom
    $settings.Indent = $false
    $settings.OmitXmlDeclaration = $false

    $entry.Delete()
    $newEntry = $archive.CreateEntry(
      $entryName,
      [System.IO.Compression.CompressionLevel]::Optimal
    )
    $entryStream = $newEntry.Open()
    $xmlWriter = [System.Xml.XmlWriter]::Create($entryStream, $settings)
    $document.Save($xmlWriter)
    $xmlWriter.Dispose()
    $entryStream.Dispose()

    $updated++
  }
  finally {
    $archive.Dispose()
  }
}

Write-Output "Applied OOXML lesson labels to $updated PPTX files without launching PowerPoint."


