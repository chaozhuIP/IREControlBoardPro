`timescale 1ns/1ns


module tb_DDS();

reg		sys_clk		;
reg		sys_rst_n	;
reg		EN;


 

reg [31:0]Fword;/*频率控制字*/
reg [15:0]Pword;/*相位控制字*/
reg [15:0]Pwidth;
wire DA_Clk1;/*DA数据输出时钟*/
wire DA_Clk2;/*DA数据输出时钟*/
wire [13:0]DA_Data1;/*D输出输出A*/
wire [13:0]DA_Data2;/*D输出输出A*/
reg [15:0] pulse_number;
reg  [15:0] pulse_frequency;
reg  [7:0] 	pulse_inteval;
reg  [15:0] pulse_width;


/*脉冲信号源参数设计
	系统频率 ：Fclk=50MHZ(20ns);
	频率字：FWord 32bit，最小分辨率Fout(min)=Fclk/2^(32)=0.0116Hz;最大频率25MHz
	输出频率：Fout=Fword*50MHZ/2^(32);关系Fword=2^32/50M*Fout=[85.8993459*Fout]
	输出脉宽：脉宽精度 1/2^(14)*(1/Fout)*10^6=61.03ns/kHZ,关系width=Pwidth*1/2^(14)*(1/Fout)
	Pwidth=2^(14)*Fout*width=16.384*Fout*width /us.Khz
	相位：interval=Pword/2^(14)*1/Fout-width;Pword=2^14-(interval+width)*Fout*2^(14);
	*/
	




initial
	begin
	sys_clk=1'b1;
	sys_rst_n<=1'b0;
	Fword<=32'd0;
	Pword<=16'd0;
	Pwidth<=16'd0;
	pulse_frequency=10000;
	pulse_inteval=5;
	pulse_width=1000;
	
	EN<=0;
	pulse_number=10;
	#20
	Fword=(48'hffffffff+1)*pulse_frequency/(50*1000000);
	Pwidth=(48'hffff+1)*pulse_frequency*pulse_width/1000000000;
	Pword=(17'hffff+1)-(48'hffff+1)*(pulse_inteval*1000+pulse_width)*pulse_frequency/1000000000;
	sys_rst_n<=1'b1;
	EN<=0;
	#20000
	EN<=1;
	#20020
	EN<=0;
	
	/* Fword=(48'hffffffff+1)*500/(50*1000000);
	Pwidth=(48'h3fff+1)*500*1000/1000000000;
	Pword=(14'h3fff+1)-(48'h3fff+1)*(90*1000+1000)*500/1000000000;
	pulse_numbe=10; */
	end
always #10 sys_clk=~sys_clk;


DDS_Module DDS_Module_inst1(
	.Clk	(sys_clk)	,
	.Rst_n	(1)	,
	.EN		(EN)	,
	.Fword	(Fword)	,
	.Pword	(16'd0)	,
	.Pwidth	(Pwidth)	,
	.DA_Clk	(DA_Clk1)	,
	.DA_Data(DA_Data1),
	.num	(pulse_number)
);


DDS_Module DDS_Module_inst2(
	.Clk	(sys_clk)	,
	.Rst_n	(1)	,
	.EN		(EN)	,
	.Fword	(Fword)	,
	.Pword	(Pword)	,
	.Pwidth	(Pwidth)	,
	.DA_Clk	(DA_Clk2)	,
	.DA_Data(DA_Data2),
	.num	(pulse_number+1)
);





/* DDS_Module DDS_Module_inst(
	.Clk	(sys_clk)	,
	.Rst_n	(sys_rst_n)	,
	.EN		(EN)	,
	.Fword	(Fword)	,
	.Pword	(Pword)	,
	.Pwidth	(Pwidth)	,
	.DA_Clk	(DA_Clk)	,
	.DA_Data(DA_Data)
); */


endmodule