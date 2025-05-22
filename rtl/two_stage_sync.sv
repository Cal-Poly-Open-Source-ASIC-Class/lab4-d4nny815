module two_stage_sync #(
    parameter WIDTH = 4
    )( 
    input rst_n,
    input clk,
    input [WIDTH-1:0] din,
    output logic [WIDTH-1:0] q2
    );

    logic [WIDTH-1:0] q1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q1 <= 0;
            q2 <= 0;
        end
        else begin
            q2 <= q1;
            q1 <= din;
        end 
    end 

endmodule