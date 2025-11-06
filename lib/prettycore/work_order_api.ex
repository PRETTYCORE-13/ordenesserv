defmodule Prettycore.WorkorderApi do
  @moduledoc false

  @url "http://ecore.ath.cx:1406/SP/EN_RESTHELPER/workorder"

  @token "QGXWeAvvj1p5v1EVOQoeR8HI1VHk25K6UT7A4xPgA81UXHKGBdE1f21spgwZmiE3"

  def workorder(ref) do
    body = %{"WOKE_REFERENCIA" => ref}

    req =
      Req.new(
        url: @url,
        headers: [
          {"authorization", "Bearer " <> @token},
          {"content-type", "application/json"}
        ],
        json: body
      )

    case Req.post(req) do
      {:ok, %Req.Response{status: 200, body: resp_body}} ->
        {:ok, resp_body}

      {:ok, %Req.Response{status: status, body: resp_body}} ->
        {:error, {:http_error, status, resp_body}}

      {:error, reason} ->
        {:error, {:request_error, reason}}
    end
  end
end
