


// Timer counter module
module timer(
    input rst, // reset signal
    input en, // enable signal
    input [31:0] period, // period parameter
    input clk, // clock signal
    output reg done, // done signal
    output reg [9:0] count // count output
);


reg [31:0] div_reg; // divider register

// reset the counter and the divider register when rst is high


// start counting when en is high
always @(posedge clk or negedge rst) begin
	if(!rst)
	begin
		count <= 0;
		div_reg <= 0;
	end
	else
	begin 
		if (en) begin 
			div_reg <= div_reg + 1; // increase the divider register by 1
			if (div_reg == period) begin // if the divider register reaches the period value
				div_reg <= 0; // reset the divider register to 0
				done <= 1; // set done to high for one clock cycle 
				count <= count + 1; // increase the counter by 1 
			end else begin 
				done <= 0; // set done to low otherwise 
			end 
		end else begin 
			div_reg <= 0; // reset the divider register to 0 when en is low 
			done <= 0; // set done to low when en is low 
			count <= 0;
		end 
	end
end 

endmodule 