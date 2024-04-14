defmodule EnterTest do
  use ExUnit.Case
  doctest Enter

  test "greets the world" do
    assert Enter.hello() == :world
  end
end
