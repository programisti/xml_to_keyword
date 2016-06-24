defmodule XmlToKeyword do
  require Record

  Record.defrecord :xmlElement, Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlText,    Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlAttribute, Record.extract(:xmlAttribute, from_lib: "xmerl/include/xmerl.hrl")

  def convert(xml) do
    {doc, _} = xml |> :binary.bin_to_list |> :xmerl_scan.string
    [elements] = doc
    |> get_root_path
    |> :xmerl_xpath.string(doc)
    |> Enum.map(fn(element) -> parse(xmlElement(element, :content)) end)

    [{get_root_name(doc), elements}]
  end

  defp parse(node) do
    cond do
      Record.is_record(node, :xmlElement) ->
        name    = xmlElement(node, :name)
        content = xmlElement(node, :content)
        case xmlElement(node, :attributes) do
          [] -> 
            [{name, parse(content)}]
          attrs -> 
            Enum.map(attrs, fn(attr) ->
              attr_name = xmlAttribute(attr, :name)
              attr_val = xmlAttribute(attr, :value)
              [{name, Map.put(%{}, attr_name, attr_val), parse(content) }]
            end)
        end

      Record.is_record(node, :xmlText) ->
        xmlText(node, :value) |> to_string

      is_list(node) ->
        case Enum.map(node, &(parse(&1))) do
          [text_content] when is_binary(text_content) ->
            text_content
          elements ->
            Enum.reduce(elements, [], fn(x, acc) ->
              if is_list(x) do
                acc ++ x
              else
                acc
              end
            end)
        end
      true -> IO.inspect "Error in XmlToKeyword not supported"
    end
  end

  defp get_root_name(doc), do: doc |> xmlElement(:name)
  defp get_root_path(doc), do: '//#{get_root_name(doc)}'
end
