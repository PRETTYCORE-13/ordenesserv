defmodule PrettycoreWeb.SysUdnWorkorderLive do
  use PrettycoreWeb, :live_view

  alias Prettycore.EcoreClient

  @impl true
  def mount(params, _session, socket) do
    ref = Map.get(params, "ref", "")

    {result, error} =
      case ref do
        "" ->
          {nil, "No se recibió WOKE_REFERENCIA (param ref)."}

        _ ->
          case EcoreClient.workorder_by_ref(ref) do
            {:ok, body} -> {body, nil}
            {:error, reason} -> {nil, inspect(reason)}
          end
      end

    {:ok,
     socket
     |> assign(ref: ref, result: result, error: error)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pc-wrap">
      <h1 class="pc-title">Workorder {@ref}</h1>
      
      <%= if @error do %>
        <div class="pc-error">Error al consultar la API: {@error}</div>
      <% else %>
        <pre class="pc-json">
    {inspect(@result, pretty: true)}
        </pre>
      <% end %>
       <.link navigate={~p"/ui/sys_udn"} class="pc-btn">Volver a SYS_UDN</.link>
    </div>
    """
  end
end
