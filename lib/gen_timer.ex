defmodule GenTimer do
  @moduledoc """
  Extends GenServer to give a timer functionality. 

  There is a small folder of examples in this repo to guide you.

  ## Callbacks
  Supports the same callbacks as `GenServer`. The only considerations are:

  ### There Is Required State For `init/1`
  The state returned by `c:GenServer.init/1` must include the required keys shown 
  in `t:valid_state/0`, but then you can add any other state you please.

  ### Repeated Funtion Callback
  The callback `c:repeated_function/1` is where you choose what is done each 
  iteration. It will use the current state as the argument and will use the 
  returned state as the state of the GenServer going forward. 
  """

  @type valid_state :: %{milli: pos_integer, times: pos_integer | :infinite, last_return: any}

  @doc """
  This is where you choose what is done each iteration. 

  It will use the current state as the argument and will use the returned state 
  as the state of the GenServer going forward. 
  """
  @callback repeated_function(state :: valid_state) :: valid_state

  defmacro __using__(_args) do
    quote do
      use GenServer, restart: :transient
      @behaviour GenTimer

      @spec last_returned_value(pid()) :: any()
      def last_returned_value(pid) do
        GenServer.call(pid, :last_returned_value)
      end

      # Callbacks

      @impl true
      def handle_info(:start_timer, state) do
        new_state =
          state
          |> check_state()
          |> Map.update(:times, 0, fn times -> schedule_remaining(state.milli, times) end)

        {:noreply, new_state}
      end

      def handle_info(:perform, state) do
        new_state = repeated_function(state)
        {:stop, :normal, new_state}
      end

      def handle_info(:perform_and_reschedule, state) do
        new_state =
          state
          |> repeated_function()
          |> Map.update(:times, 0, fn times -> schedule_remaining(state.milli, times) end)

        {:noreply, new_state}
      end

      @impl true
      def handle_call(:last_returned_value, _from, state) do
        return = Map.get(state, :last_return)
        {:reply, return, state}
      end

      # Private
      defp check_state(state) do
        state |> check_keys() |> check_values()
      end

      defp check_keys(state) do
        cond do
          not Map.has_key?(state, :milli) -> raise GenTimer.RequiredKeyError, :milli
          not Map.has_key?(state, :times) -> raise GenTimer.RequiredKeyError, :times
          not Map.has_key?(state, :last_return) -> Map.put(state, :last_return, nil)
          true -> state
        end
      end

      defp check_values(%{milli: milli}) when not is_integer(milli) or milli < 1 do
        raise GenTimer.InvalidDurationError, milli
      end

      defp check_values(%{times: times} = state) do
        case times do
          :infinite -> :ok
          num when is_integer(num) and num > 0 -> :ok
          other -> raise GenTimer.InvalidRepetitionError, other
        end

        state |> Map.delete(:times) |> check_values() |> Map.put(:times, times)
      end

      defp check_values(state), do: state

      defp schedule_work(job, milli) do
        Process.send_after(self(), job, milli)
      end

      defp schedule_remaining(milli, :infinite) do
        schedule_work(:perform_and_reschedule, milli)
        :infinite
      end

      defp schedule_remaining(milli, times) do
        cond do
          times > 1 -> schedule_work(:perform_and_reschedule, milli)
          times == 1 -> schedule_work(:perform, milli)
          true -> :ok
        end

        times - 1
      end
    end
  end

  @doc """
  Use exactly the same as `GenServer.start_link/3`.

  Only difference is that it will send a message to the process to start the timer.
  """
  @spec start_link(atom, any, GenServer.options()) :: GenServer.on_start()
  def start_link(module, args, options) do
    module
    |> GenServer.start_link(args, options)
    |> send_start_signal()
  end

  @doc """
  Use exactly the same as `GenServer.start/3`. 

  Only difference is that it will send a message to the process to start the timer.
  """
  @spec start(atom, any, GenServer.options()) :: GenServer.on_start()
  def start(module, args, options) do
    module
    |> GenServer.start(args, options)
    |> send_start_signal()
  end

  defdelegate abcast(nodes, name, request), to: GenServer
  defdelegate call(server, request, timeout), to: GenServer
  defdelegate cast(server, request), to: GenServer
  defdelegate multi_call(nodes, name, request, timeout), to: GenServer
  defdelegate reply(client, reply), to: GenServer
  defdelegate stop(server, reason, timeout), to: GenServer

  defp send_start_signal({:ok, pid} = result) do
    Process.send(pid, :start_timer, [])
    result
  end

  defp send_start_signal(other), do: other
end
