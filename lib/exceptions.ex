defmodule GenTimer.RequiredKeyError do
  defexception [:message]

  @impl true
  def exception(key) do
    %__MODULE__{message: "must include #{key} in the initial args"}
  end
end

defmodule GenTimer.InvalidDurationError do
  defexception [:message]

  @impl true
  def exception(milli) do
    %__MODULE__{message: "invalid duration; example: %{milli: 5000}, had: %{milli: #{milli}}"}
  end
end

defmodule GenTimer.InvalidRepetitionError do
  defexception [:message]

  @impl true
  def exception(times) do
    %__MODULE__{
      message:
        "invalid repetition; example: %{times: 5} or %{times: :infinite}, had: %{times: #{times}}"
    }
  end
end
