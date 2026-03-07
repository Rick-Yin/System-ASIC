package l0_case_pkg;

  task automatic l0_report(
    input [8*64-1:0] op_name,
    input int total_cases,
    input int mismatches
  );
    if (mismatches == 0) begin
      $display("[L0][PASS] op=%0s cases=%0d mismatches=%0d", op_name, total_cases, mismatches);
    end else begin
      $display("[L0][FAIL] op=%0s cases=%0d mismatches=%0d", op_name, total_cases, mismatches);
    end
  endtask

endpackage
