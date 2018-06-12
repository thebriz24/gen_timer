defmodule GenTimerTest do
  use ExUnit.Case
  doctest GenTimer

  test "greets the world" do
    assert GenTimer.hello() == :world
  end
end
