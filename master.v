module apb_master #(
    parameter ADDR_WIDTH = 8
)(
    input wire PCLK, PRESETn, transfer, READ_WRITE,
    input wire [ADDR_WIDTH-1:0] apb_write_paddr, apb_write_data, apb_read_paddr,
    input wire PREADY,
    input wire [ADDR_WIDTH-1:0] prdata,
    output reg [ADDR_WIDTH-1:0] apb_read_data_out, paddr, pwdata,
    output reg PENABLE, PWRITE, PSEL1, PSLVERR
);

    // State encoding
    parameter IDLE   = 2'b00,
              SETUP  = 2'b01,
              ACCESS = 2'b10;

    reg [1:0] cs, ns; // Current and next state

    // State memory (sequential logic)
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            cs <= IDLE;
        else
            cs <= ns;
    end

    // Next state logic (combinational logic)
    always @(*) begin
        case (cs)
            IDLE: begin
                if (transfer && !PSLVERR)
                    ns = SETUP;
                else
                    ns = IDLE;
            end
            SETUP: begin
                ns = ACCESS;
            end
            ACCESS: begin
                if (PREADY && transfer && !PSLVERR)
                    ns = SETUP;
                else if (PREADY)
                    ns = IDLE;
                else
                    ns = ACCESS;
            end
            default: ns = IDLE;
        endcase
    end

    // Output logic
    always @(*) begin
        if (!PRESETn) begin
            PSEL1   = 0;
            PENABLE = 0;
            PWRITE  = 0;
            pwdata  = 0;
            paddr   = 0;
            apb_read_data_out = 0;
            PSLVERR =0;
        end else begin
            case (cs)
                IDLE: begin
                    PSEL1   = 0;
                    PENABLE = 0;
                    PWRITE  = 0;
                end
                SETUP: begin
                    PSEL1   = 1;
                    PENABLE = 0;
                    PWRITE  = READ_WRITE;
                    pwdata  = apb_write_data;
                    if (READ_WRITE) begin
                        paddr = apb_read_paddr;
                        apb_read_data_out = prdata;
                    end else begin
                        paddr = apb_write_paddr;
                    end
                end
                ACCESS: begin
                    PSEL1   = 1;
                    PENABLE = 1;
                end
            endcase
        end
    end

    // Error detection logic
    reg setup_error, invalid_read_paddr, invalid_write_paddr, invalid_write_data, invalid_setup_error;

    always @(*) begin
        if (!PRESETn) begin
            setup_error = 0;
            invalid_read_paddr = 0;
            invalid_write_paddr = 0;
            invalid_write_data = 0;
        end else begin
            setup_error = 0;
            invalid_read_paddr = 0;
            invalid_write_paddr = 0;
            invalid_write_data = 0;

            if (cs == IDLE && ns == ACCESS)
                setup_error = 1;

            if ((apb_write_data === 8'dx) && (!READ_WRITE) && (cs == SETUP || cs == ACCESS))
                invalid_write_data = 1;

            if ((apb_read_paddr === 8'dx) && READ_WRITE && (cs == SETUP || cs == ACCESS))
                invalid_read_paddr = 1;

            if ((apb_write_paddr === 8'dx) && (!READ_WRITE) && (cs == SETUP || cs == ACCESS))
                invalid_write_paddr = 1;

            if (cs == SETUP) begin
                if (PWRITE) begin
                    if (paddr == apb_write_paddr && pwdata == apb_write_data)
                        setup_error = 0;
                    else
                        setup_error = 1;
                end else begin
                    if (paddr == apb_read_paddr)
                        setup_error = 0;
                    else
                        setup_error = 1;
                end
            end
        end

        invalid_setup_error = setup_error || invalid_read_paddr || invalid_write_data || invalid_write_paddr;
    end

    assign PSLVERR = invalid_setup_error;

endmodule
