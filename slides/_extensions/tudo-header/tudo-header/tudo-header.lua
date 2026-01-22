local function ensureHtmlDeps()
  quarto.doc.add_html_dependency({
    name = "tudo-header",
    version = "0.0.1",
    scripts = {
        { path = "resources/js/add_header.js", attribs = {defer = "true"}}
      },
    stylesheets = {"resources/css/add_header.css"}
  })
end

if quarto.doc.is_format('revealjs') then
  ensureHtmlDeps()
  function Pandoc(doc)
    local blocks = doc.blocks
    local str = pandoc.utils.stringify
    local meta = doc.meta

    local header_logo = meta['header-logo'] and str(meta['header-logo']) or ""
    local header_logo2 = meta['header-logo2'] and str(meta['header-logo2']) or ""
	    
    local div = pandoc.Div(
      {
        pandoc.Div(pandoc.Image("", header_logo, ""), {class = "header-logo"}),
        pandoc.Div(pandoc.Image("", header_logo2, ""), {class = "header-logo header-logo-right"})		
      }, 
      {class = 'reveal-header'}
    )
    
    table.insert(blocks, div)
    return doc
  end
end