defmodule Prettycore.ClientesApi do
  @moduledoc """
  API client for managing clientes via REST API
  """

  @url "http://ecore.ath.cx:1406/SP/EN_RESTHELPER/Clientes"

  @doc """
  Creates a new client via REST API.

  ## Parameters
    - cliente_data: Map with client data (from embedded schema)
    - password: User password for authentication

  ## Returns
    - {:ok, response_body} on success
    - {:error, reason} on failure
  """
  def crear_cliente(cliente_data, password) do
    # Transform embedded schema data to API format
    body = transform_to_api_format(cliente_data)

    headers = [
      {"authorization", "Bearer " <> password},
      {"content-type", "application/json"}
    ]

    case Req.post(@url, json: body, headers: headers) do
      {:ok, %Req.Response{status: status, body: resp_body}} when status in 200..299 ->
        {:ok, resp_body}

      {:ok, %Req.Response{status: status, body: resp_body}} ->
        IO.inspect(resp_body, label: "crear_cliente error body")
        {:error, {:http_error, status, resp_body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Transform embedded schema to API format
  defp transform_to_api_format(cliente_data) do
    direccion = Map.get(cliente_data, :direccion)

    %{
      "ctecli_codigo_k" => cliente_data.ctecli_codigo_k,
      "ctecli_razonsocial" => cliente_data.ctecli_razonsocial,
      "ctecli_dencomercia" => cliente_data.ctecli_dencomercia,
      "ctecli_rfc" => cliente_data.ctecli_rfc,
      "ctecli_fechaalta" => format_datetime(cliente_data.ctecli_fechaalta),
      "ctecli_edocred" => cliente_data.ctecli_edocred,
      "ctecli_diascredito" => cliente_data.ctecli_diascredito,
      "ctecli_limitecredi" => format_decimal(cliente_data.ctecli_limitecredi),
      "ctecli_tipodefact" => cliente_data.ctecli_tipodefact,
      "ctecli_formapago" => cliente_data.ctecli_formapago,
      "ctecli_metodopago" => cliente_data.ctecli_metodopago,
      "sat_uso_cfdi_k" => cliente_data.sat_uso_cfdi_k,
      "ctecli_fereceptormail" => cliente_data.ctecli_fereceptormail,
      "ctetpo_codigo_k" => cliente_data.ctetpo_codigo_k,
      "ctecan_codigo_k" => cliente_data.ctecan_codigo_k,
      "ctesca_codigo_k" => cliente_data.ctesca_codigo_k,
      "ctepaq_codigo_k" => cliente_data.ctepaq_codigo_k,
      "ctereg_codigo_k" => cliente_data.ctereg_codigo_k,
      "cfgmon_codigo_k" => cliente_data.cfgmon_codigo_k,
      "ctecli_pais" => cliente_data.ctecli_pais,
      "cfgreg_codigo_k" => cliente_data.cfgreg_codigo_k,
      "satexp_codigo_k" => cliente_data.satexp_codigo_k,
      "catind_codigo_k" => cliente_data.catind_codigo_k,
      "catpfi_codigo_k" => cliente_data.catpfi_codigo_k,
      "ctecli_generico" => cliente_data.ctecli_generico,
      "ctecli_nocta" => cliente_data.ctecli_nocta,
      "ctecli_dscantimp" => cliente_data.ctecli_dscantimp,
      "ctecli_desglosaieps" => cliente_data.ctecli_desglosaieps,
      "ctecli_factablero" => cliente_data.ctecli_factablero,
      "ctecli_aplicacanje" => cliente_data.ctecli_aplicacanje,
      "ctecli_aplicadev" => cliente_data.ctecli_aplicadev,
      "ctecli_desglosakit" => cliente_data.ctecli_desglosakit,
      "ctecli_facgrupo" => cliente_data.ctecli_facgrupo,
      "ctecli_cfdi_ver" => cliente_data.ctecli_cfdi_ver,
      "systra_codigo_k" => cliente_data.systra_codigo_k,
      "s_maqedo" => cliente_data.s_maqedo,
      "direccion" => transform_direccion(direccion)
    }
  end

  defp transform_direccion(nil), do: nil

  defp transform_direccion(direccion) do
    %{
      "ctedir_codigo_k" => direccion.ctedir_codigo_k,
      "ctedir_responsable" => direccion.ctedir_responsable,
      "ctedir_telefono" => direccion.ctedir_telefono,
      "ctedir_calle" => direccion.ctedir_calle,
      "ctedir_callenumext" => direccion.ctedir_callenumext,
      "ctedir_callenumint" => direccion.ctedir_callenumint,
      "ctedir_colonia" => direccion.ctedir_colonia,
      "ctedir_cp" => direccion.ctedir_cp,
      "ctedir_celular" => direccion.ctedir_celular,
      "ctedir_mail" => direccion.ctedir_mail,
      "mapedo_codigo_k" => direccion.mapedo_codigo_k,
      "mapmun_codigo_k" => direccion.mapmun_codigo_k,
      "maploc_codigo_k" => direccion.maploc_codigo_k,
      "map_x" => direccion.map_x,
      "map_y" => direccion.map_y,
      "vtarut_codigo_k_pre" => direccion.vtarut_codigo_k_pre,
      "vtarut_codigo_k_ent" => direccion.vtarut_codigo_k_ent,
      "vtarut_codigo_k_aut" => direccion.vtarut_codigo_k_aut,
      "ctepfr_codigo_k" => direccion.ctepfr_codigo_k,
      "cteclu_codigo_k" => direccion.cteclu_codigo_k,
      "ctezni_codigo_k" => direccion.ctezni_codigo_k
    }
  end

  defp format_datetime(%NaiveDateTime{} = dt) do
    NaiveDateTime.to_iso8601(dt)
  end

  defp format_datetime(nil), do: nil

  defp format_decimal(%Decimal{} = d) do
    Decimal.to_float(d)
  end

  defp format_decimal(value) when is_number(value), do: value
  defp format_decimal(nil), do: 0.0
end
