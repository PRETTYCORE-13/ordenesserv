defmodule Prettycore.Clientes.Direccion do
  @moduledoc """
  Esquema para CTE_DIRECCION - Direcciones de clientes
  """
  use Ecto.Schema

  @primary_key false
  schema "CTE_DIRECCION" do
    field(:ctecli_codigo_k, :string, primary_key: true)
    field(:ctedir_codigo_k, :string, primary_key: true)
    field(:ctepfr_codigo_k, :string)
    field(:vtarut_codigo_k_pre, :string)
    field(:vtarut_codigo_k_ent, :string)
    field(:vtarut_codigo_k_aut, :string)
    field(:mapedo_codigo_k, :string)
    field(:mapmun_codigo_k, :string)
    field(:maploc_codigo_k, :string)
    field(:map_x, :decimal)
    field(:map_y, :decimal)
    field(:ctedir_calle, :string)
    field(:ctedir_colonia, :string)
    field(:ctedir_callenumext, :string)
    field(:ctedir_callenumint, :string)
    field(:ctedir_telefono, :string)
    field(:ctedir_responsable, :string)
    field(:ctedir_calleentre1, :string)
    field(:ctedir_calleentre2, :string)
    field(:ctedir_cp, :string)

    belongs_to(:cliente, Prettycore.Clientes.Cliente,
      foreign_key: :ctecli_codigo_k,
      references: :ctecli_codigo_k,
      define_field: false
    )

    belongs_to(:patron_frecuencia, Prettycore.Clientes.PatronFrecuencia,
      foreign_key: :ctepfr_codigo_k,
      references: :ctepfr_codigo_k,
      define_field: false
    )

    belongs_to(:estado, Prettycore.Clientes.Estado,
      foreign_key: :mapedo_codigo_k,
      references: :mapedo_codigo_k,
      define_field: false
    )

    belongs_to(:municipio, Prettycore.Clientes.Municipio,
      foreign_key: :mapmun_codigo_k,
      references: :mapmun_codigo_k,
      define_field: false
    )

    belongs_to(:localidad, Prettycore.Clientes.Localidad,
      foreign_key: :maploc_codigo_k,
      references: :maploc_codigo_k,
      define_field: false
    )
  end
end
