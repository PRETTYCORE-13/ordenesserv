defmodule Prettycore.Workorders.WorkorderEnc do
  use Ecto.Schema

  @primary_key false
  @schema_prefix "dbo"   # SQL Server usa dbo por defecto

  schema "XEN_WOKORDERENC" do
    field :sysudn,      :string,  source: :"SYSUDN_CODIGO_K"
    field :systra,      :string,  source: :"SYSTRA_CODIGO_K"
    field :serie,       :string,  source: :"WOKE_SERIE_K"
    field :folio,       :string,  source: :"WOKE_FOLIO_K"
    field :referencia,  :string,  source: :"WOKE_REFERENCIA"
    field :tipo,        :string,  source: :"WOKTPO_CODIGO_K"
    field :estado,      :integer, source: :"S_MAQEDO"
    field :descripcion, :string,  source: :"WOKE_DESCRIPCION"
    field :fecha,       :naive_datetime, source: :"S_FECHA"
    field :usuario,     :string,  source: :"WOKE_USUARIO"
  end
end
