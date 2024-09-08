# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  # Graph represents a labelled directed graph.
  #
  # This is an intermediate data structure for rendering Mermaid and Graphviz diagrams.
  class Graph
    # @rbs!
    #   type node_shape = :circle | :doublecircle

    # Node represents a node of graphs.
    #
    # @rbs skip
    Node = Data.define(:label, :shape)

    # @rbs!
    #   class Node < Data
    #     attr_reader label: String
    #     attr_reader shape: node_shape
    #     def self.[]: (String label, node_shape shape) -> Node
    #   end

    # Edge represents an edge of graphs.
    #
    # @rbs skip
    Edge = Data.define(:from, :label, :to)

    # @rbs!
    #   class Edge < Data
    #     attr_reader from: Integer
    #     attr_reader label: String
    #     attr_reader to: Integer
    #     def self.[]: (Integer from, String label, Integer to) -> Edge
    #   end

    # Returns the escaped string for Mermaid diagrams.
    #
    # See https://mermaid.js.org/syntax/flowchart.html#entity-codes-to-escape-characters.
    #
    #: (String label) -> String
    def self.mermaid_escape(label)
      label =
        label.gsub(/[#"]/) do |c|
          case c
          in "#"
            "#35;"
          in "\""
            "#quot;"
          end
        end
      "\"#{label}\""
    end

    # Returns the escaped string for GraphViz DOTs.
    #
    # See https://graphviz.org/docs/attr-types/escString/.
    #
    #: (String label) -> String
    def self.dot_escape(label)
      label =
        label.gsub(/[\\"]/) do |c|
          case c
          in "\\"
            "\\\\"
          in "\""
            "\\\""
          end
        end
      "\"#{label}\""
    end

    # @rbs @nodes: Hash[Integer, Node]
    # @rbs @edges: Array[Edge]

    #: (Hash[Integer, Node] nodes, Array[Edge] edges) -> void
    def initialize(nodes, edges)
      @nodes = nodes
      @edges = edges
    end

    attr_reader :nodes #: Hash[Integer, Node]
    attr_reader :edges #: Array[Edge]

    # Returns a [Mermaid](https://mermaid.js.org) diagram of this graph.
    #
    #: (?direction: "TD" | "LR") -> String
    def to_mermaid(direction: "TD")
      mmd = +""

      mmd << "flowchart #{direction}\n"

      nodes.each do |index, node|
        node_def =
          case node.shape
          in :circle
            "((#{Graph.mermaid_escape(node.label)}))"
          in :doublecircle
            "(((#{Graph.mermaid_escape(node.label)})))"
          end
        mmd << "  #{index}#{node_def}\n"
      end
      mmd << "\n"

      edges.each { |edge| mmd << "  #{edge.from} -- #{Graph.mermaid_escape(edge.label)} --> #{edge.to}\n" }

      mmd.freeze
    end

    # Returns a [GraphViz](https://graphviz.org) DOT diagram of this graph.
    #
    #: () -> String
    def to_dot
      dot = +""

      dot << "digraph {\n"

      nodes.each { |index, node| dot << "  #{index} [label=#{Graph.dot_escape(node.label)}, shape=#{node.shape}];\n" }
      dot << "\n"

      edges.each { |edge| dot << "  #{edge.from} -> #{edge.to} [label=#{Graph.dot_escape(edge.label)}];\n" }

      dot << "}\n"

      dot.freeze
    end
  end
end
