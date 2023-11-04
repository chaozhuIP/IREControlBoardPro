
module signal_driver(
    input rst, // 复位信号
    input en, //使能信号
	input clk, // 时钟信号
    input [31:0] period, // 定时器周期信号
	input ecg_status,	//ECG同步信号使能信号
	input  ecg_sync,        // ECG同步信号
    output  done, // 触发信号到来
    output  [9:0] count // 脉冲串计数
);


reg [9:0] time_count; // 定时器计数
reg [9:0] ecg_count; // ecg计数
reg ecg_done;// ecg 触发到来
reg time_done;//定时器触发到来
timer timer_init(
    .rst		(rst_n),
	.en     (en),
    .period	(period), 
    .clk		(sys_clk), 
    .done	(time_done), 
    .count 	(time_count)
);



ecg_syn ecg_syn_init(
  .rst		(rst_n), 
  .en		(en),
  .ecg_sync	(ecg_sync),
  .clk		(sys_clk), 
  .done	(ecg_done), 
  .count 	(ecg_count)
);
assign done=ecg_status?ecg_done:time_done;
assign count=ecg_status?ecg_count:time_count;

endmodule 