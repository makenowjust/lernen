# frozen_string_literal: true
# rbs_inline: enabled

module Lernen
  # Graph represents a labelled directed graph.
  #
  # This is an intermediate data structure for rendering Mermaid and Graphviz diagrams.
  class Graph
    # @rbs!
    #   type node_shape = :circle | :doublecircle | :record | :none
    #
    #   type mermaid_direction = "TD" | "DT" | "LR" | "RL"

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
    #     attr_reader from: Integer | String
    #     attr_reader label: String | nil
    #     attr_reader to: Integer | String
    #     def self.[]: (Integer | String from, String | nil label, Integer | String to) -> Edge
    #   end

    # SubGraph represents a sub-graph of graphs.
    #
    # @rbs skip
    SubGraph = Data.define(:label, :graph)

    # @rbs!
    #   class SubGraph < Data
    #     attr_reader label: String
    #     attr_reader graph: Graph
    #     def self.[]: (String label, Graph graph) -> SubGraph
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

    # @rbs @nodes: Hash[Integer | String, Node]
    # @rbs @edges: Array[Edge]
    # @rbs @subgraphs: Array[SubGraph]

    #: (
    #    Hash[Integer | String, Node] nodes,
    #    Array[Edge] edges,
    #    ?Array[SubGraph] subgraphs
    #  ) -> void
    def initialize(nodes, edges, subgraphs = [])
      @nodes = nodes
      @edges = edges
      @subgraphs = subgraphs
    end

    attr_reader :nodes #: Hash[Integer | String, Node]
    attr_reader :edges #: Array[Edge]
    attr_reader :subgraphs #: Array[SubGraph]

    # Returns a [Mermaid](https://mermaid.js.org) diagram of this graph.
    #
    #: (?direction: mermaid_direction) -> String
    def to_mermaid(direction: "TD")
      mmd = +""

      mmd << "flowchart #{direction}\n"
      mmd << to_mermaid_internal

      mmd.freeze
    end

    # Returns a [GraphViz](https://graphviz.org) DOT diagram of this graph.
    #
    #: () -> String
    def to_dot
      dot = +""

      dot << "digraph {\n"
      dot << to_dot_internal
      dot << "}\n"

      dot.freeze
    end

    protected

    #: (?String id_prefix) -> String
    def to_mermaid_internal(id_prefix = "")
      mmd = +""
      needs_sep = false

      nodes.each do |id, node|
        needs_sep = true

        node_def =
          case node.shape
          in :circle
            "((#{Graph.mermaid_escape(node.label)}))"
          in :doublecircle
            "(((#{Graph.mermaid_escape(node.label)})))"
          in :record
            "(#{Graph.mermaid_escape(node.label)})"
          in :none
            "@{ shape: sm-circ }"
          end
        mmd << "  #{id_prefix}#{id}#{node_def}\n"
      end
      mmd << "\n" if needs_sep

      edges.each do |edge|
        needs_sep = true

        from = "#{id_prefix}#{edge.from}"
        to = "#{id_prefix}#{edge.to}"
        if edge.label
          mmd << "  #{from} -- #{Graph.mermaid_escape(edge.label)} --> #{to}\n"
        else
          mmd << "  #{from} --> #{to}\n"
        end
      end

      subgraphs.each_with_index do |subgraph, index|
        mmd << "\n" if needs_sep
        needs_sep = true

        subgraph_id = "#{id_prefix}g#{index}"
        mmd << "  subgraph #{subgraph_id}[#{Graph.mermaid_escape(subgraph.label)}]\n"
        subgraph
          .graph
          .to_mermaid_internal("#{subgraph_id}_")
          .lines
          .each { |line| mmd << (line == "\n" ? line : "  #{line}") }
        mmd << "  end\n"
      end

      mmd.freeze
    end

    #: (?String id_prefix) -> String
    def to_dot_internal(id_prefix = "")
      dot = +""
      needs_sep = false

      nodes.each do |index, node|
        needs_sep = true
        name = index.is_a?(String) ? index : "#{id_prefix}#{index}"

        if node.shape == :record
          label = Graph.dot_escape("{ #{node.label} }")
          dot << "  #{name} [label=#{label}, shape=record, style=rounded];\n"
        else
          dot << "  #{name} [label=#{Graph.dot_escape(node.label)}, shape=#{node.shape}];\n"
        end
      end
      dot << "\n" if needs_sep

      edges.each do |edge|
        needs_sep = true

        from = edge.from.is_a?(String) ? edge.from : "#{id_prefix}#{edge.from}"
        to = edge.to.is_a?(String) ? edge.to : "#{id_prefix}#{edge.to}"
        if edge.label
          dot << "  #{from} -> #{to} [label=#{Graph.dot_escape(edge.label)}];\n"
        else
          dot << "  #{from} -> #{to};\n"
        end
      end

      subgraphs.each_with_index do |subgraph, index|
        dot << "\n" if needs_sep
        needs_sep = true

        subgraph_id = "#{id_prefix}g#{index}"
        dot << "  subgraph cluster_#{subgraph_id} {\n"
        dot << "    label=#{Graph.dot_escape(subgraph.label)};\n"
        subgraph
          .graph
          .to_dot_internal("#{subgraph_id}_")
          .lines
          .each { |line| dot << (line == "\n" ? line : "  #{line}") }
        dot << "  }\n"
      end

      dot.freeze
    end
  end
end
