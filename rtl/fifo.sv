module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH  = 4
    ) (
    input reset_n,
    input wclk,
    input we,
    input [WIDTH-1:0] wdata,
    input rclk,
    input re,
    output [WIDTH-1:0] rdata,
    output empty,
    output full
    );

    wire [DEPTH-1:0] waddr, raddr;
    wire [DEPTH:0] wptr, rptr, wq2_rptr, rq2_wptr;

    two_stage_sync #(DEPTH+1) sync_r2w (
        .rst_n  (reset_n),
        .clk    (wclk), 
        .din    (rptr),
        .q2     (wq2_rptr)
    );

    two_stage_sync #(DEPTH+1) sync_w2r (
        .rst_n  (reset_n),
        .clk    (rclk), 
        .din    (wptr),
        .q2     (rq2_wptr)
    );

    memory #(WIDTH, DEPTH) mem (
        .wclk       (wclk),
        .we         (we), 
        .wfull      (full),
        .wdata      (wdata),
        .waddr      (waddr), 
        .raddr      (raddr),
        .rdata      (rdata) 
    );

    rptr_mod #(DEPTH) rptr_mod (
        .rrst_n     (reset_n),
        .rclk       (rclk),
        .rq2_wptr   (rq2_wptr),
        .rinc       (re), 
        .raddr      (raddr),
        .rptr       (rptr), 
        .rempty     (empty)
    );

    wptr_mod #(DEPTH) wptr_mod (
        .wrst_n     (reset_n),
        .wclk       (wclk),
        .winc       (we), 
        .wq2_rptr   (wq2_rptr),
        .waddr      (waddr),
        .wptr       (wptr), 
        .wfull      (full) 
    );

endmodule