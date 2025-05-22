module rptr_mod #(
    parameter DEPTH = 4
    )(
    input rrst_n,
    input rclk, 
    input rinc, 
    input [DEPTH:0] rq2_wptr,
    output logic [DEPTH-1:0] raddr,
    output logic [DEPTH:0] rptr,
    output logic rempty
    );

    logic [DEPTH:0] rbin;
    logic [DEPTH:0] rgrey_next, rbin_next;
    logic rempty_val;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rbin <= 0;
            rptr <= 0;
            rempty <= 1'b1;
        end
        else begin
            rbin <= rbin_next;
            rptr <= rgrey_next;
            rempty <= rempty_val;
        end
    end

    always_comb begin
        raddr = rbin[DEPTH-1:0];
        rbin_next = !rempty ? rbin + {{DEPTH-1{1'b0}}, rinc} : rbin;
        rgrey_next = (rbin_next >> 1) ^ rbin_next;
        
        rempty_val = (rgrey_next == rq2_wptr);
    end

endmodule