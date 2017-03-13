require "warmups"
require "node_renderer"

describe NodeRenderer do
  let(:html){ "<p>hello, <b>world!</b></p>" }
  let(:tree) do
    parser = HTMLParser.new
    parser.parser_script(html, nil)
    parser.root
  end
  let(:nr){ NodeRenderer.new(tree) }

  

end
