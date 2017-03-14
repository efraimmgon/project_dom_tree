Node = Struct.new("Node", :id, :type, :parent, :attrs, :body)

class HTMLParser
  attr_accessor :root, :length, :elts

  def initialize
    @root = nil
    @length = 0
    @elts = []
  end

  def parse_elt(html)
    html.match(/^<(\w+)/)[1].to_sym
  end

  def parse_body(html)
    html.match(/^<.*?>((.|\n)*)<.*?>$/)[1]
  end

  def parse_attrs(html)
    regex = /(?:(?<attr_name>\w+)\s*=\s*'(?<attr_val>[^']*)')/
    html.scan(regex).reduce({}) do |attrs, pair|
      return {} if pair.empty?
      name, val = pair
      if name == "class"
        attrs[:class] = val.split(" ").map{ |v| v.strip }
      else
        attrs[name.to_sym] = val
      end
      attrs
    end
  end

  def text?(html)
    html.match(/^([^<]+)/)
  end

  def parse_tag(html, parent)
    if elt = (!opening_tag?(html.strip) && text?(html))
      return Node.new(length, :text, parent ? parent.id : nil, {}, [elt.to_s])
    end
    type = parse_elt(html)
    attrs = parse_attrs(html)
    id = parent ? parent.id : nil
    Node.new(length, type, id, attrs, [])
  end

  def parse_script_(html, parent)
    if tag = (opening_tag?(html) or text?(html))
      node = parse_tag(html, parent)
      @elts.push(node)
      @length += 1
      if parent.nil?
        @root = node
        parse_script_(tag.post_match, node)
      else
        parent.body.push(node)
        parse_script_(tag.post_match, node)
      end
    elsif tag = closing_tag?(html)
      if tag[1].to_sym == parent.type
        parent.body.push("") if parent.body.empty?
      end
      parse_script_(tag.post_match, elts[parent.parent]) if parent.parent
    elsif html.empty?
      return parent.body.push("") if parent.body.empty?
      parent
    end
  end

  def opening_tag?(html)
    html.match(/^<[^\/\>]+>/)
  end

  def closing_tag?(html)
    html.match(/^<\/(.*?)>/)
  end

  def element?(ds)
    ds.is_a?(Array) && ds.first.is_a?(Symbol)
  end

  def to_html_(tr)
    acc = ""
    if tr.is_a?(Array)
      return "" if tr.empty?
      to_html_(tr.first) + to_html_(tr[1..-1])
    elsif tr.type == :text
      tr.body.first
    else
      acc += "<#{tr.type}"
      acc += tr.attrs.empty? ? "" : tr.attrs.map{ |k, v| " #{k}='#{v}'" }.join
      acc += ">"
      acc + to_html_(tr.body) + "</#{tr.type}>"
    end
  end

  def to_html
    to_html_(root)
  end

  def build_tree(path)
    html = File.readlines.reduce("") do |acc, line|
      acc += line
    end
    parse_script(html)
  end

  def parse_script(html)
    parse_script_(html, nil)
    self
  end

  # ------------------------------------------------------------------------
  # Searcher
  # ------------------------------------------------------------------------

  def search_by_(tr, attr_name, attr_value)
    return if tr.nil?
    elt, rest = tr.first, tr[1..-1]
    if elt.is_a?(Node)
      if elt.attrs[attr_name] == attr_value
        return elt
      end
    end
    search_by(rest+elt.body, attr_name, attr_value)
  end

  def search_by(attr_name, attr_value)
    search_by_([root], attr_name, attr_value)
  end

  def search_children(node, attr_name, attr_value)
    search_by_([node], attr_name, attr_value)
  end

  def search_ancestors_(node, attr_name, attr_value)
    return if node.nil?
    elt, rest = node.first, node[1..-1]
    if elt.is_a?(Node)
      if elt.attrs[attr_name] == attr_value
        return elt
      end
    end
    search_ancestors_(rest.push(elt.parent), attr_name, attr_value)
  end

  def search_ancestors(node, attr_name, attr_value)
    return if node.parent.nil?
    search_ancestors_([elts[node.parent]], attr_name, attr_value)
  end

end
