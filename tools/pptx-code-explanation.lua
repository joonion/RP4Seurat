-- Split mixed code/explanation slides into two PowerPoint placeholders.
-- The first placeholder contains code and is positioned above the second
-- explanation placeholder by the custom reference PPTX.

local function is_slide_header(block)
  return block.t == "Header" and block.level == 2
end

local function split_slide_content(blocks)
  local code_blocks = pandoc.Blocks({})
  local explanation_blocks = pandoc.Blocks({})

  for _, block in ipairs(blocks) do
    if block.t == "CodeBlock" then
      code_blocks:insert(block)
    else
      explanation_blocks:insert(block)
    end
  end

  if #code_blocks == 0 or #explanation_blocks == 0 then
    return blocks
  end

  local code_column = pandoc.Div(
    code_blocks,
    pandoc.Attr("", { "column", "code-panel" }, { width = "1.0" })
  )

  local explanation_column = pandoc.Div(
    explanation_blocks,
    pandoc.Attr("", { "column", "explanation" }, { width = "1.0" })
  )

  return pandoc.Blocks({
    pandoc.Div(
      { code_column, explanation_column },
      pandoc.Attr("", { "columns", "pptx-code-explanation" })
    )
  })
end

function Pandoc(document)
  if FORMAT ~= "pptx" then
    return nil
  end

  local output = pandoc.Blocks({})
  local blocks = document.blocks
  local index = 1

  while index <= #blocks do
    local block = blocks[index]

    if not is_slide_header(block) then
      output:insert(block)
      index = index + 1
    else
      output:insert(block)
      index = index + 1

      local slide_content = pandoc.Blocks({})
      while index <= #blocks and not is_slide_header(blocks[index]) do
        slide_content:insert(blocks[index])
        index = index + 1
      end

      local transformed = split_slide_content(slide_content)
      for _, transformed_block in ipairs(transformed) do
        output:insert(transformed_block)
      end
    end
  end

  document.blocks = output
  return document
end
