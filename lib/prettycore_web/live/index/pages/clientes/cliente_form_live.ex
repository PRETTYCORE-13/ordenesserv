defmodule PrettycoreWeb.ClienteFormLive do
  use PrettycoreWeb, :live_view_admin

  alias Prettycore.ClientesApi
  alias Prettycore.Auth.User
  alias Prettycore.Repo
  import Ecto.Query

  # Esquema embedded para Dirección
  defmodule DireccionForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :ctedir_codigo_k, :string, default: "1"
      field :ctedir_responsable, :string
      field :ctedir_telefono, :string
      field :ctedir_calle, :string
      field :ctedir_callenumext, :string
      field :ctedir_callenumint, :string
      field :ctedir_colonia, :string
      field :ctedir_cp, :string
      field :ctedir_celular, :string
      field :ctedir_mail, :string

      # Ubicación
      field :mapedo_codigo_k, :integer
      field :mapmun_codigo_k, :integer
      field :maploc_codigo_k, :integer
      field :map_x, :string
      field :map_y, :string

      # Rutas
      field :vtarut_codigo_k_pre, :string
      field :vtarut_codigo_k_ent, :string
      field :vtarut_codigo_k_aut, :string

      # Configuración
      field :ctepfr_codigo_k, :string, default: "D"
      field :cteclu_codigo_k, :string, default: "100"
      field :ctezni_codigo_k, :string, default: "100"
    end

    def changeset(direccion, attrs) do
      direccion
      |> cast(attrs, [
        :ctedir_codigo_k, :ctedir_responsable, :ctedir_telefono,
        :ctedir_calle, :ctedir_callenumext, :ctedir_callenumint,
        :ctedir_colonia, :ctedir_cp, :ctedir_celular, :ctedir_mail,
        :mapedo_codigo_k, :mapmun_codigo_k, :maploc_codigo_k,
        :map_x, :map_y, :vtarut_codigo_k_pre, :vtarut_codigo_k_ent,
        :vtarut_codigo_k_aut, :ctepfr_codigo_k, :cteclu_codigo_k,
        :ctezni_codigo_k
      ])
      |> validate_required([
        :ctedir_calle, :ctedir_cp, :vtarut_codigo_k_pre,
        :vtarut_codigo_k_ent
      ])
      |> validate_length(:ctedir_cp, min: 5, max: 5)
    end
  end

  # Esquema embedded para Cliente
  defmodule ClienteForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      # Identificación (requeridos)
      field :ctecli_codigo_k, :string
      field :ctecli_razonsocial, :string
      field :ctecli_dencomercia, :string
      field :ctecli_rfc, :string, default: "XAXX010101000"

      # Fechas
      field :ctecli_fechaalta, :naive_datetime

      # Crédito
      field :ctecli_edocred, :integer, default: 0
      field :ctecli_diascredito, :integer, default: 0
      field :ctecli_limitecredi, :decimal, default: Decimal.new("0.00")

      # Facturación
      field :ctecli_tipodefact, :integer, default: 2
      field :ctecli_formapago, :string, default: "01"
      field :ctecli_metodopago, :string, default: "PUE"
      field :sat_uso_cfdi_k, :string, default: "S01"
      field :ctecli_fereceptormail, :string

      # Catálogos (con valores por defecto)
      field :ctetpo_codigo_k, :integer, default: 100
      field :ctecan_codigo_k, :string, default: "100"
      field :ctesca_codigo_k, :string, default: "100"
      field :ctepaq_codigo_k, :string, default: "100"
      field :ctereg_codigo_k, :string, default: "101"
      field :cfgmon_codigo_k, :string, default: "MXN"
      field :ctecli_pais, :string, default: "MEX"
      field :cfgreg_codigo_k, :string, default: "616"
      field :satexp_codigo_k, :string, default: "01"
      field :catind_codigo_k, :string, default: "3"
      field :catpfi_codigo_k, :string, default: "1"

      # Flags (valores por defecto)
      field :ctecli_generico, :integer, default: 1
      field :ctecli_nocta, :integer, default: 1
      field :ctecli_dscantimp, :integer, default: 1
      field :ctecli_desglosaieps, :integer, default: 0
      field :ctecli_factablero, :integer, default: 1
      field :ctecli_aplicacanje, :integer, default: 0
      field :ctecli_aplicadev, :integer, default: 0
      field :ctecli_desglosakit, :integer, default: 0
      field :ctecli_facgrupo, :integer, default: 0
      field :ctecli_cfdi_ver, :integer, default: 1

      # Sistema (valores automáticos)
      field :systra_codigo_k, :string, default: "FRCTE_CLIENTE"
      field :s_maqedo, :integer, default: 10

      # Dirección embebida
      embeds_one :direccion, DireccionForm
    end

    def changeset(cliente, attrs) do
      cliente
      |> cast(attrs, [
        :ctecli_codigo_k, :ctecli_razonsocial, :ctecli_dencomercia,
        :ctecli_rfc, :ctecli_fechaalta, :ctecli_edocred,
        :ctecli_diascredito, :ctecli_limitecredi, :ctecli_tipodefact,
        :ctecli_formapago, :ctecli_metodopago, :sat_uso_cfdi_k,
        :ctecli_fereceptormail, :ctetpo_codigo_k, :ctecan_codigo_k,
        :ctesca_codigo_k, :ctepaq_codigo_k, :ctereg_codigo_k,
        :cfgmon_codigo_k, :ctecli_pais, :cfgreg_codigo_k,
        :satexp_codigo_k, :catind_codigo_k, :catpfi_codigo_k
      ])
      |> cast_embed(:direccion, required: true)
      |> validate_required([
        :ctecli_codigo_k, :ctecli_razonsocial, :ctecli_dencomercia,
        :ctecli_rfc
      ])
      |> validate_length(:ctecli_rfc, min: 12, max: 13)
      |> validate_format(:ctecli_rfc, ~r/^[A-Z&Ñ]{3,4}\d{6}[A-Z0-9]{3}$/,
        message: "formato RFC inválido"
      )
    end
  end

  @impl true
  def mount(_params, session, socket) do
    # Crear cliente con valores por defecto
    cliente = %ClienteForm{
      ctecli_fechaalta: NaiveDateTime.utc_now(),
      direccion: %DireccionForm{}
    }

    form = to_form(ClienteForm.changeset(cliente, %{}))

    {:ok,
     socket
     |> assign(:current_page, "clientes")
     |> assign(:sidebar_open, true)
     |> assign(:show_programacion_children, false)
     |> assign(:current_user_email, session["user_email"])
     |> assign(:current_path, "/admin/clientes/new")
     |> assign(:form, form)
     |> assign(:page_title, "Nuevo Cliente")}
  end

  @impl true
  def handle_event("validate", %{"cliente_form" => params}, socket) do
    changeset =
      %ClienteForm{}
      |> ClienteForm.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"cliente_form" => params}, socket) do
    changeset = ClienteForm.changeset(%ClienteForm{}, params)

    case validate_and_extract(changeset) do
      {:ok, cliente_data} ->
        # Get user password for API authentication
        sysusr_codigo = socket.assigns.current_user_email

        password_query =
          from(u in User,
            where: u.sysusr_codigo_k == ^sysusr_codigo,
            select: u.sysusr_password
          )

        case Repo.one(password_query) do
          nil ->
            {:noreply,
             socket
             |> put_flash(:error, "No se pudo autenticar. Intente de nuevo.")
             |> assign(:form, to_form(changeset))}

          password ->
            # Call API to create cliente
            case ClientesApi.crear_cliente(cliente_data, password) do
              {:ok, _response} ->
                {:noreply,
                 socket
                 |> put_flash(:info, "Cliente creado exitosamente")
                 |> push_navigate(to: ~p"/admin/clientes")}

              {:error, {:http_error, status, body}} ->
                error_msg = extract_error_message(body, status)

                {:noreply,
                 socket
                 |> put_flash(:error, "Error al crear cliente: #{error_msg}")
                 |> assign(:form, to_form(changeset))}

              {:error, reason} ->
                {:noreply,
                 socket
                 |> put_flash(:error, "Error de conexión: #{inspect(reason)}")
                 |> assign(:form, to_form(changeset))}
            end
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("change_page", %{"id" => id}, socket) do
    case id do
      "toggle_sidebar" ->
        {:noreply, Phoenix.Component.update(socket, :sidebar_open, &(not &1))}

      "inicio" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/platform")}

      "clientes" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/clientes")}

      _ ->
        {:noreply, socket}
    end
  end

  defp validate_and_extract(changeset) do
    if changeset.valid? do
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    else
      {:error, changeset}
    end
  end

  defp extract_error_message(body, status) when is_map(body) do
    cond do
      Map.has_key?(body, "error") -> body["error"]
      Map.has_key?(body, "message") -> body["message"]
      true -> "Error HTTP #{status}"
    end
  end

  defp extract_error_message(_body, status), do: "Error HTTP #{status}"
end
