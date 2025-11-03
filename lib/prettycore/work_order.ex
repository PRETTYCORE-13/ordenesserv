defmodule Prettycore.WorkOrder do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "xen_wokorderenc" do
    field(:sysudn_codigo_k, :string)
    field(:systra_codigo_k, :string)
    field(:woke_serie_k, :string)
    field(:woke_folio_k, :integer)
    field(:woke_referencia, :string)
    field(:woktpo_codigo_k, :string)
    field(:woke_descripcion, :string)
    field(:woke_usuario, :string)
    field(:ctecli_codigo_k, :string)
    field(:ctecli_dencomercia, :string)
    field(:systtp_codigo_k, :string)
    field(:systts_codigo_k, :string)
    field(:s_maqedo, :integer)
    field(:s_fecha, :utc_datetime)
    field(:s_fi, :string)
    field(:s_guid, :string)
    field(:s_guidlog, :string)
    field(:s_usuario, :string)
    field(:s_usuariodb, :string)
    field(:s_usuarionot, :string)
    field(:s_guidnot, :string)
  end

  def changeset(wokorderenc, attrs) do
    wokorderenc
    |> cast(attrs, [
      :sysudn_codigo_k,
      :systra_codigo_k,
      :woke_serie_k,
      :woke_folio_k,
      :woke_referencia,
      :woktpo_codigo_k,
      :woke_descripcion,
      :woke_usuario,
      :ctecli_codigo_k,
      :ctecli_dencomercia,
      :systtp_codigo_k,
      :systts_codigo_k,
      :s_maqedo,
      :s_fecha,
      :s_fi,
      :s_guid,
      :s_guidlog,
      :s_usuario,
      :s_usuariodb,
      :s_usuarionot,
      :s_guidnot
    ])
    |> validate_required([
      :sysudn_codigo_k,
      :systra_codigo_k,
      :woke_serie_k,
      :woke_folio_k,
      :woke_referencia,
      :woktpo_codigo_k,
      :woke_descripcion,
      :systtp_codigo_k,
      :s_maqedo,
      :s_fecha
    ])
  end
end
