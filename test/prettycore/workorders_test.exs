defmodule Prettycore.WorkordersTest do
  use ExUnit.Case, async: false

  alias Prettycore.Workorders
  alias Prettycore.Workorders.WorkorderEnc

  describe "list_enc/0" do
    test "returns a list of WorkorderEnc structs" do
      result = Workorders.list_enc()

      # Verify it returns a list
      assert is_list(result)

      # If there are results, verify the structure
      if length(result) > 0 do
        first_workorder = List.first(result)

        # Verify it's a WorkorderEnc struct
        assert %WorkorderEnc{} = first_workorder

        # Verify it has the expected fields
        assert Map.has_key?(first_workorder, :sysudn)
        assert Map.has_key?(first_workorder, :systra)
        assert Map.has_key?(first_workorder, :serie)
        assert Map.has_key?(first_workorder, :folio)
        assert Map.has_key?(first_workorder, :referencia)
        assert Map.has_key?(first_workorder, :estado)
        assert Map.has_key?(first_workorder, :descripcion)
        assert Map.has_key?(first_workorder, :fecha)
        assert Map.has_key?(first_workorder, :usuario)
      end
    end

    test "returns workorders with valid data types" do
      result = Workorders.list_enc()

      # If there are results, verify the data types
      if length(result) > 0 do
        first_workorder = List.first(result)

        # Verify data types
        assert is_binary(first_workorder.sysudn) or is_nil(first_workorder.sysudn)
        assert is_binary(first_workorder.systra) or is_nil(first_workorder.systra)
        assert is_binary(first_workorder.serie) or is_nil(first_workorder.serie)
        assert is_integer(first_workorder.folio) or is_nil(first_workorder.folio)
        assert is_binary(first_workorder.referencia) or is_nil(first_workorder.referencia)
        assert is_integer(first_workorder.estado) or is_nil(first_workorder.estado)
        assert is_binary(first_workorder.descripcion) or is_nil(first_workorder.descripcion)
        assert is_binary(first_workorder.usuario) or is_nil(first_workorder.usuario)

        # Fecha should be NaiveDateTime or nil
        assert is_nil(first_workorder.fecha) or
                 match?(%NaiveDateTime{}, first_workorder.fecha)
      end
    end

    test "successfully queries the database without errors" do
      # This test verifies that the function executes without raising an error
      result =
        try do
          Workorders.list_enc()
          {:ok, :success}
        rescue
          _error -> {:error, :failed}
        end

      assert {:ok, _} = result
    end
  end
end
