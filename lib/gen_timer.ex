defmodule GenTimer do
  @moduledoc false

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

  def start_link(module, args, options) do
    case GenServer.start_link(module, args, options) do
      {:ok, pid} = return ->
        Process.send(pid, :start_timer, [])
        return

      other ->
        other
    end
  end

  @type valid_state :: %{milli: pos_integer, times: pos_integer | :infinite, last_return: any}
  @callback repeated_function(state :: valid_state) :: valid_state
end
