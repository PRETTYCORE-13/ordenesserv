defmodule Prettycore.Workorders do
  @moduledoc false
  alias Prettycore.Repo
  alias Prettycore.Workorders.WorkorderEnc
  import Ecto.Query
  ## Encabezados (órdenes)

  def list_enc do
    ##   Repo.all(WorkorderEnc)
    WorkorderEnc
     |> preload([:tipo])
    |> Repo.all()
  end

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
