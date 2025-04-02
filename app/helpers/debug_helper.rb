# frozen_string_literal: true

module DebugHelper
  LABELS = { gql: 'label-info', method: 'label-inverse', set: 'label-warning',
error: 'label-important' }.freeze

  def method_source(method_name)
    Rails.cache.fetch("methods/source/#{method_name}") do
        f, line = Qernel::NodeApi.instance_method(method_name)&.source_location
        if f && line
          lines = File.read(f).lines.to_a
          source = lines[line - 1]
          intendation = source.match(/^(\s*)def/).captures.first

          lines[line..].each do |l|
            source << l
            break if /^#{intendation}end/.match?(l)
          end

          source
        end
    rescue StandardError => e
        e
    end
  end

  def log_tree(logs = @logs)
    updates, logs = logs.partition { |l| l[:type] == :update }

    if (tree = Qernel::Logger.to_tree(logs))
      log_subtree(tree)
    end

    concat(content_tag(:h3, 'UPDATE commands'))

    if (tree = Qernel::Logger.to_tree(updates))
      log_subtree(tree)
    end
  end

  def log_subtree(subtree)
    raise 'log_subtree requires the variables @gquery_keys and @method_definitions' if @gquery_keys.nil? || @method_definitions.nil?

    concat(content_tag(:ul, class: 'unstyled') do
      safe_join(
        subtree.filter_map do |parent, children|
          next if parent.nil?

          type      = parent[:type]
          attr_name = parent[:attr_name]
          value     = parent[:value]

          content_tag(:li) do
            html = []
            html << content_tag(:p, class: type) do
              inner = []
              inner << content_tag('span', type.to_s, class: "label unfold_toggle #{LABELS[type]}")
              inner << '&nbsp;'.html_safe
              inner << log_folding_tags(type)
              inner << log_title(parent)
              inner << log_value(value)
              safe_join(inner)
            end

            if (gquery_key = parent[:gquery_key]) && @gquery_keys.exclude?(gquery_key) && (gquery = Gquery.get(gquery_key.to_s))
                html << content_tag(:strong, "#{gquery.unit || '-'} ", class: 'pull-right')
                html << content_tag(:div, class: 'offset1') do
                  with_tabs(0) do
                    content_tag(:pre, gquery.query, class: 'gql')
                  end
                end
                @gquery_keys << gquery_key
            end

            html << log_subtree(children) unless children.nil?
            safe_join(html)
          end
        end
      )
    end)
  end

  def log_title(log)
    type      = log[:type]
    attr_name = log[:attr_name]

    if type == :method
      concat(content_tag(:a, attr_name.to_s,
        href: 'javascript:void(null)',
        rel: 'modal',
        data: {
          target: "##{attr_name}",
          toggle: :modal
        },
        class: 'attr_name'))
      @method_definitions << attr_name
    else
      concat(content_tag(:span, attr_name.to_s, class: 'attr_name'))
      if log[:node]
        haml_concat(link_to('>>', inspect_node_path(id: log[:node], graph_name: :energy)))
      end
    end
    nil
  end

  def log_value(value)
    value = value.first if value.is_a?(Array) && value.length == 1

    tag_text = if value.is_a?(Array)
      "#{value.length} #"
    else
      auto_number(value)
    end

    concat(content_tag(:strong, tag_text, class: 'pull-right'))
  end

  def log_folding_tags(type)
    return unless %i[attr method].include?(type)

    content_tag(:span) do
      if type == :attr
        safe_join([
          content_tag(:span, '-'),
          content_tag(:span, '+')
        ])
      else
        safe_join([
          content_tag(:a, '-', href: 'javascript:void(null)', class: 'fold_all'),
          content_tag(:a, '+', href: 'javascript:void(null)', class: 'unfold_all')
        ])
      end
    end
  end

  def calculation_debugger_path(node, calculation)
    inspect_debug_gql_path(gquery: "V(#{node.key}, #{calculation})")
  end

  def merit_order_nodes(graph, type)
    unless (nodes = Etsource::MeritOrder.new.import_electricity[type.to_s])
      raise "No such merit order group: #{type.inspect}"
    end

    nodes
      .map     { |key, *_| graph.node(key) }
      .sort_by { |node| node[:merit_order_position] }
  end
end
