module asyn_fifo (
    input wr_clk,
    input rd_clk,
    input rst,
    input wr,
    input rd,
    input [data_width-1:0] wdata,    // Input data width correction
    output reg [data_width-1:0] rdata, // Output data width correction
    output full,
    output empty,
    output reg valid,
    output reg overflow,  // Corrected output type
    output reg underflow
);

parameter data_width = 8;  // Parameter corrected
parameter fifo_depth = 8;
parameter address_size = 4;

reg [address_size-1:0] wr_pointer, wr_pntr_g_s1, wr_pntr_g_s2; 
reg [address_size-1:0] rd_pointer, rd_pntr_g_s1, rd_pntr_g_s2;
reg [data_width-1:0] mem [fifo_depth-1:0];  

// Writing data into FIFO
always @(posedge wr_clk) begin
    if (rst) 
        wr_pointer <= 0;
    else if (wr && !full) begin
        mem[wr_pointer] <= wdata;
        wr_pointer <= wr_pointer + 1;
    end
end

// Reading data from FIFO
always @(posedge rd_clk) begin
    if (rst)
        rd_pointer <= 0;
    else if (rd && !empty) begin
        rdata <= mem[rd_pointer];  // Read operation
        rd_pointer <= rd_pointer + 1;
    end
end

// Binary to Gray conversion for wr_pointer and rd_pointer
wire [address_size-1:0] wr_pntr_g = wr_pointer ^ (wr_pointer >> 1);
wire [address_size-1:0] rd_pntr_g = rd_pointer ^ (rd_pointer >> 1);

// 2-stage synchronizer for wr_pointer with respect to rd_clk
always @(posedge rd_clk) begin
    if (rst) begin
        wr_pntr_g_s1 <= 0;
        wr_pntr_g_s2 <= 0;
    end else begin
        wr_pntr_g_s1 <= wr_pntr_g;  // 1st FF
        wr_pntr_g_s2 <= wr_pntr_g_s1;  // 2nd FF
    end
end

// 2-stage synchronizer for rd_pointer with respect to wr_clk
always @(posedge wr_clk) begin
    if (rst) begin
        rd_pntr_g_s1 <= 0;
        rd_pntr_g_s2 <= 0;
    end else begin
        rd_pntr_g_s1 <= rd_pntr_g;  // 1st FF
        rd_pntr_g_s2 <= rd_pntr_g_s1;  // 2nd FF
    end
end

// Empty condition
assign empty = (rd_pntr_g == wr_pntr_g_s2);

// Full condition
assign full = (wr_pntr_g[address_size-1] != rd_pntr_g_s2[address_size-1]) &&
              (wr_pntr_g[address_size-2] != rd_pntr_g_s2[address_size-2]) &&
              (wr_pntr_g[address_size-3] == rd_pntr_g_s2[address_size-3]);

// Overflow detection
always @(posedge wr_clk) begin
    overflow <= full && wr;
end

// Underflow detection
always @(posedge rd_clk) begin
    underflow <= empty && rd;
    valid <= (rd && !empty);
end

endmodule

