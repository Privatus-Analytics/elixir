defmodule PrivatusAnalytics.Props do
  @moduledoc false
  # Cleans event names, property keys and values the same way the tracker does.

  @max_props 30
  @max_list 30
  @max_value 500
  @max_key 64
  @max_name 120

  @doc "Trims an event name and cuts it to 120 characters. Returns nil when empty."
  def event_name(nil), do: nil

  def event_name(name) do
    case name |> to_string() |> String.trim() |> String.slice(0, @max_name) do
      "" -> nil
      clean -> clean
    end
  end

  @doc "Lowercases a key, turns anything but a-z, 0-9 and _ into _, cuts it to 64."
  def key(key) do
    key
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9_]/u, "_")
    |> String.slice(0, @max_key)
  end

  @doc "Props for HTML attributes: every value becomes a string."
  def for_attributes(props) do
    clean(props, &attribute_value/1)
  end

  @doc "Props for JSON: numbers, booleans and string lists keep their type."
  def for_json(props) do
    clean(props, &json_value/1)
  end

  defp clean(nil, _fun), do: []

  defp clean(props, fun) do
    props
    |> Enum.map(fn {key, value} -> {key(key), fun.(value)} end)
    # Maps have no order of their own, so sort them to keep the output stable.
    |> then(fn pairs -> if is_map(props), do: Enum.sort_by(pairs, &elem(&1, 0)), else: pairs end)
    |> Enum.reject(fn {key, value} -> key == "" or value == :drop end)
    |> Enum.uniq_by(fn {key, _} -> key end)
    |> Enum.take(@max_props)
  end

  defp attribute_value(value) when is_list(value) do
    case Enum.map(value, &scalar/1) |> Enum.reject(&(&1 == :drop)) do
      [] -> :drop
      items -> items |> Enum.join(",") |> cut()
    end
  end

  defp attribute_value(value) do
    case scalar(value) do
      :drop -> :drop
      string -> cut(string)
    end
  end

  defp json_value(value) when is_boolean(value) or is_number(value), do: value

  defp json_value(value) when is_list(value) do
    value
    |> Enum.map(&scalar/1)
    |> Enum.reject(&(&1 == :drop))
    |> Enum.take(@max_list)
    |> Enum.map(&cut/1)
  end

  defp json_value(value) do
    case scalar(value) do
      :drop -> :drop
      string -> cut(string)
    end
  end

  # One value as a string, or :drop for nil and things with no text form (maps, tuples).
  defp scalar(nil), do: :drop
  defp scalar(value) when is_binary(value), do: value
  defp scalar(value) when is_integer(value), do: Integer.to_string(value)
  defp scalar(value) when is_float(value), do: Float.to_string(value)
  defp scalar(value) when is_atom(value), do: Atom.to_string(value)

  defp scalar(value) do
    if String.Chars.impl_for(value) && not is_list(value), do: to_string(value), else: :drop
  end

  defp cut(string), do: String.slice(string, 0, @max_value)
end
