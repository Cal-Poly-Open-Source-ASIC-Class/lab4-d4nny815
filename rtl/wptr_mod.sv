module wptr_mod #(
    parameter DEPTH = 4
    )(
    input wrst_n,
    input wclk,
    input winc,
    input [DEPTH:0] wq2_rptr,
    output logic wfull,
    output logic [DEPTH-1:0] waddr,
    output logic [DEPTH:0] wptr
    );

    logic [DEPTH:0] wbin;
    logic [DEPTH:0] wgray_next, wbin_next;
    logic wfull_val;
    
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wbin <= 0;
            wptr <= 0;
            wfull <= 0;
        end
        else begin
            wbin <= wbin_next;
            wptr <= wgray_next;
            wfull <= wfull_val;
        end
    end

    always_comb begin
        waddr = wbin[DEPTH-1:0];
        wbin_next = !wfull ? wbin + {{DEPTH-1{1'b0}}, winc} : wbin;
        wgray_next = wbin_next ^ (wbin_next >> 1);

        wfull_val = ((wgray_next[DEPTH] != wq2_rptr[DEPTH] ) &&
                     (wgray_next[DEPTH-1] != wq2_rptr[DEPTH-1]) &&
                     (wgray_next[DEPTH-2:0] == wq2_rptr[DEPTH-2:0]));
    end
endmodule