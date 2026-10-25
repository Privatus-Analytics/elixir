defmodule PrivatusAnalytics.HTML do
  @moduledoc false
  # Small HTML and JSON helpers, so the package does not need phoenix_html or Jason.

  @doc "Escapes text for an HTML attribute value or element body."
  def escape(value) do
    value
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end

  @doc "Builds `name=\"value\"` pairs. A `true` value prints the bare name."
  def attributes(pairs) do
    Enum.map_join(pairs, " ", fn
      {name, true} -> to_string(name)
      {name, value} -> ~s(#{name}="#{escape(value)}")
    end)
  end

  @doc """
  Encodes JSON that is safe inside a `<script>` element: `<`, `>`, `&`, U+2028
  and U+2029 are written as `\\u` escapes.
  """
  def json(value) when is_boolean(value), do: to_string(value)
  def json(nil), do: "null"
  def json(value) when is_integer(value), do: Integer.to_string(value)
  def json(value) when is_float(value), do: Float.to_string(value)
  def json(value) when is_binary(value), do: [?", json_string(value), ?"] |> IO.iodata_to_binary()
  def json(value) when is_list(value), do: "[" <> Enum.map_join(value, ",", &json/1) <> "]"

  def json({:object, pairs}) do
    "{" <>
      Enum.map_join(pairs, ",", fn {key, value} -> json(key) <> ":" <> json(value) end) <> "}"
  end

  defp json_string(string) do
    for <<char::utf8 <- string>>, into: "", do: json_char(char)
  end

  defp json_char(?"), do: "\\\""
  defp json_char(?\\), do: "\\\\"
  defp json_char(?\n), do: "\\n"
  defp json_char(?\r), do: "\\r"
  defp json_char(?\t), do: "\\t"
  defp json_char(char) when char in [?<, ?>, ?&, 0x2028, 0x2029] or char < 0x20, do: unicode(char)
  defp json_char(char), do: <<char::utf8>>

  defp unicode(char) do
    "\\u" <> (char |> Integer.to_string(16) |> String.downcase() |> String.pad_leading(4, "0"))
  end
end
