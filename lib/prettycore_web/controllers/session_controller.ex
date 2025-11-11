defmodule PrettycoreWeb.SessionController do
  use PrettycoreWeb, :controller
  alias Prettycore.Auth

  def create(conn, %{"username" => username, "password" => password}) do
    case Auth.authenticate(username, password) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.sysusr_codigo_k)
        |> put_flash(:info, "Bienvenido #{user.sysusr_codigo_k}")
        |> redirect(to: "/admin/platform")
      :error ->
        conn
        |> put_flash(:error, "Credenciales inválidas")
        |> redirect(to: Routes.session_path(conn, :new))
    end
  end
end
