defmodule Prettycore.Workorders.WorkorderTipo do
  use Ecto.Schema
  alias Prettycore.Workorders.WorkorderEnc

  @primary_key {:id, :string, source: :"WOKTPO_CODIGO_K"}
  @schema_prefix "dbo"

  schema "XEN_WOKORDERTIPO" do
    field :descripcion, :string, source: :"WOKTPO_DESCRIPCION"

    # Un tipo puede tener muchas órdenes
    belongs_to :orden, WorkorderEnc,
      foreign_key: :"SYSTRA_CODIGO_K",
      define_field: false       # evita crear tipo_id
  end
end
