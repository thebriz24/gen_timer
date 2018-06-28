# GenTimer
[![Hex Version](https://img.shields.io/hexpm/v/gen_timer.svg "Hex Version")](https://hex.pm/packages/gen_timer)

A GenServer for asynchronously running a function after some duration.

## Installation

```elixir
def deps do
  [
    {:gen_timer, "~> 0.0.2"}
  ]
end
```

## Usage

Register a function and a duration. The function will be called after the duration. If using `start_repeated/4` or
`start_link_repeated/4` it will continue for the specified amount of times.
