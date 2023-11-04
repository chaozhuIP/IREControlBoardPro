module ecg_syn (
  input rst, // reset signal
  input en, // enable signal
  input clk, // enable signal
  input wire ecg_sync,        // ECG同步信号
  output reg done, // done signal
  output reg [9:0] count // count output
);

reg [15:0] counter;
reg ecg_sync_delayed;
reg ecg_sync_delayed_r;
always @(posedge clk or negedge rst) begin
	if (!rst) begin
		count <= 0;        // 复位计数器
		done <= 1'b0;           // 复位标志信号
	end else if (en) begin
		if (ecg_sync_delayed && !ecg_sync_delayed_r) begin
			done <= 1; // set done to high for one clock cycle 
			count <= count + 1; // increase the counter by 1
		end else begin
			done <= 0; // set done to low otherwise 
		end
	end
	else 
		begin 
			done <= 0; // set done to low when en is low 
			count <= 0;
		end 
	end
always @(posedge clk) //采样频率小于按键毛刺频率，相当于滤除掉了高频毛刺信号。
	begin
	if(counter >=16'b0001_0000_0000_0000) begin
			counter <= 20'b0;
			ecg_sync_delayed <= ecg_sync;
	end
	else
			counter <= counter+16'b1;
	end
always @(posedge clk)
	ecg_sync_delayed_r <= ecg_sync_delayed;


endmodule