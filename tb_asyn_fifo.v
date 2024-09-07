module tb_asyn_fifo;

    // Parameters
    parameter DATA_WIDTH = 8;
    parameter FIFO_DEPTH = 8;
    parameter ADDRESS_SIZE = 4;

    // Testbench signals
    reg wr_clk;
    reg rd_clk;
    reg rst;
    reg wr;
    reg rd;
    reg [DATA_WIDTH-1:0] wdata;
    wire [DATA_WIDTH-1:0] rdata;
    wire full;
    wire empty;
    wire valid;
    wire overflow;
    wire underflow;

    // Instantiate the FIFO module
    asyn_fifo #(
        .data_width(DATA_WIDTH),
        .fifo_depth(FIFO_DEPTH),
        .address_size(ADDRESS_SIZE)
    ) fifo (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .rst(rst),
        .wr(wr),
        .rd(rd),
        .wdata(wdata),
        .rdata(rdata),
        .full(full),
        .empty(empty),
        .valid(valid),
        .overflow(overflow),
        .underflow(underflow)
    );

    // Clock generation
    initial begin
        wr_clk = 0;
        rd_clk = 0;
        forever #5 wr_clk = ~wr_clk; // 10-time unit period for write clock
    end

    initial begin
        forever #7 rd_clk = ~rd_clk; // 14-time unit period for read clock
    end

    // VCD file generation
    initial begin
        $dumpfile("fifo_test.vcd"); // VCD file name
        $dumpvars(0, tb_asyn_fifo); // Dump all variables in this module
    end

    // Testbench stimulus
    initial begin
        // Initialize signals
        rst = 1;
        wr = 0;
        rd = 0;
        wdata = 0;

        // Apply reset
        #10 rst = 0;
        #10;

        // Test Case 1: Fill FIFO completely
        $display("Test Case 1: Fill FIFO");
        repeat (FIFO_DEPTH) begin
            #10 wr = 1; wdata = $random;
        end
        #10 wr = 0; wdata = 0;

        // Test Case 2: Try to write when FIFO is full
        $display("Test Case 2: Write when FIFO is full");
        #10;
        wr = 1; wdata = $random;
        #10 wr = 0; wdata = 0;

        // Test Case 3: Read FIFO until it is empty
        $display("Test Case 3: Empty FIFO");
        repeat (FIFO_DEPTH) begin
            #10 rd = 1;
        end
        #10 rd = 0;

        // Test Case 4: Try to read when FIFO is empty
        $display("Test Case 4: Read when FIFO is empty");
        #10;
        rd = 1;
        #10 rd = 0;

        // Test Case 5: Alternate write and read operations
        $display("Test Case 5: Alternate write and read operations");
        repeat (FIFO_DEPTH / 2) begin
            #10 wr = 1; wdata = $random;
            #10 wr = 0; wdata = 0;
            #10 rd = 1;
            #10 rd = 0;
        end

        // Test Case 6: Fill FIFO, then read and write simultaneously
        $display("Test Case 6: Fill FIFO, then read and write simultaneously");
        repeat (FIFO_DEPTH) begin
            #10 wr = 1; wdata = $random;
        end
        #10 wr = 0; wdata = 0;

        // Simultaneously read and write
        #10 rd = 1;
        #10 rd = 0;
        repeat (FIFO_DEPTH) begin
            #10 wr = 1; wdata = $random;
            #10 rd = 1;
            #10 wr = 0; wdata = 0;
            #10 rd = 0;
        end

        // Test Case 7: Long run test with random operations
        $display("Test Case 7: Long run test with random operations");
        repeat (50) begin
            #10 wr = $random % 2; // Randomly enable or disable write
            wdata = $random;
            #10 rd = $random % 2; // Randomly enable or disable read
        end

        // End simulation
        #100;
        $finish;
    end

    // Monitor FIFO memory contents
    initial begin
        // Display initial state
        $monitor("Time: %0t | wr: %b | rd: %b | FIFO Memory: %h %h %h %h %h %h %h %h | Full: %b | Empty: %b | Valid: %b | Overflow: %b | Underflow: %b",
                 $time,
                 wr, rd,
                 fifo.mem[0], fifo.mem[1], fifo.mem[2], fifo.mem[3],
                 fifo.mem[4], fifo.mem[5], fifo.mem[6], fifo.mem[7],
                 full, empty, valid, overflow, underflow);
    end

endmodule
