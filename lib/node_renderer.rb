class NodeRenderer

  attr_accessor :tree

  def initialize(tr)
    @tree = tr
  end

  # How many total nodes there are in the sub-tree below this node
  def render(node = nil)
    elt = node | tree
    puts "\nNodes: #{elt.body.count}"
    puts "\nAttributes:"
    elt.attrs.each{ |k, v| puts("#{k}: #{v}") }
    children = elt.body.select{ |i| i.is_a?(Node) }
    puts "\nChildren: #{children.each{ |c| render(c) }}"


  end


end
