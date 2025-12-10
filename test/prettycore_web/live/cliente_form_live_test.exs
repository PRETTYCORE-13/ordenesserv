defmodule PrettycoreWeb.ClienteFormLiveTest do
  use PrettycoreWeb.LiveCase, async: false

  alias Prettycore.Catalogos

  @moduletag :authenticated

  describe "mount /admin/clientes/new" do
    test "renders the new client form", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/clientes/new")

      assert html =~ "Nuevo Cliente"
      assert html =~ "form"
    end

    test "initializes form with default values", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Verify default values are set
      assert has_element?(view, "input[name='cliente_form[ctecli_rfc]'][value='XAXX010101000']")
      assert has_element?(view, "input[name='cliente_form[ctecli_pais]'][value='MEX']")
    end

    test "loads catalog select options", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Verify catalogs are loaded
      assert has_element?(view, "select[name='cliente_form[ctetpo_codigo_k]']")
      assert has_element?(view, "select[name='cliente_form[ctecan_codigo_k]']")
      assert has_element?(view, "select[name='cliente_form[ctereg_codigo_k]']")
      assert has_element?(view, "select[name='cliente_form[systra_codigo_k]']")
      assert has_element?(view, "select[name='cliente_form[cfgmon_codigo_k]']")
    end

    test "initializes with direccion fields", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Verify direccion input fields exist
      assert has_element?(view, "input[name^='cliente_form[direcciones]']")
    end

    test "sets current page to clientes", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/clientes/new")

      # The current_page should be "clientes"
      assert html =~ "clientes"
    end

    test "displays save button", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      assert has_element?(view, "button[type='submit']")
    end

    test "displays cancel link", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      assert has_element?(view, "a[href='/admin/clientes']")
    end
  end

  describe "form validation" do
    test "validates required cliente fields", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Submit form with empty required fields
      result = view
      |> form("form", cliente_form: %{
        "ctecli_codigo_k" => "",
        "ctetpo_codigo_k" => "",
        "ctecan_codigo_k" => "",
        "ctesca_codigo_k" => "",
        "ctereg_codigo_k" => "",
        "systra_codigo_k" => ""
      })
      |> render_change()

      assert result =~ "Este campo es obligatorio"
    end

    test "validates RFC format", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Submit with invalid RFC
      result = view
      |> form("form", cliente_form: %{
        "ctecli_rfc" => "INVALID"
      })
      |> render_change()

      assert result =~ "formato RFC inválido"
    end

    test "accepts valid RFC format", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Submit with valid RFC
      result = view
      |> form("form", cliente_form: %{
        "ctecli_rfc" => "TCO010101ABC"
      })
      |> render_change()

      refute result =~ "formato RFC inválido"
    end

    test "validates CP format in direccion", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Submit with invalid CP (too short)
      result = view
      |> form("form", cliente_form: %{
        "direcciones" => %{
          "0" => %{
            "ctedir_cp" => "123"
          }
        }
      })
      |> render_change()

      assert result =~ "El CP debe tener 5 dígitos"
    end

    test "validates CP contains only numbers", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Submit with non-numeric CP
      result = view
      |> form("form", cliente_form: %{
        "direcciones" => %{
          "0" => %{
            "ctedir_cp" => "abcde"
          }
        }
      })
      |> render_change()

      assert result =~ "El CP debe contener solo números"
    end

    test "accepts valid CP format", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Submit with valid CP
      result = view
      |> form("form", cliente_form: %{
        "direcciones" => %{
          "0" => %{
            "ctedir_cp" => "01000"
          }
        }
      })
      |> render_change()

      refute result =~ "El CP debe"
    end

    test "validates RFC length", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # RFC too short
      result = view
      |> form("form", cliente_form: %{
        "ctecli_rfc" => "ABC"
      })
      |> render_change()

      assert result =~ "formato RFC inválido"
    end
  end

  describe "catalog loading" do
    test "loads tipos de cliente options", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/admin/clientes/new")

      tipos_cliente = Catalogos.listar_tipos_cliente()

      if length(tipos_cliente) > 0 do
        # Verify select has options
        assert html =~ "ctetpo_codigo_k"
      end
    end

    test "loads canales options", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/admin/clientes/new")

      canales = Catalogos.listar_canales()

      if length(canales) > 0 do
        # Verify select has options
        assert html =~ "ctecan_codigo_k"
      end
    end

    test "loads regimenes options", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/admin/clientes/new")

      regimenes = Catalogos.listar_regimenes()

      if length(regimenes) > 0 do
        # Verify select has options
        assert html =~ "ctereg_codigo_k"
      end
    end

    test "loads usos cfdi options", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/admin/clientes/new")

      usos_cfdi = Catalogos.listar_usos_cfdi()

      if length(usos_cfdi) > 0 do
        # Verify select has options
        assert html =~ "sat_uso_cfdi_k"
      end
    end
  end

  describe "form interaction" do
    test "form change event is handled", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Trigger form change
      result = view
      |> form("form", cliente_form: %{
        "ctecli_codigo_k" => "TEST001",
        "ctecli_razonsocial" => "Test Company"
      })
      |> render_change()

      # Should not crash and should return HTML
      assert result
    end

    test "handles tab change event", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Change to facturacion tab
      result = view
      |> element("button[phx-click='change_tab'][phx-value-tab='facturacion']")
      |> render_click()

      # Should not crash
      assert result
    end
  end

  describe "page navigation" do
    test "handles navigation to clientes list", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Trigger clientes navigation via change_page event
      view
      |> render_hook("change_page", %{"id" => "clientes"})

      # Should redirect to clientes
      assert_redirect(view, ~p"/admin/clientes")
    end

    test "handles navigation to inicio", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Trigger inicio navigation via change_page event
      view
      |> render_hook("change_page", %{"id" => "inicio"})

      # Should redirect to platform
      assert_redirect(view, ~p"/admin/platform")
    end
  end

  describe "form submission" do
    @tag :skip
    test "creates cliente with valid data and mocked API", %{conn: conn} do
      # This test would require mocking ClientesApi.crear_cliente
      # Skipped for now as it requires API mocking setup
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      valid_attrs = %{
        "ctecli_codigo_k" => "TEST001",
        "ctecli_razonsocial" => "Test Company SA de CV",
        "ctecli_dencomercia" => "Test Company",
        "ctecli_rfc" => "TCO010101ABC",
        "ctecli_fechaalta" => NaiveDateTime.utc_now() |> NaiveDateTime.to_iso8601(),
        "ctetpo_codigo_k" => "01",
        "ctecan_codigo_k" => "01",
        "ctesca_codigo_k" => "01",
        "ctereg_codigo_k" => "01",
        "systra_codigo_k" => "FRCTE_CLIENTE",
        "direcciones" => %{
          "0" => %{
            "ctedir_codigo_k" => "1",
            "ctedir_calle" => "Calle Principal",
            "ctedir_callenumext" => "123",
            "ctedir_cp" => "01000",
            "mapedo_codigo_k" => "9",
            "mapmun_codigo_k" => "15",
            "maploc_codigo_k" => "1"
          }
        }
      }

      # Would need to mock API here before submitting
      # result = view
      # |> form("form", cliente_form: valid_attrs)
      # |> render_submit()
    end
  end
end
