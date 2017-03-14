require "warmups"

describe HTMLParser do
  let(:parser){ HTMLParser.new }
  let(:html){ "<p id='paragraph'><span>in span</span></p>" }
  let(:pop_parser){ parser.parse_script(html) }

  describe "#parse_tag" do
    let(:html){ "<p class='foo bar' id='baz' name='fozzie'><p>" }

    it "returns a match" do
      expect(parser.parse_tag(html, nil).type).to eq(:p)
    end

    it "matches the classes of the tag" do
      tag = parser.parse_tag(html, nil)
      expect(tag.attrs[:class]).to eq(["foo", "bar"])
    end

    it "matches the id of the tag" do
      tag = parser.parse_tag(html, nil)
      expect(tag.attrs[:id]).to eq("baz")
    end

    it "matches the name of the tag" do
      tag = parser.parse_tag(html, nil)
      expect(tag.attrs[:name]).to eq("fozzie")
    end

    it "matches text" do
      tag = parser.parse_tag("hello world", nil)
      expect(tag).to eq(Node.new(0, :text, nil, {}, ["hello world"]))
    end
  end

  describe "#parse_script" do
    let(:text){ text = Node.new(0, :text, nil, {}, ["hello world"])}

    it "parses a simple empty element" do
      ds = parser.parse_script("<p></p>")
      expect(parser.root).to eq(Node.new(0, :p, nil, {}, [""]))
    end

    it "parses a simple element with text" do
      ds = parser.parse_script("<p>hello world</p>")
      text.id, text.parent = 1, 0
      expect(parser.root).to eq(Node.new(0, :p, nil, {}, [text]))
    end

    it "parses an element with attributes" do
      ds = parser.parse_script("<p id='paragraph'>hello world</p>")
      text.id, text.parent = 1, 0
      expected = Node.new(0, :p, nil, {id: "paragraph"}, [text])
      expect(parser.root).to eq(expected)
    end

    it "parses a nested element" do
      ds = parser.parse_script("<p><span></span></p>")
      child = Node.new(1, :span, 0, {}, [""])
      expected = Node.new(0, :p, nil, {}, [child])
      expect(parser.root).to eq(expected)
    end

    it "parses a nested element with text" do
      ds = parser.parse_script("<p><span>hello world</span></p>")
      text.id, text.parent = 2, 1
      child = Node.new(1, :span, 0, {}, [text])
      expected = Node.new(0, :p, nil, {}, [child])
      expect(parser.root).to eq(expected)
    end

    it "works with spaced elts" do
      parser.parse_script("<p>
          Before text <span>mid text (not included in text
          attribute of the paragraph tag)</span> after text.
      </p>")
      expect(parser.root.id).to eq(0)

    end
  end

  describe "#to_html" do
    it "returns the html_string" do
      html = "<p><span>in span</span></p>"
      parser.parse_script(html)
      expect(parser.to_html).to eq(html)
    end
  end

  describe "#search_by" do
    it "returns the node with the equivalent attribute" do
      expected = pop_parser.root
      expect(pop_parser.search_by(:id, "paragraph")).to eq(expected)
    end
  end

  describe "#search_children" do
    it "searchs only the children of the given node" do
      result = pop_parser.search_children(pop_parser.root, :id, "paragraph")
      expect(result).to eq(pop_parser.root)
    end
  end

  describe "#search_ancestors" do
    it "searchs the ancestors of the given node" do
      result = pop_parser.search_ancestors(pop_parser.root, :id, "paragraph")
      expect(result).to eq(nil)
    end
  end

end
