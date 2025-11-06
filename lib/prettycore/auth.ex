defmodule Prettycore.Auth do
  @moduledoc false

  alias Prettycore.Repo
  alias Prettycore.Auth.User

  # Regresa {:ok, user} o {:error, :invalid_credentials}
  def authenticate(username, password)
      when is_binary(username) and is_binary(password) do
    case Repo.get_by(User,
           sysusr_codigo_k: username,
           sysusr_password: password
         ) do
      nil -> {:error, :invalid_credentials}
      user -> {:ok, user}
    end
  end
end
