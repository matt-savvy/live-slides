defmodule LiveSlides.TestSupervisorHelper do
  import ExUnit.Callbacks

  def start_test_supervisor(_) do
    start_supervised!({DynamicSupervisor, name: TestSupervisor})
    :ok
  end
end
