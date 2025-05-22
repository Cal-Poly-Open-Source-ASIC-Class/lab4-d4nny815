module memory #(
    parameter WIDTH = 8,
    parameter DEPTH = 4
    )(
    input wclk,
    input we, 
    input wfull, 
    input [WIDTH-1:0] wdata,
    input [DEPTH-1:0] waddr,
    input [DEPTH-1:0] raddr,
    output [WIDTH-1:0] rdata
    );

    logic [WIDTH-1:0] mem [0:2**DEPTH-1];


    always_ff @(posedge wclk) begin
        if (we && !wfull) 
            mem[waddr] <= wdata;
    end

    assign rdata = mem[raddr];

endmodule