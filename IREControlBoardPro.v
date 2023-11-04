
module IREControlBoardPro(
	
	input			sys_clk,
	input			rst_n,
	input			key_in, //模拟电容充满状态
	input           pedal,
	input 			ECG_syn,
	input   [2:0]	needle_type,
	output			key_out,
	output AD1_CLK,
	input [11:0] AD1_DB,
	output AD2_CLK,
	input  [11:0] AD2_DB,	
	input			UART_RX,
	output			UART_TX,
	output			DA_Clk1,
	output			DA_Clk2,
	output			DACA_WRT1,
	output			DACA_WRT2,
	output 	[13:0]			DA_Data1,
	output	[13:0]			DA_Data2

);
parameter max_len=30;




wire 			uart_rxs_done;
wire [8*max_len-1:0]	uart_rxs_data;

//1、参数锁定，上位机发送一次数据、脉冲电压、脉冲宽度、脉冲频率、脉冲间隔、脉冲个数、脉冲串周期、脉冲串数
//2、等待电容充满电，作为使能信号
//3、ECG同步信号使能，则脚踏板踩下，与放电频率和ECG同步
//4、ECG同步信号失能，则脚踏板踩下，与放电频率和定时器频率同步

reg  [15:0] pulse_valtage=1000;//脉冲电压（V）
reg  [15:0] pulse_frequency=1000;//脉冲频率（Hz）
reg  [7:0] pulse_inteval=10;//脉冲间隔（us）
reg  [15:0] pulse_width=500;//脉冲宽度（ns）
reg  [15:0] pulse_number=20;//脉冲个数（个）
reg	 [9:0] pulses_number=20;//脉冲串数（串数）
reg	 [13:0] pulses_cycle=800;//脉冲串数（ms）

reg  sel;


reg status_V=0;//高压开关状态
reg status_ECG=0;//ECG使能信号

reg capacity_en=1;
reg dds_en;
reg  [31:0]Fword;/*频率控制字*/
reg  [15:0]Pword;/*相位控制字*/
reg  [15:0]Pwidth;

reg  pedal_signal_en=0;


/*
	目前下位机完成的功能
	1、信号源模块功能：脉宽、频率、脉冲间隔，脉冲个数（脉冲串数为1）
		由上位机发送指令触发，当检测当上位机发送满足的指令时，同时检测接收完数据时，信号源此时开始工作
		脉冲串周期、和个数，由上位机发送指令数和频率决定（一般是1s周期，通信过程时间损耗不会影响）
	2、电压电流检测功能：系统实时检测通道数据满足数据收集的条件，数据将触发发送功能
	3、电压控制：由上位机另一个COM口RS232通信控制
	-------------------------------
	放电执行：
	1、信号源模块:脉宽、频率、脉冲间隔、脉冲个数由上位机参数设置，上位机发送参数锁定按钮，发送设置参数到下位机。
	下位机接收参数数据。和已完成功能相同。
	2、电压控制:由参数锁定按钮控制，发送数据到充电电源模块设置电压（需要注意：充电电源输出后，需要一段时间给电容充电到设定电压值（下位机不需要触发信号源工作）
	3、脉冲串周期控制：由ECG同步信号控制，FPGA检测到ECG脉冲上升沿触发信号源工作一次
	4、信号源工作：脚踏板状态控制
	5、电压电流检测功能：系统实时检测通道数据满足数据收集的条件，数据将触发发送功能
	检测：
	


*/



assign AD1_CLK=sys_clk;//采集卡时钟
assign AD2_CLK=sys_clk;

//reg[7:0] bit_k;
//reg txdone;
reg UART_TX_Reg;
UART_MulRX #(
	.MulRXNum(max_len)
)
  UART_MulRXHP(
   .sys_clk				(sys_clk),        
   .rst_n				(rst_n),          

   .uart_rxs_done  	(uart_rxs_done),   
   .odats				(uart_rxs_data),           
	//.bit_k				(bit_k)    ,
   .uartrx  			(UART_RX)       
);

/*请求暂存*/
always@(posedge sys_clk)
begin
    if(uart_rxs_done == 1'b1)   //发送请求来了，暂存请求
	begin
		if(uart_rxs_data[2*8-1:8]=="a")
		begin
		
		
			pulses_cycle <=(uart_rxs_data[27*8-1:26*8]-"0")*1000+
			(uart_rxs_data[26*8-1:25*8]-"0")*100+
			(uart_rxs_data[25*8-1:24*8]-"0")*10+
			(uart_rxs_data[24*8-1:23*8]-"0")*1;
			
			pulses_number <=(uart_rxs_data[23*8-1:22*8]-"0")*100+
			(uart_rxs_data[22*8-1:21*8]-"0")*10+
			(uart_rxs_data[21*8-1:20*8]-"0")*1;
			
			if(uart_rxs_data[20*8-1:19*8]=="0")
				status_ECG	<= 1'b0;
			else
				status_ECG	<= 1'b1;
				
			pulse_valtage <=(uart_rxs_data[19*8-1:18*8]-"0")*1000+
			(uart_rxs_data[18*8-1:17*8]-"0")*100+
			(uart_rxs_data[17*8-1:16*8]-"0")*10+
			(uart_rxs_data[16*8-1:15*8]-"0")*1;
			pulse_width <=(uart_rxs_data[15*8-1:14*8]-"0")*1000+
			(uart_rxs_data[14*8-1:13*8]-"0")*100+
			(uart_rxs_data[13*8-1:12*8]-"0")*10+
			(uart_rxs_data[12*8-1:11*8]-"0")*1;
			pulse_frequency <=(uart_rxs_data[11*8-1:10*8]-"0")*1000+
			(uart_rxs_data[10*8-1:9*8]-"0")*100+
			(uart_rxs_data[9*8-1:8*8]-"0")*10+
			(uart_rxs_data[8*8-1:7*8]-"0")*1;
			pulse_inteval <=(uart_rxs_data[7*8-1:6*8]-"0")*10+
			(uart_rxs_data[6*8-1:5*8]-"0")*1;
			pulse_number <=(uart_rxs_data[5*8-1:4*8]-"0")*100+
			(uart_rxs_data[4*8-1:3*8]-"0")*10+
			(uart_rxs_data[3*8-1:2*8]-"0")*1;
			status_V <=status_V;
		end
		else if(uart_rxs_data[2*8-1:8]=="b")
		begin
			
			if(uart_rxs_data[3*8-1:8*2]=="1")
				status_V <=1;
			else
				status_V <=0;
			pulse_valtage 	<=		pulse_valtage 	;
			pulse_width 	<=		pulse_width 	;
			pulse_frequency <=		pulse_frequency ;
			pulse_inteval 	<=		pulse_inteval 	;
			pulse_number 	<=		pulse_number 	;
			status_ECG <= status_ECG;
		end
		
	end
	else
	begin
			status_V <=status_V;
			pulse_valtage 	<=		pulse_valtage 	;
			pulse_width 	<=		pulse_width 	;
			pulse_frequency <=		pulse_frequency ;
			pulse_inteval 	<=		pulse_inteval 	;
			pulse_number 	<=		pulse_number 	;
	end	
       
end

/*脉冲信号源参数设计
	系统频率 ：Fclk=50MHZ(20ns);
	频率字：FWord 32bit，最小分辨率Fout(min)=Fclk/2^(32)=0.0116Hz;最大频率25MHz
	输出频率：Fout=Fword*50MHZ/2^(32);关系Fword=2^32/50M*Fout=[85.8993459*Fout]
	输出脉宽：脉宽精度 1/2^(14)*(1/Fout)*10^6=61.03ns/kHZ,关系width=Pwidth*1/2^(14)*(1/Fout)
	Pwidth=2^(14)*Fout*width=16.384*Fout*width /us.Khz
	相位：interval=Pword/2^(14)*1/Fout-width;Pword=2^14-(interval+width)*Fout*2^(14);
	信号源设计(上位机控制）
	给定参数：脉宽 100ns-9.999us
			正负间隔：1-99us
			频率 ：10-9999HZ
			个数：1-999	
	
	*/
//42,949.67  





assign Fword=(48'hffffffff+1)*pulse_frequency/(50*1000000);
assign Pwidth=(48'hffff+1)*pulse_frequency*pulse_width/1000000000;
assign Pword=(17'hffff+1)-(48'hffff+1)*(pulse_inteval*1000+pulse_width)*pulse_frequency/1000000000;
assign	DACA_WRT1=DA_Clk1;
assign	DACA_WRT2=DA_Clk2;

//接收完数据触发
/* always@(posedge sys_clk)
	begin
	dds_en <=uart_rxs_done;
	capacity_en <=dds_en;
	end
	
	 */

DDS_Module DDS_Module_inst1(
	.Clk	(sys_clk)	,
	.Rst_n	(1)	,
	.EN	(dds_en),
	//.EN		(~capacity_en&dds_en)	,
	.Fword	(Fword)	,
	.Pword	(24'd0)	,
	.Pwidth	(Pwidth)	,
	.DA_Clk	(DA_Clk1)	,
	.DA_Data(DA_Data1),
	.num	(pulse_number),
	.sel(sel),
	.ensig(pedal_signal_en)
);


DDS_Module DDS_Module_inst2(
	.Clk	(sys_clk)	,
	.Rst_n	(1)	,
	.EN	(dds_en),
	//.EN		(~capacity_en&dds_en)	,
	.Fword	(Fword)	,
	.Pword	(Pword)	,
	.Pwidth	(Pwidth)	,
	.DA_Clk	(DA_Clk2)	,
	.DA_Data(DA_Data2),
	.num	(pulse_number+1),
	.sel(),
	.ensig(pedal_signal_en)
);
//脚踏板踩下
key key_init1(
	.clk     (sys_clk)	,
	.key_in	 (~pedal)	,
	.led_out (pedal_signal_en),
	.flag_key2 ()
);



//模拟电容电压充满 
key key_init2(
	.clk     (sys_clk)	,
	.key_in	 (key_in)	,
	.led_out (capacity_en),
	.flag_key2 ()
);


reg [9:0] count; 
reg signal_en1=0;
reg signal_en2=0;			


/* signal_driver signal_driver_init(
	.rst		(rst_n), // 复位信号
    .en		(signal_en1&signal_en2), //定时器触发条件：脚踏板按下和电容电压达到预设值
    .period	(50000*pulses_cycle), // 定时器周期数 
    .clk		(sys_clk), // 系统时钟
    .done	(dds_en), // 单次触发
    .count 	(count),// 触发的次数
	.ecg_status(status_ECG), //ecg使能信号
	.ecg_sync(ECG_syn)//ecg同步信号
); */
/* timer timer_init(
    .rst		(rst_n),
	.en     (signal_en1&signal_en2&(~status_ECG)),
    .period	(50000*pulses_cycle), 
    .clk		(sys_clk), 
    .done	(dds_en), 
    .count 	(count)
);
 */


reg [9:0] time_count; // 定时器计数
reg [9:0] ecg_count; // ecg计数
reg ecg_done;// ecg 触发到来
reg time_done;//定时器触发到来
timer timer_init(
    .rst		(rst_n),
	.en     (signal_en1&signal_en2&(~status_ECG)),
    .period	(50000*pulses_cycle), 
    .clk		(sys_clk), 
    .done	(time_done), 
    .count 	(time_count)
);
ecg_syn ecg_syn_init(
  .rst		(rst_n), 
  .en		(signal_en1&signal_en2&status_ECG),
  .ecg_sync	(ECG_syn),//PIN_L3
  .clk		(sys_clk), 
  .done	(ecg_done), 
  .count 	(ecg_count)
);
assign dds_en=status_ECG?ecg_done:time_done;
assign count=status_ECG?ecg_count:time_count;





//开始放电逻辑，当电容电压满足条件、脚踏板踏下和ECG失能，开始放电，当脉冲串个数达到或者在放电过程中脚踏板提起失能
always@(posedge sys_clk)
begin
	if(pedal_signal_en==1&& capacity_en==1 )
		signal_en1<=1;
	else if(count==pulses_number || pedal_signal_en==0 )
		signal_en1<=0;
	else
		signal_en1<=signal_en1;
end	


//放电使能逻辑，当参数锁定，单次放电使能，当脉冲串个数达到或者在放电过程中脚踏板提起失能
always@(posedge sys_clk)
begin
	if(uart_rxs_done==1)
		signal_en2<=1;
	else
	begin
		if(count==pulses_number||(count>0&&count<pulses_number&&pedal_signal_en==0))
			signal_en2<=0;
		else 
			signal_en2<=signal_en2;
	end			
end



 
assign key_out=~pedal_signal_en;

reg [2:0] needle_type_r;

key key_init3(
	.clk     (sys_clk)	,
	.key_in	 (~needle_type[0])	,
	.led_out (needle_type_r[0]),
	.flag_key2 ()
);

key key_init4(
	.clk     (sys_clk)	,
	.key_in	 (~needle_type[1])	,
	.led_out (needle_type_r[1]),
	.flag_key2 ()
);

key key_init5(
	.clk     (sys_clk)	,
	.key_in	 (~needle_type[2])	,
	.led_out (needle_type_r[2]),
	.flag_key2 ()
);


//脚踏板、电极针状态发生改变监测
reg io_change=0;
reg [3:0] prev_signal=4'd0;
always@(posedge sys_clk)
begin
	if ({pedal_signal_en,needle_type_r} != prev_signal) begin
        io_change <= 1'b1;   // IO发生变化，捕获信号保持高电平
    end else begin
        io_change <= 1'b0;   // 其他情况下，捕获信号保持低电平
    end
    prev_signal <= {pedal_signal_en,needle_type_r}; // 保存当前的IO信号值
end

      


/*多次发送*/
UART_MulTX #(
 .MulTXNum(6)
)
UART_MulTXHP(

    .sys_clk			(sys_clk)									,
    .rst_n			(rst_n)										,

    .uart_tx_req		(UART_TX_Reg)											,   /*串口发送请求*/
    .uart_txs_done	()									,  /*串口发送完成*/       

    .idats			(send_)				,          /*发送的数据*/
    .uarttx        	(UART_TX)								/*uart tx数据线*/
);
reg [23:0]AD1_reg;
reg [23:0]AD2_reg;
reg [3:0] Num_0=0;
//发送选择模式位
reg send_mode=0;
wire [47:0] send_;
assign send_=send_mode?{AD1_reg,AD2_reg}:{40'hffffffffff,prev_signal,pedal_signal_en,needle_type_r};
/*-5~5V 数字量对应0~4095(0V-2048) 
监测电压（-5000~5000V)衰减1000 到-5~5V
	AD采样精度：10/4096=0.00244140625; 电压检测精度：10/4096*1000=2.44V
	换算公式：假设数字量-Vdata，AD采样模拟量-VAD，VAD=(Vdata-2048)/2048*5V,Vreal=(Vdata-2048)/2048*5*1000;
	上限值：设置为Vreal=500V(VAD=0.5V) 对应数字量为：Vdata=500/1000/5*2048+2048=2252V
	设置开始采样点延迟时间：一个周期20ns，延迟100ns，5个周期
监测电流（）
*/


//always@(negedge sys_clk)
always@(posedge sys_clk)
begin	
	if(sel) 
	begin
		if(AD1_DB>2252)
		begin
			case(Num_0)
			3'd0:begin
			UART_TX_Reg<=0;
			Num_0<=1;
			end
			3'd1:begin
			Num_0<=2;
			end
			3'd2:begin
			Num_0<=3;
			end
			3'd3:begin
			Num_0<=4;
			end
			3'd4:begin
			Num_0<=5;
			end
			3'd5:begin
			AD1_reg[11:0]<=AD1_DB;
			AD2_reg[11:0]<=AD2_DB;
			Num_0<=6;
			end
			3'd6:begin
			AD1_reg[23:12]<=AD1_DB;
			AD2_reg[23:12]<=AD2_DB;
			UART_TX_Reg<=1;
			send_mode<=1;
			Num_0<=7;
			end
			3'd7:begin
			Num_0<=7;
			UART_TX_Reg<=0;
			end
			default:
			begin
			UART_TX_Reg<=0;
			Num_0<=7;
			end	
			endcase
		end
		else
		begin
		UART_TX_Reg<=0;
		Num_0<=0;
		end
	end
	else if (io_change)
	begin
		Num_0<=0;
		UART_TX_Reg<=1;
		send_mode<=0;
	end
	else
	begin
		UART_TX_Reg<=0;
		Num_0<=0;
	end
end 



endmodule 