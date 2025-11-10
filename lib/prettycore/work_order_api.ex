defmodule Prettycore.WorkorderApi do
  @moduledoc false

  @url "http://ecore.ath.cx:1406/SP/EN_RESTHELPER/workorderEstado"

  # OJO: pon aquí tu token real o léelo de ENV
  @token "QGXWeAvvj1p5v1EVOQoeR8HI1VHk25K6UT7A4xPgA81UXHKGBdE1f21spgwZmiE3"
  # recomendado:
  # @token System.get_env("WORKORDER_BEARER")

  # estado: 1 = aceptar, 0 = rechazar
  def cambiar_estado(ref, estado) when estado in [0, 1] do
    body = %{
      "WOKE_REFERENCIA" => ref,
      "Estado" => Integer.to_string(estado)
    }

    headers = [
      {"authorization", "Bearer " <> @token},
      {"content-type", "application/json"}
    ]

    case Req.post(@url, json: body, headers: headers) do
      {:ok, %Req.Response{status: status, body: resp_body}} when status in 200..299 ->
        {:ok, resp_body}

      {:ok, %Req.Response{status: status, body: resp_body}} ->
        IO.inspect(resp_body, label: "workorderEstado error body")
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
