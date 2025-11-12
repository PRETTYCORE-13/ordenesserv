defmodule PrettycoreWeb.LoginController do
  use PrettycoreWeb, :controller
  alias Prettycore.Auth

  def create(conn, %{"username" => user, "password" => pass}) do
    case Auth.authenticate(user, pass) do
      {:ok, %{id: id}} ->
        conn
        |> put_session(:user_id, id)        # guarda ID real
        |> configure_session(renew: true)   # rotar session id
        |> redirect(to: ~p"/ui/platform")

      {:ok, _} ->
        conn
        |> put_session(:user_id, user)      # fallback si no tienes id
        |> configure_session(renew: true)
        |> redirect(to: ~p"/ui/platform")

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Usuario o contraseña incorrectos")
        |> redirect(to: ~p"/ui/login")
    end
  end

  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/ui/login")
  end
end
