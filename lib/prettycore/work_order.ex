defmodule Prettycore.WorkOrder do
  use Ecto.Schema

  @primary_key false
  @schema_prefix "dbo"

  schema "XEN_WOKORDERENC" do
    field :sysudn_codigo_k, :string, source: :"SYSUDN_CODIGO_K"
    field :systra_codigo_k, :string, source: :"SYSTRA_CODIGO_K"
    field :woke_serie_k,   :string,  source: :"WOKE_SERIE_K"
    field :woke_folio_k,   :integer, source: :"WOKE_FOLIO_K"

    field :woke_referencia, :string, source: :"WOKE_REFERENCIA"
    field :woktpo_codigo_k, :string, source: :"WOKTPO_CODIGO_K"

    field :woke_descripcion,  :string,         source: :"WOKE_DESCRIPCION"
  end
end
