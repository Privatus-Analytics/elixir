ExUnit.start()

defmodule PrivatusAnalytics.Case do
  @moduledoc false
  use ExUnit.CaseTemplate

  @keys ~w(site_id script_host modules excluded_paths domains spa manual enabled
           enabled_environments env extra_attributes props queue_stub nonce_assign)a

  using do
    quote do
      import PrivatusAnalytics.Case
    end
  end

  setup do
    reset()
    on_exit(&reset/0)
  end

  def configure(settings) do
    Enum.each(settings, fn {key, value} ->
      Application.put_env(:privatus_analytics, key, value)
    end)
  end

  def reset do
    Enum.each(@keys, &Application.delete_env(:privatus_analytics, &1))
    System.delete_env("PRIVATUS_SITE_ID")
    System.delete_env("PRIVATUS_SCRIPT_HOST")
  end
end
