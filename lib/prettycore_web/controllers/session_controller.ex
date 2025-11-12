defmodule PrettycoreWeb.SessionController do
  use PrettycoreWeb, :controller
  alias Prettycore.Auth

  # POST /
  def create(conn, %{"username" => user, "password" => pass}) do
    case Auth.authenticate(user, pass) do
      {:ok, %{id: id}} ->
        conn
        |> put_session(:user_id, id)      # guarda el ID del usuario
        |> configure_session(renew: true) # rota el session id
        |> redirect(to: ~p"/admin/platform")

      {:ok, _} ->
        conn
        |> put_session(:user_id, user)    # si tu Auth no devuelve id aún
        |> configure_session(renew: true)
        |> redirect(to: ~p"/admin/platform")

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Usuario o contraseña incorrectos")
        |> redirect(to: ~p"/")
    end
  end

  # GET /ui/logout
  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)      # borra TODA la sesión
    |> put_flash(:info, "Sesión cerrada")
    |> redirect(to: ~p"/")
  end
end
