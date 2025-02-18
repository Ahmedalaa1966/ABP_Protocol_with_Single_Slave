module ABP_Slave (
    input PCLK,PRESETn,PWRITE
    input PSEL1,PENABLE,
    input [7:0] paddr ,pwdata,
    output [7:0] prdata,
    output PREADY 
);

   reg [7:0] mem [0:63] ;
   always @(*) begin
    if(!PRESETn)
     prdata = 0;
    else if(PSEL1 && !PENABLE)
     PREADY= 0 ;
    else if(PSEL1 && PENABLE && READ_WRITE) begin
     prdata = mem[paddr] ;
     PREADY = 1 ;
    end
    else if(PSEL1 && PENABLE && !READ_WRITE) begin 
     mem[paddr] = pwdata ;
     PREADY = 1
    end
    else 
     PREADY = 0 ;
   end




endmodule