# lib/prettycore_web/live/auth_on_mount.ex
defmodule PrettycoreWeb.AuthOnMount do
  import Phoenix.LiveView, only: [redirect: 2]
  import Phoenix.Component, only: [assign: 3]

  @impl true
  def on_mount(:ensure_authenticated, params, session, socket) do
    user_id = session["user_id"]
    email_from_session = session["user_email"]
    email_from_url = params["email"] || email_from_session

    case user_id do
      nil ->
        {:halt, redirect(socket, to: "/")}

      _ ->
        # request_path lo obtenemos desde las opciones del socket
        path =
          case socket.host_uri do
            nil -> nil
            uri -> uri.path
          end

        {:cont,
         socket
         |> assign(:current_user_id, user_id)
         |> assign(:current_user_email, email_from_url)
         |> assign(:current_path, path)}
    end
  end
end
