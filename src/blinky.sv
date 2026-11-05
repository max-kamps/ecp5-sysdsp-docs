module top (
	output logic [4:0] led,
	input  wire        clk
);
	// Delay (50MHz >> 25 = 1.49011611938Hz = 0.67108864s/blink)
	logic [24:0] clkb;
	wire clki = clkb[24];

	// Count the clocks
	always @(posedge clk) clkb <= clkb + 1'b1;

	initial begin
		clkb = 0;
	end

	// Add one to the led register
	always_ff @(posedge clki) begin
		led <= led + 1;
	end
endmodule
