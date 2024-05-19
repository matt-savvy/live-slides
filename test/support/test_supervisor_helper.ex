defmodule LiveSlides.TestSupervisorHelper do
  import ExUnit.Callbacks

  def set_env_test_supervisor(_) do
    Application.put_env(:live_slides, :supervisor, TestSupervisor)

    on_exit(fn ->
      Application.delete_env(:live_slides, :supervisor)
    end)
  end

  def start_test_supervisor(_) do
    start_supervised!({DynamicSupervisor, name: TestSupervisor})
    :ok
  end
end
