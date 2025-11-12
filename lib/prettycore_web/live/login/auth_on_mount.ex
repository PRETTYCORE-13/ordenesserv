# lib/prettycore_web/live/auth_on_mount.ex
defmodule PrettycoreWeb.AuthOnMount do
  import Phoenix.LiveView, only: [redirect: 2]
  import Phoenix.Component, only: [assign: 2, assign: 3]

  @impl true
  def on_mount(:ensure_authenticated, _params, session, socket) do
    case session["user_id"] do
      nil ->
        {:halt, redirect(socket, to: "/")}
      user_id ->
        {:cont, assign(socket, :current_user_id, user_id)}
    end
  end
end
