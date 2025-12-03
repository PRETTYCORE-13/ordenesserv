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
        IO.inspect(body, label: "crear_cliente ")
        IO.inspect(resp_body, label: "crear_cliente ")
        {:ok, resp_body}

      {:ok, %Req.Response{status: status, body: resp_body}} ->
        IO.inspect(body, label: "crear_cliente ")
        IO.inspect(resp_body, label: "crear_cliente error body")
        {:error, {:http_error, status, resp_body}}

      {:error, reason} ->
        IO.inspect(body, label: "crear_cliente ")
        IO.inspect(reason, label: "crear_cliente error body")
        {:error, reason}
    end
  end

  @doc false
  def transform_to_api_format(cliente_data) do
    direccion = Map.get(cliente_data, :direccion)

    %{
      "clientes" => [
        %{
          "CTECLI_CODIGO_K" => cliente_data.ctecli_codigo_k,
          "CTECLI_RAZONSOCIAL" => cliente_data.ctecli_razonsocial,
          "CTECLI_DENCOMERCIA" => cliente_data.ctecli_dencomercia,
          "CTECLI_RFC" => cliente_data.ctecli_rfc,
          "CTECLI_FECHAALTA" => format_datetime(cliente_data.ctecli_fechaalta),
          "CTECLI_EDOCRED" => cliente_data.ctecli_edocred,
          "CTECLI_DIASCREDITO" => cliente_data.ctecli_diascredito,
          "CTECLI_LIMITECREDI" => format_decimal(cliente_data.ctecli_limitecredi),
          "CTECLI_TIPODEFACT" => cliente_data.ctecli_tipodefact,
          "CTECLI_FORMAPAGO" => cliente_data.ctecli_formapago,
          "CTECLI_METODOPAGO" => cliente_data.ctecli_metodopago,
          "SAT_USO_CFDI_K" => cliente_data.sat_uso_cfdi_k,
          "CTECLI_FERECEPTORMAIL" => cliente_data.ctecli_fereceptormail,
          "CTETPO_CODIGO_K" => cliente_data.ctetpo_codigo_k,
          "CTECAN_CODIGO_K" => cliente_data.ctecan_codigo_k,
          "CTESCA_CODIGO_K" => cliente_data.ctesca_codigo_k,
          "CTEPAQ_CODIGO_K" => cliente_data.ctepaq_codigo_k,
          "CTEREG_CODIGO_K" => cliente_data.ctereg_codigo_k,
          "CFGMON_CODIGO_K" => cliente_data.cfgmon_codigo_k,
          "CTECLI_PAIS" => cliente_data.ctecli_pais,
          "CFGREG_CODIGO_K" => cliente_data.cfgreg_codigo_k,
          "SATEXP_CODIGO_K" => cliente_data.satexp_codigo_k,
          "CATIND_CODIGO_K" => cliente_data.catind_codigo_k,
          "CATPFI_CODIGO_K" => cliente_data.catpfi_codigo_k,
          "CTECLI_GENERICO" => cliente_data.ctecli_generico,
          "CTECLI_NOCTA" => cliente_data.ctecli_nocta,
          "CTECLI_DSCANTIMP" => cliente_data.ctecli_dscantimp,
          "CTECLI_DESGLOSAIEPS" => cliente_data.ctecli_desglosaieps,
          "CTECLI_FACTABLERO" => cliente_data.ctecli_factablero,
          "CTECLI_APLICACANJE" => cliente_data.ctecli_aplicacanje,
          "CTECLI_APLICADEV" => cliente_data.ctecli_aplicadev,
          "CTECLI_DESGLOSAKIT" => cliente_data.ctecli_desglosakit,
          "CTECLI_FACGRUPO" => cliente_data.ctecli_facgrupo,
          "CTECLI_CFDI_VER" => cliente_data.ctecli_cfdi_ver,
          "SYSTRA_CODIGO_K" => cliente_data.systra_codigo_k,
          "S_MAQEDO" => cliente_data.s_maqedo,
          "direccion" => [transform_direccion(direccion)]
        }
      ]
    }
  end

  @doc false
  def transform_direccion(nil), do: nil

  @doc false
  def transform_direccion(direccion) do
    %{
      "CTEDIR_CODIGO_K" => direccion.ctedir_codigo_k,
      "CTEDIR_RESPONSABLE" => direccion.ctedir_responsable,
      "CTEDIR_TELEFONO" => direccion.ctedir_telefono,
      "CTEDIR_CALLE" => direccion.ctedir_calle,
      "CTEDIR_CALLENUMEXT" => direccion.ctedir_callenumext,
      "CTEDIR_CALLENUMINT" => direccion.ctedir_callenumint,
      "CTEDIR_COLONIA" => direccion.ctedir_colonia,
      "CTEDIR_CP" => direccion.ctedir_cp,
      "CTEDIR_CELULAR" => direccion.ctedir_celular,
      "CTEDIR_MAIL" => direccion.ctedir_mail,
      "MAPEDO_CODIGO_K" => direccion.mapedo_codigo_k,
      "MAPMUN_CODIGO_K" => direccion.mapmun_codigo_k,
      "MAPLOC_CODIGO_K" => direccion.maploc_codigo_k,
      "MAP_X" => direccion.map_x,
      "MAP_Y" => direccion.map_y,
      "VTARUT_CODIGO_K_PRE" => direccion.vtarut_codigo_k_pre,
      "VTARUT_CODIGO_K_ENT" => direccion.vtarut_codigo_k_ent,
      "VTARUT_CODIGO_K_AUT" => direccion.vtarut_codigo_k_aut,
      "CTEPFR_CODIGO_K" => direccion.ctepfr_codigo_k,
      "CTECLU_CODIGO_K" => direccion.cteclu_codigo_k,
      "CTEZNI_CODIGO_K" => direccion.ctezni_codigo_k
    }
  end

  @doc false
  def format_datetime(%NaiveDateTime{} = dt) do
    NaiveDateTime.to_iso8601(dt)
  end

  @doc false
  def format_datetime(nil), do: nil

  @doc false
  def format_decimal(%Decimal{} = d) do
    Decimal.to_float(d)
  end

  @doc false
  def format_decimal(value) when is_number(value), do: value

  @doc false
  def format_decimal(nil), do: 0.0
end
