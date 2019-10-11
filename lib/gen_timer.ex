defmodule GenTimer do
  @moduledoc ~S"""
  A GenServer for asynchronously running a function after some duration.

  ## Usage
  Register a function and a duration. The function will be called after the duration. If using `start_repeated/4` or
  `start_link_repeated/4` it will continue for the specified amount of times.
  """
  use GenServer

  @doc """
    Starts a `GenServer` process without links (outside of a supervision tree). The `function` is registered. After the
    `milli` duration the function will be called using specified `args`.
  """
  @spec start((... -> {any(), new_state :: any()}), list(), non_neg_integer()) :: GenServer.on_start()
  def start(function, args, milli), do: start_repeated(function, args, milli, 1)

  @doc """
    The same as `start/3` but allows to specify an amount of `times` to repeat, defaulting to `:infinite`.
  """
  @spec start_repeated((... -> {any(), new_state :: any()}), list(), non_neg_integer(), non_neg_integer() | :infinite) ::
          GenServer.on_start()
  def start_repeated(function, args, milli, times \\ :infinite) do
    GenServer.start(
      __MODULE__,
      %{function: function, args: args, milli: milli, times: times},
      name: GenTimer
    )
  end

  @doc """
    Starts a `GenServer` process linked to the current process. The `function` is registered. After the
    `milli` duration the function will be called using specified `args`.
  """
  @spec start_link((... -> {any(), new_state :: any()}), list(), non_neg_integer()) :: GenServer.on_start()
  def start_link(function, args, milli), do: start_link_repeated(function, args, milli, 1)

  @doc """
    The same as `start_link/3` but allows to specify an amount of `times` to repeat, defaulting to `:infinite`.
  """
  @spec start_link_repeated(
          (... -> {any(), new_state :: any()}),
          list(),
          non_neg_integer(),
          non_neg_integer() | :infinite
        ) :: GenServer.on_start()
  def start_link_repeated(function, args, milli, times \\ :infinite) do
    GenServer.start_link(
      __MODULE__,
      %{function: function, args: args, milli: milli, times: times},
      name: GenTimer
    )
  end

  @doc """
    Synchronously calls the `GenServer` at `pid` to receive the last value returned by the registered function. All previous
    returned values will not be kept.
  """
  @spec last_returned_value(pid()) :: any()
  def last_returned_value(pid) do
    GenServer.call(pid, :last_returned_value)
  end

  defp schedule_work(:perform, milli) do
    Process.send_after(self(), :perform, milli)
  end

  defp schedule_work(:perform_and_reschedule, milli) do
    Process.send_after(self(), :perform_and_reschedule, milli)
  end

  defp schedule_remaining(milli, :infinite) do
    schedule_work(:perform_and_reschedule, milli)
    :infinite
  end

  defp schedule_remaining(milli, times) do
    if times > 1 do
      schedule_work(:perform_and_reschedule, milli)
    else
      schedule_work(:perform, milli)
    end

    times - 1
  end

  ## Callbacks

  @doc """
    Imported by `GenServer.__using__/1`
  """
  def init(%{milli: milli, times: :infinite} = state) do
    schedule_work(:perform_and_reschedule, milli)
    {:ok, state}
  end

  def init(%{milli: milli} = state) do
    state =
      Map.update(state, :times, 0, fn times ->
        schedule_remaining(milli, times)
      end)

    {:ok, state}
  end

  def handle_info(:perform, state) do
    {return, new_args} = apply(state.function, state.args)
    new_state = state |> Map.put(:return, return) |> Map.put(:args, new_args)
    {:stop, :normal, new_state}
  end

  def handle_info(:perform_and_reschedule, state) do
    {return, new_args} = apply(state.function, state.args)

    new_state =
      state
      |> Map.update(:times, 0, fn times -> schedule_remaining(state.milli, times) end)
      |> Map.put(:return, return)
      |> Map.put(:args, new_args)

    {:noreply, new_state}
  end

  def handle_call(:last_returned_value, _from, state) do
    return = Map.get(state, :return)
    {:reply, return, state}
  end
end
