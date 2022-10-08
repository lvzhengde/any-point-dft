/*++
Abstract:
  pipeline fft radix-4 unit 1, twiddle factor ROM
--*/

`include "macros.v"
`include "fixed_point.v"

module r4u1_rom(
  rom_addr,
  rom_data
);
  input  [2:0]  rom_addr;
  output [2*`COEF_WIDTH-1:0] rom_data;

`ifdef ASIC
  rom_asic_r4u1 rom_asic_r4u1(
    .rom_addr    (rom_addr),
    .rom_data    (rom_data)
  );
`elsif FPGA
  rom_fpga_r4u1 rom_fpga_r4u1(
    .rom_addr    (rom_addr),
    .rom_data    (rom_data)
  );
`else   //simulation
  wire [2*`COEF_WIDTH-1:0] rom_data;
  reg  [2*`COEF_WIDTH-1:0] rom_mem[7:0];
  reg  [2*`COEF_WIDTH-1:0] twiddle;
  integer rom_file;
  integer bin_file;
  integer rt_code;
  integer i;
  integer temp;
  
  initial
  begin     
    $readmemb(`BIN_ROM_FILE_R4U1, rom_mem); 
    //rom_file = $fopen(`ROM_FILE_R4U1,"r");  
    //bin_file = $fopen(`BIN_ROM_FILE_R4U1);       
    //
    //for (i = 0; i < 8; i = i+1) begin
    //  rt_code = $fscanf(rom_file, "%d", temp);
    //  if (rt_code > 0) begin
    //    twiddle = temp;
    //    rom_mem[i] = twiddle;
    //    $fdisplay(bin_file, "%b", rom_mem[i]); 
    //  end
    //end  
    //
    //$fclose(rom_file);  
    //$fclose(bin_file);
  end

  assign rom_data = rom_mem[rom_addr];
`endif

endmodule
