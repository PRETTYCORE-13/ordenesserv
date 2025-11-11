defmodule Prettycore.Workorders do
  @moduledoc false

  alias Prettycore.Repo

  ## Encabezados (órdenes)

  def list_enc do
    sql = """
    SELECT
      SYSUDN_CODIGO_K,
      SYSTRA_CODIGO_K,
      WOKE_SERIE_K,
      WOKE_FOLIO_K,
      WOKE_REFERENCIA,
      WOKTPO_CODIGO_K,
      S_MAQEDO,
      WOKE_DESCRIPCION
    FROM XEN_WOKORDERENC
    """

    {:ok, %{columns: cols, rows: rows}} = Repo.query(sql, [])

    Enum.map(rows, fn row ->
      row_map = to_map(cols, row)

      %{
        sysudn:      row_map["SYSUDN_CODIGO_K"],
        systra:      row_map["SYSTRA_CODIGO_K"],
        serie:       row_map["WOKE_SERIE_K"],
        folio:       row_map["WOKE_FOLIO_K"],
        referencia:  row_map["WOKE_REFERENCIA"],
        tipo:        row_map["WOKTPO_CODIGO_K"],
        estado:      row_map["S_MAQEDO"],
        descripcion: row_map["WOKE_DESCRIPCION"]
      }
    end)
  end

  ## Detalle (imágenes)

  def list_det(sysudn, systra, serie, folio) do
    sql = """
    SELECT
      SYSUDN_CODIGO_K,
      SYSTRA_CODIGO_K,
      WOKE_SERIE_K,
      WOKE_FOLIO_K,
      CONCEPTO,
      DESCRIPCION,
      IMAGE_URL,
      IMAGE_DATA
    FROM XEN_WOKORDERDET
    WHERE SYSUDN_CODIGO_K = @p1
      AND SYSTRA_CODIGO_K = @p2
      AND WOKE_SERIE_K    = @p3
      AND WOKE_FOLIO_K    = @p4
    """

    params = [sysudn, systra, serie, folio]

    {:ok, %{columns: cols, rows: rows}} = Repo.query(sql, params)

    Enum.map(rows, fn row ->
      row_map = to_map(cols, row)

      %{
        concepto:   row_map["CONCEPTO"],
        descripcion: row_map["DESCRIPCION"],
        image_url:  row_map["IMAGE_URL"],
        image_data: row_map["IMAGE_DATA"]
      }
    end)
  end

  ## Helper: lista de columnas + lista de valores -> mapa

  defp to_map(cols, row) do
    cols
    |> Enum.zip(row)
    |> Enum.into(%{})
  end
end
