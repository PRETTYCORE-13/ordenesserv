defmodule Prettycore.Workorders do
  @moduledoc false
  alias Prettycore.Repo
  alias Prettycore.Workorders.WorkorderEnc
  import Ecto.Query, warn: false
  ## Encabezados (órdenes)

  def list_enc do
    WorkorderEnc
    |> preload([:tipo])
    |> Repo.all()
  end

  @doc """
  Lists workorder headers with optional filters applied at the database level.

  ## Options
    * `:estado` - Filter by estado value (e.g., "por_aceptar" for estado == 100, "todas" for all)
    * `:sysudn` - Filter by sysudn value
    * `:usuario` - Filter by usuario value
    * `:fecha_desde` - Filter by fecha >= this date (ISO8601 string or Date)
    * `:fecha_hasta` - Filter by fecha <= this date (ISO8601 string or Date)

  ## Examples
      iex> list_enc_filtered(%{estado: "por_aceptar"})
      [%WorkorderEnc{}, ...]

      iex> list_enc_filtered(%{sysudn: "100", fecha_desde: "2025-01-01"})
      [%WorkorderEnc{}, ...]
  """
  def list_enc_filtered(filters \\ %{}) do
    WorkorderEnc
    |> apply_estado_filter(filters[:estado])
    |> apply_sysudn_filter(filters[:sysudn])
    |> apply_usuario_filter(filters[:usuario])
    |> apply_fecha_desde_filter(filters[:fecha_desde])
    |> apply_fecha_hasta_filter(filters[:fecha_hasta])
    |> preload([:tipo])
    |> Repo.all()
  end

  # Filter by estado
  defp apply_estado_filter(query, nil), do: query
  defp apply_estado_filter(query, ""), do: query
  defp apply_estado_filter(query, "todas"), do: query
  defp apply_estado_filter(query, "por_aceptar") do
    from w in query, where: w.estado == 100
  end
  defp apply_estado_filter(query, estado) when is_integer(estado) do
    from w in query, where: w.estado == ^estado
  end
  defp apply_estado_filter(query, estado) when is_binary(estado) do
    case Integer.parse(estado) do
      {int_estado, ""} -> apply_estado_filter(query, int_estado)
      _ -> query
    end
  end

  # Filter by sysudn
  defp apply_sysudn_filter(query, nil), do: query
  defp apply_sysudn_filter(query, ""), do: query
  defp apply_sysudn_filter(query, sysudn) do
    from w in query, where: w.sysudn == ^sysudn
  end

  # Filter by usuario
  defp apply_usuario_filter(query, nil), do: query
  defp apply_usuario_filter(query, ""), do: query
  defp apply_usuario_filter(query, usuario) do
    from w in query, where: w.usuario == ^usuario
  end

  # Filter by fecha_desde (from date)
  defp apply_fecha_desde_filter(query, nil), do: query
  defp apply_fecha_desde_filter(query, ""), do: query
  defp apply_fecha_desde_filter(query, fecha_desde) do
    date = parse_date(fecha_desde)
    if date do
      # Convert Date to NaiveDateTime for comparison (start of day)
      naive_datetime = NaiveDateTime.new!(date, ~T[00:00:00])
      from w in query, where: w.fecha >= ^naive_datetime
    else
      query
    end
  end

  # Filter by fecha_hasta (to date)
  defp apply_fecha_hasta_filter(query, nil), do: query
  defp apply_fecha_hasta_filter(query, ""), do: query
  defp apply_fecha_hasta_filter(query, fecha_hasta) do
    date = parse_date(fecha_hasta)
    if date do
      # Convert Date to NaiveDateTime for comparison (end of day)
      naive_datetime = NaiveDateTime.new!(date, ~T[23:59:59])
      from w in query, where: w.fecha <= ^naive_datetime
    else
      query
    end
  end

  # Helper to parse date from various formats
  defp parse_date(%Date{} = date), do: date
  defp parse_date(%NaiveDateTime{} = naive_dt), do: NaiveDateTime.to_date(naive_dt)
  defp parse_date(%DateTime{} = dt), do: DateTime.to_date(dt)
  defp parse_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _} -> nil
    end
  end
  defp parse_date(_), do: nil

  def list_enc2 do
    sql = """
    SELECT
      SYSUDN_CODIGO_K,
      SYSTRA_CODIGO_K,
      WOKE_SERIE_K,
      WOKE_FOLIO_K,
      WOKE_REFERENCIA,
      WOKTPO_CODIGO_K,
      S_MAQEDO,
      WOKE_DESCRIPCION,
      S_FECHA,
      WOKE_USUARIO
    FROM XEN_WOKORDERENC
    """

    case Repo.query(sql, []) do
      {:ok, %{columns: cols, rows: rows}} ->
        list =
          Enum.map(rows, fn row ->
            row_map = to_map(cols, row)

            %{
              sysudn: row_map["SYSUDN_CODIGO_K"],
              systra: row_map["SYSTRA_CODIGO_K"],
              serie: row_map["WOKE_SERIE_K"],
              folio: row_map["WOKE_FOLIO_K"],
              referencia: row_map["WOKE_REFERENCIA"],
              tipo: row_map["WOKTPO_CODIGO_K"],
              estado: row_map["S_MAQEDO"],
              descripcion: row_map["WOKE_DESCRIPCION"],
              fecha: row_map["S_FECHA"],
              usuario: row_map["WOKE_USUARIO"]
            }
          end)

        {:ok, list}

      {:error, error} ->
        IO.inspect(error, label: "error list_enc")
        {:error, error}
    end
  end

  ## Detalle (imágenes)

  def list_det(sysudn, systra, serie, folio) do
    sql = """
    SELECT
      SYSUDN_CODIGO_K,
      SYSTRA_CODIGO_K,
      WOKE_SERIE_K,
      WOKE_FOLIO_K,
      WOKD_RENGLON_K AS CONCEPTO,
      WOKD_IMAGEN    AS IMAGE_URL
    FROM XEN_WOKORDERDET
    WHERE SYSUDN_CODIGO_K = @1
      AND SYSTRA_CODIGO_K = @2
      AND WOKE_SERIE_K    = @3
      AND WOKE_FOLIO_K    = @4
    """

    params = [sysudn, systra, serie, folio]

    case Repo.query(sql, params) do
      {:ok, %{columns: cols, rows: rows}} ->
        Enum.map(rows, fn row ->
          row_map = to_map(cols, row)

          %{
            concepto: row_map["CONCEPTO"],
            descripcion: nil,
            image_url: row_map["IMAGE_URL"]
          }
        end)

      {:error, error} ->
        IO.inspect(error, label: "error list_det")
        []
    end
  end

  ## Helper

  defp to_map(cols, row) do
    cols
    |> Enum.zip(row)
    |> Enum.into(%{})
  end
end
