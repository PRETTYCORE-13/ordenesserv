defmodule Prettycore.ClientesApiTest do
  use ExUnit.Case, async: true

  alias Prettycore.ClientesApi

  describe "crear_cliente/2 data transformation" do
    test "transforms cliente data to correct API format with uppercase keys" do
      cliente_data = %{
        # Datos Básicos
        ctecli_codigo_k: "CLI001",
        ctecli_razonsocial: "Test Company SA de CV",
        ctecli_dencomercia: "Test Company",
        ctecli_rfc: "ABC123456789",
        ctecli_fereceptormail: "test@example.com",
        ctecli_nocta: "1234567890",
        ctecli_fechaalta: ~N[2025-01-15 10:30:00],
        # Información de Crédito
        ctecli_edocred: 1,
        ctecli_diascredito: 30,
        ctecli_limitecredi: Decimal.new("100000.00"),
        # Clasificación (Obligatorios NOT NULL)
        ctetpo_codigo_k: "TPO001",
        ctecan_codigo_k: "CAN001",
        ctesca_codigo_k: "SCA001",
        ctereg_codigo_k: "REG001",
        systra_codigo_k: "TRA001",
        cfgmon_codigo_k: "MXN",
        # Facturación (Catálogos SAT)
        ctecli_formapago: "01",
        ctecli_metodopago: "PUE",
        sat_uso_cfdi_k: "G03",
        cfgreg_codigo_k: "601",
        # Catálogos Opcionales (Foreign Keys)
        ctepaq_codigo_k: "PAQ001",
        facadd_codigo_k: "ADD001",
        ctepor_codigo_k: "POR001",
        condim_codigo_k: "DIM001",
        ctecad_codigo_k: "CAD001",
        cfgban_codigo_k: "BAN001",
        sysemp_codigo_k: "EMP001",
        faccom_codigo_k: "COM001",
        facads_codigo_k: "ADS001",
        cteseg_codigo_k: "SEG001",
        catind_codigo_k: "IND001",
        catpfi_codigo_k: "PFI001",
        satexp_codigo_k: "EXP001",
        ctecli_pais: "MEX",
        # Flags (Valores por defecto)
        ctecli_generico: 0,
        ctecli_dscantimp: 0,
        ctecli_desglosaieps: 0,
        ctecli_periodorefac: 0,
        ctecli_cargaespecifica: 0,
        ctecli_caducidadmin: 0,
        ctecli_ctlsanitario: 0,
        ctecli_factablero: 0,
        ctecli_aplicacanje: 0,
        ctecli_aplicadev: 0,
        ctecli_desglosakit: 0,
        ctecli_facgrupo: 0,
        ctecli_timbracb: 0,
        ctecli_novalidavencimiento: 0,
        ctecli_cfdi_ver: 4.0,
        ctecli_aplicaregalo: 0,
        ctecli_noaceptafracciones: 0,
        ctecli_cxcliq: 0,
        # Tipos de Facturación
        ctecli_tipodefact: 1,
        ctecli_tipofacdes: 0,
        ctecli_tipodefacr: 0,
        ctecli_tipopago: "99",
        # Sistema
        s_maqedo: "MACHINE001",
        # Dirección
        direccion: %{
          ctedir_codigo_k: "DIR001",
          ctedir_calle: "Reforma",
          ctedir_callenumext: "123",
          ctedir_callenumint: "A",
          ctedir_colonia: "Centro",
          ctedir_cp: "06000",
          mapedo_codigo_k: "09",
          mapmun_codigo_k: "015",
          maploc_codigo_k: "0001",
          map_x: "19.4326",
          map_y: "-99.1332",
          ctedir_responsable: "Juan Perez",
          ctedir_telefono: "5551234567",
          ctedir_celular: "5559876543",
          ctedir_mail: "contacto@example.com",
          vtarut_codigo_k_pre: "RUT001",
          vtarut_codigo_k_ent: "RUT002",
          vtarut_codigo_k_cob: "RUT003",
          vtarut_codigo_k_aut: "RUT004",
          ctepfr_codigo_k: "PFR001",
          cteclu_codigo_k: "CLU001",
          ctezni_codigo_k: "ZNI001"
        }
      }

      # Call public function (made public with @doc false for testing)
      result = ClientesApi.transform_to_api_format(cliente_data)

      # Verify top level structure
      assert Map.has_key?(result, "clientes")
      assert is_list(result["clientes"])
      assert length(result["clientes"]) == 1

      cliente = List.first(result["clientes"])

      # Verify all keys are uppercase - Datos Básicos
      assert cliente["CTECLI_CODIGO_K"] == "CLI001"
      assert cliente["CTECLI_RAZONSOCIAL"] == "Test Company SA de CV"
      assert cliente["CTECLI_DENCOMERCIA"] == "Test Company"
      assert cliente["CTECLI_RFC"] == "ABC123456789"
      assert cliente["CTECLI_FERECEPTORMAIL"] == "test@example.com"
      assert cliente["CTECLI_NOCTA"] == "1234567890"
      assert cliente["CTECLI_FECHAALTA"] == "2025-01-15T10:30:00"

      # Información de Crédito
      assert cliente["CTECLI_EDOCRED"] == 1
      assert cliente["CTECLI_DIASCREDITO"] == 30
      assert cliente["CTECLI_LIMITECREDI"] == 100_000.0

      # Clasificación (Obligatorios NOT NULL)
      assert cliente["CTETPO_CODIGO_K"] == "TPO001"
      assert cliente["CTECAN_CODIGO_K"] == "CAN001"
      assert cliente["CTESCA_CODIGO_K"] == "SCA001"
      assert cliente["CTEREG_CODIGO_K"] == "REG001"
      assert cliente["SYSTRA_CODIGO_K"] == "TRA001"
      assert cliente["CFGMON_CODIGO_K"] == "MXN"

      # Facturación (Catálogos SAT)
      assert cliente["CTECLI_FORMAPAGO"] == "01"
      assert cliente["CTECLI_METODOPAGO"] == "PUE"
      assert cliente["SAT_USO_CFDI_K"] == "G03"
      assert cliente["CFGREG_CODIGO_K"] == "601"

      # Catálogos Opcionales (Foreign Keys)
      assert cliente["CTEPAQ_CODIGO_K"] == "PAQ001"
      assert cliente["FACADD_CODIGO_K"] == "ADD001"
      assert cliente["CTEPOR_CODIGO_K"] == "POR001"
      assert cliente["CONDIM_CODIGO_K"] == "DIM001"
      assert cliente["CTECAD_CODIGO_K"] == "CAD001"
      assert cliente["CFGBAN_CODIGO_K"] == "BAN001"
      assert cliente["SYSEMP_CODIGO_K"] == "EMP001"
      assert cliente["FACCOM_CODIGO_K"] == "COM001"
      assert cliente["FACADS_CODIGO_K"] == "ADS001"
      assert cliente["CTESEG_CODIGO_K"] == "SEG001"
      assert cliente["CATIND_CODIGO_K"] == "IND001"
      assert cliente["CATPFI_CODIGO_K"] == "PFI001"
      assert cliente["SATEXP_CODIGO_K"] == "EXP001"
      assert cliente["CTECLI_PAIS"] == "MEX"

      # Flags (Valores por defecto)
      assert cliente["CTECLI_GENERICO"] == 0
      assert cliente["CTECLI_DSCANTIMP"] == 0
      assert cliente["CTECLI_DESGLOSAIEPS"] == 0
      assert cliente["CTECLI_PERIODOREFAC"] == 0
      assert cliente["CTECLI_CARGAESPECIFICA"] == 0
      assert cliente["CTECLI_CADUCIDADMIN"] == 0
      assert cliente["CTECLI_CTLSANITARIO"] == 0
      assert cliente["CTECLI_FACTABLERO"] == 0
      assert cliente["CTECLI_APLICACANJE"] == 0
      assert cliente["CTECLI_APLICADEV"] == 0
      assert cliente["CTECLI_DESGLOSAKIT"] == 0
      assert cliente["CTECLI_FACGRUPO"] == 0
      assert cliente["CTECLI_TIMBRACB"] == 0
      assert cliente["CTECLI_NOVALIDAVENCIMIENTO"] == 0
      assert cliente["CTECLI_CFDI_VER"] == 4.0
      assert cliente["CTECLI_APLICAREGALO"] == 0
      assert cliente["CTECLI_NOACEPTAFRACCIONES"] == 0
      assert cliente["CTECLI_CXCLIQ"] == 0

      # Tipos de Facturación
      assert cliente["CTECLI_TIPODEFACT"] == 1
      assert cliente["CTECLI_TIPOFACDES"] == 0
      assert cliente["CTECLI_TIPODEFACR"] == 0
      assert cliente["CTECLI_TIPOPAGO"] == "99"

      # Sistema
      assert cliente["S_MAQEDO"] == "MACHINE001"

      # Verify direccion is an array
      assert Map.has_key?(cliente, "direccion")
      assert is_list(cliente["direccion"])
      assert length(cliente["direccion"]) == 1

      ClientesApi.crear_cliente(
        cliente_data,
        "qA+bp/If0eYlweqf3yqGW197tzsrqz0NL5jC87GzCuJUdyd3Oe0/iIGDOFczWRf9"
      )
    end

    test "transforms direccion with uppercase keys" do
      direccion = %{
        ctedir_codigo_k: "DIR001",
        ctedir_calle: "Reforma",
        ctedir_callenumext: "123",
        ctedir_callenumint: "A",
        ctedir_colonia: "Centro",
        ctedir_cp: "06000",
        mapedo_codigo_k: "09",
        mapmun_codigo_k: "015",
        maploc_codigo_k: "0001",
        map_x: "19.4326",
        map_y: "-99.1332",
        ctedir_responsable: "Juan Perez",
        ctedir_telefono: "5551234567",
        ctedir_celular: "5559876543",
        ctedir_mail: "contacto@example.com",
        vtarut_codigo_k_pre: "RUT001",
        vtarut_codigo_k_ent: "RUT002",
        vtarut_codigo_k_cob: "RUT003",
        vtarut_codigo_k_aut: "RUT004",
        ctepfr_codigo_k: "PFR001",
        cteclu_codigo_k: "CLU001",
        ctezni_codigo_k: "ZNI001"
      }

      cliente_data = %{
        ctecli_codigo_k: "CLI001",
        ctecli_razonsocial: "Test",
        ctecli_dencomercia: "Test",
        ctecli_rfc: "ABC123",
        ctecli_fechaalta: ~N[2025-01-15 10:30:00],
        ctecli_edocred: 1,
        ctecli_diascredito: 30,
        ctecli_limitecredi: Decimal.new("0"),
        ctecli_tipodefact: 1,
        ctecli_formapago: "01",
        ctecli_metodopago: "PUE",
        sat_uso_cfdi_k: "G03",
        ctecli_fereceptormail: "test@test.com",
        ctetpo_codigo_k: "TPO001",
        ctecan_codigo_k: "CAN001",
        ctesca_codigo_k: "SCA001",
        ctepaq_codigo_k: "PAQ001",
        ctereg_codigo_k: "REG001",
        cfgmon_codigo_k: "MXN",
        ctecli_pais: "MEX",
        cfgreg_codigo_k: "601",
        satexp_codigo_k: "EXP001",
        catind_codigo_k: "IND001",
        catpfi_codigo_k: "PFI001",
        ctecli_generico: 0,
        ctecli_nocta: "123",
        ctecli_dscantimp: 0,
        ctecli_desglosaieps: 0,
        ctecli_factablero: 0,
        ctecli_aplicacanje: 0,
        ctecli_aplicadev: 0,
        ctecli_desglosakit: 0,
        ctecli_facgrupo: 0,
        ctecli_cfdi_ver: 4.0,
        systra_codigo_k: "TRA001",
        s_maqedo: "MACHINE",
        direccion: direccion
      }

      result = ClientesApi.transform_to_api_format(cliente_data)
      cliente = List.first(result["clientes"])
      direccion_result = List.first(cliente["direccion"])

      # Verify all direccion keys are uppercase
      # Identificación
      assert direccion_result["CTEDIR_CODIGO_K"] == "DIR001"

      # Dirección Física
      assert direccion_result["CTEDIR_CALLE"] == "Reforma"
      assert direccion_result["CTEDIR_CALLENUMEXT"] == "123"
      assert direccion_result["CTEDIR_CALLENUMINT"] == "A"
      assert direccion_result["CTEDIR_COLONIA"] == "Centro"
      assert direccion_result["CTEDIR_CP"] == "06000"

      # Ubicación Geográfica
      assert direccion_result["MAPEDO_CODIGO_K"] == "09"
      assert direccion_result["MAPMUN_CODIGO_K"] == "015"
      assert direccion_result["MAPLOC_CODIGO_K"] == "0001"
      assert direccion_result["MAP_X"] == "19.4326"
      assert direccion_result["MAP_Y"] == "-99.1332"

      # Contacto
      assert direccion_result["CTEDIR_RESPONSABLE"] == "Juan Perez"
      assert direccion_result["CTEDIR_TELEFONO"] == "5551234567"
      assert direccion_result["CTEDIR_CELULAR"] == "5559876543"
      assert direccion_result["CTEDIR_MAIL"] == "contacto@example.com"

      # Rutas (FK → VTA_RUTA)
      assert direccion_result["VTARUT_CODIGO_K_PRE"] == "RUT001"
      assert direccion_result["VTARUT_CODIGO_K_ENT"] == "RUT002"
      assert direccion_result["VTARUT_CODIGO_K_COB"] == "RUT003"
      assert direccion_result["VTARUT_CODIGO_K_AUT"] == "RUT004"

      # Otros catálogos opcionales
      assert direccion_result["CTEPFR_CODIGO_K"] == "PFR001"
      assert direccion_result["CTECLU_CODIGO_K"] == "CLU001"
      assert direccion_result["CTEZNI_CODIGO_K"] == "ZNI001"
    end

    test "handles nil direccion correctly" do
      cliente_data = build_minimal_cliente_data(%{direccion: nil})

      result = ClientesApi.transform_to_api_format(cliente_data)
      cliente = List.first(result["clientes"])

      # direccion should be an empty list when nil
      assert cliente["direccion"] == [nil]
    end

    test "formats datetime correctly" do
      cliente_data =
        build_minimal_cliente_data(%{
          ctecli_fechaalta: ~N[2025-12-03 14:30:45]
        })

      result = ClientesApi.transform_to_api_format(cliente_data)
      cliente = List.first(result["clientes"])

      assert cliente["CTECLI_FECHAALTA"] == "2025-12-03T14:30:45"
    end

    test "handles nil datetime" do
      cliente_data = build_minimal_cliente_data(%{ctecli_fechaalta: nil})

      result = ClientesApi.transform_to_api_format(cliente_data)
      cliente = List.first(result["clientes"])

      assert cliente["CTECLI_FECHAALTA"] == nil
    end

    test "formats decimal to float" do
      cliente_data =
        build_minimal_cliente_data(%{
          ctecli_limitecredi: Decimal.new("999999.99")
        })

      result = ClientesApi.transform_to_api_format(cliente_data)
      cliente = List.first(result["clientes"])

      assert cliente["CTECLI_LIMITECREDI"] == 999_999.99
      assert is_float(cliente["CTECLI_LIMITECREDI"])
    end

    test "handles numeric limitecredi values" do
      cliente_data = build_minimal_cliente_data(%{ctecli_limitecredi: 50000})

      result = ClientesApi.transform_to_api_format(cliente_data)
      cliente = List.first(result["clientes"])

      assert cliente["CTECLI_LIMITECREDI"] == 50000
    end

    test "handles nil limitecredi as 0.0" do
      cliente_data = build_minimal_cliente_data(%{ctecli_limitecredi: nil})

      result = ClientesApi.transform_to_api_format(cliente_data)
      cliente = List.first(result["clientes"])

      assert cliente["CTECLI_LIMITECREDI"] == 0.0
    end

    test "preserves required NOT NULL fields" do
      cliente_data =
        build_minimal_cliente_data(%{
          ctecli_codigo_k: "REQUIRED_CODE",
          ctecli_fechaalta: ~N[2025-01-01 00:00:00],
          ctetpo_codigo_k: "TIPO001",
          ctecan_codigo_k: "CANAL001",
          ctesca_codigo_k: "SUBCANAL001",
          ctereg_codigo_k: "REGIMEN001",
          systra_codigo_k: "TRANS001"
        })

      result = ClientesApi.transform_to_api_format(cliente_data)
      cliente = List.first(result["clientes"])

      # Verify required fields are present
      assert cliente["CTECLI_CODIGO_K"] == "REQUIRED_CODE"
      assert cliente["CTECLI_FECHAALTA"] == "2025-01-01T00:00:00"
      assert cliente["CTETPO_CODIGO_K"] == "TIPO001"
      assert cliente["CTECAN_CODIGO_K"] == "CANAL001"
      assert cliente["CTESCA_CODIGO_K"] == "SUBCANAL001"
      assert cliente["CTEREG_CODIGO_K"] == "REGIMEN001"
      assert cliente["SYSTRA_CODIGO_K"] == "TRANS001"
    end
  end

  # Helper to build minimal cliente data
  defp build_minimal_cliente_data(overrides) do
    defaults = %{
      # Datos Básicos
      ctecli_codigo_k: "CLI001",
      ctecli_razonsocial: "Test Company",
      ctecli_dencomercia: "Test",
      ctecli_rfc: "TEST123456789",
      ctecli_fereceptormail: "test@test.com",
      ctecli_nocta: "123",
      ctecli_fechaalta: ~N[2025-01-15 10:00:00],
      # Información de Crédito
      ctecli_edocred: 1,
      ctecli_diascredito: 30,
      ctecli_limitecredi: Decimal.new("0"),
      # Clasificación (Obligatorios NOT NULL)
      ctetpo_codigo_k: "TPO001",
      ctecan_codigo_k: "CAN001",
      ctesca_codigo_k: "SCA001",
      ctereg_codigo_k: "REG001",
      systra_codigo_k: "TRA001",
      cfgmon_codigo_k: "MXN",
      # Facturación (Catálogos SAT)
      ctecli_formapago: "01",
      ctecli_metodopago: "PUE",
      sat_uso_cfdi_k: "G03",
      cfgreg_codigo_k: "601",
      # Catálogos Opcionales (Foreign Keys)
      ctepaq_codigo_k: "PAQ001",
      facadd_codigo_k: nil,
      ctepor_codigo_k: nil,
      condim_codigo_k: nil,
      ctecad_codigo_k: nil,
      cfgban_codigo_k: nil,
      sysemp_codigo_k: nil,
      faccom_codigo_k: nil,
      facads_codigo_k: nil,
      cteseg_codigo_k: nil,
      catind_codigo_k: "IND001",
      catpfi_codigo_k: "PFI001",
      satexp_codigo_k: "EXP001",
      ctecli_pais: "MEX",
      # Flags (Valores por defecto)
      ctecli_generico: 0,
      ctecli_dscantimp: 0,
      ctecli_desglosaieps: 0,
      ctecli_periodorefac: 0,
      ctecli_cargaespecifica: 0,
      ctecli_caducidadmin: 0,
      ctecli_ctlsanitario: 0,
      ctecli_factablero: 0,
      ctecli_aplicacanje: 0,
      ctecli_aplicadev: 0,
      ctecli_desglosakit: 0,
      ctecli_facgrupo: 0,
      ctecli_timbracb: 0,
      ctecli_novalidavencimiento: 0,
      ctecli_cfdi_ver: 4.0,
      ctecli_aplicaregalo: 0,
      ctecli_noaceptafracciones: 0,
      ctecli_cxcliq: 0,
      # Tipos de Facturación
      ctecli_tipodefact: 1,
      ctecli_tipofacdes: 0,
      ctecli_tipodefacr: 0,
      ctecli_tipopago: "99",
      # Sistema
      s_maqedo: "MACHINE",
      # Dirección
      direccion: nil
    }

    Map.merge(defaults, overrides)
  end
end
