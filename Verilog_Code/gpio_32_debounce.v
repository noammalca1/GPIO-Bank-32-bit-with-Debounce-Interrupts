module gpio_32_debounce (
    input  wire        PCLK,
    input  wire        PRESETn,

    // Synchronized input from gpio_pins (after 2FF)
    input  wire [31:0] sync_gpio_in,

    // Debounce time in clock cycles (0 = no debounce)
    input  wire [15:0] debounce_cfg,

    // Clean, debounced version of the input (safe for logic / CPU)
    output reg  [31:0] debounced_gpio_in
);

    // -------------------------------------------------------------------
    // Per-bit counters to measure stability duration.
    // counter[i] increments while sync_gpio_in[i] != debounced_gpio_in[i].
    // Once stable long enough (>= debounce_cfg), the bit is updated.
    // -------------------------------------------------------------------
    reg [15:0] counter [0:31];

    integer i;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            // Reset: clear debounced output and counters
            debounced_gpio_in <= 32'h0000_0000;

            for (i = 0; i < 32; i = i + 1)
                counter[i] <= 16'h0000;

        end else begin
            // For each of the 32 GPIO bits independently
            for (i = 0; i < 32; i = i + 1) begin

                // No debounce mode (pass-through)
                if (debounce_cfg == 16'h0000) begin
                    debounced_gpio_in[i] <= sync_gpio_in[i];
                    counter[i]           <= 16'h0000;
                end

                else begin
                    // If stable (same as debounced output) → reset counter
                    if (sync_gpio_in[i] == debounced_gpio_in[i]) begin
                        counter[i] <= 16'h0000;
                    end

                    // If unstable (different from debounced output)
                    else begin
                        // Count how long it stays different
                        if (counter[i] >= debounce_cfg) begin
                            // Accept new value after stability
                            debounced_gpio_in[i] <= sync_gpio_in[i];
                            counter[i]           <= 16'h0000;
                        end else begin
                            // Not stable long enough yet
                            counter[i] <= counter[i] + 16'h0001;
                        end
                    end
                end
            end
        end
    end

endmodule
