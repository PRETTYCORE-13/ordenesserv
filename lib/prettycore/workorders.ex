defmodule Prettycore.Workorders do
  import Ecto.Query, only: [from: 2]

  alias Prettycore.Repo
  alias Prettycore.WorkOrder
  alias Ecto.Adapters.SQL

  @doc """
  Lista encabezados desde XEN_WOKORDERENC.

  Regresa:
  - referencia
  - tipo
  - sysudn, systra, serie, folio (llaves para detalle)
  """
  def list_enc do
    from(w in WorkOrder,
      select: %{
        referencia: w.woke_referencia,
        tipo: w.woktpo_codigo_k,
        sysudn: w.sysudn_codigo_k,
        systra: w.systra_codigo_k,
        serie: w.woke_serie_k,
        folio: w.woke_folio_k
      }
    )
    |> Repo.all()
  end

  @doc """
  Lee detalle desde XEN_WOKORDERDET con SELECT * y trata de detectar el campo de imagen.

  Regresa lista de mapas:
    [%{image_data: "...base64..."}, ...]
  """
  def list_det(sysudn, systra, serie, folio) do
    sql = """
    SELECT *
    FROM [dbo].[XEN_WOKORDERDET]
    WHERE SYSUDN_CODIGO_K = @1
      AND SYSTRA_CODIGO_K = @2
      AND WOKE_SERIE_K   = @3
      AND WOKE_FOLIO_K   = @4
    """

    case SQL.query(Repo, sql, [sysudn, systra, serie, folio]) do
      {:ok, %{columns: cols, rows: rows}} ->
        Enum.map(rows, fn row ->
          row_map =
            cols
            |> Enum.zip(row)
            |> Enum.into(%{})

          # 1) Intenta por nombre de columna (IMG / IMAGE)
          img1 =
            row_map
            |> Enum.find_value(fn {k, v} ->
              name = k |> to_string() |> String.upcase()

              if (String.contains?(name, "IMG") or String.contains?(name, "IMAGE")) and
                   is_binary(v) and v != "" do
                v
              else
                nil
              end
            end)

          # 2) Si no encuentra, usa la primera cadena larga
          img =
            img1 ||
              Enum.find_value(row_map, fn {_k, v} ->
                if is_binary(v) and byte_size(v) > 100 do
                  v
                else
                  nil
                end
              end)

          %{image_data: img}
        end)

      {:error, _reason} ->
        []
    end
  end
end
