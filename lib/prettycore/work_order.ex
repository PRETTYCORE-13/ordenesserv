defmodule Prettycore.WorkOrder do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "XEN_WOKORDERENC" do
    field(:sysudn_codigo_k, :string, source: :SYSUDN_CODIGO_K)
    field(:systra_codigo_k, :string, source: :SYSTRA_CODIGO_K)
    field(:woke_serie_k, :string, source: :WOKE_SERIE_K)
    field(:woke_folio_k, :integer, source: :WOKE_FOLIO_K)
    field(:woke_referencia, :string, source: :WOKE_REFERENCIA)
    field(:woktpo_codigo_k, :string, source: :WOKTPO_CODIGO_K)
    field(:woke_descripcion, :string, source: :WOKE_DESCRIPCION)
    field(:woke_usuario, :string, source: :WOKE_USUARIO)
    field(:ctecli_codigo_k, :string, source: :CTECLI_CODIGO_K)
    field(:ctecli_dencomercia, :string, source: :CTECLI_DENCOMERCIA)
    field(:systtp_codigo_k, :string, source: :SYSTTP_CODIGO_K)
    field(:systts_codigo_k, :string, source: :SYSTTS_CODIGO_K)
    field(:s_maqedo, :integer, source: :S_MAQEDO)
    field(:s_fecha, :naive_datetime, source: :S_FECHA)
    field(:s_fi, :string, source: :S_FI)
    field(:s_guid, :string, source: :S_GUID)
    field(:s_guidlog, :string, source: :S_GUIDLOG)
    field(:s_usuario, :string, source: :S_USUARIO)
    field(:s_usuariodb, :string, source: :S_USUARIODB)
    field(:s_usuarionot, :string, source: :S_USUARIONOT)
    field(:s_guidnot, :string, source: :S_GUIDNOT)
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
