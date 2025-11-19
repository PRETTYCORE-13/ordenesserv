defmodule Prettycore.Workorders.WorkorderEnc do
  use Ecto.Schema
  alias Prettycore.Workorders.WorkorderTipo

  @schema_prefix "dbo"
  @primary_key false

  schema "XEN_WOKORDERENC" do
    field :sysudn,     :string,  source: :"SYSUDN_CODIGO_K"
    field :systra,     :string,  source: :"SYSTRA_CODIGO_K"
    field :serie,      :string,  source: :"WOKE_SERIE_K"
    field :folio,      :integer, source: :"WOKE_FOLIO_K"
    field :referencia, :string,  source: :"WOKE_REFERENCIA"

    belongs_to :tipo, WorkorderTipo,
      foreign_key: :"WOKTPO_CODIGO_K",
      references: :id,
      define_field: false

    field :estado,      :integer, source: :"S_MAQEDO"
    field :descripcion, :string,  source: :"WOKE_DESCRIPCION"
    field :fecha,       :naive_datetime, source: :"S_FECHA"
    field :usuario,     :string,  source: :"WOKE_USUARIO"
  end
end
