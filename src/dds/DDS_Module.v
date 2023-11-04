/***************************************************
*	Module Name		:	DDS_Module		   
*	Target Device	:	EP4CE10F17C8
*	Tool versions	:	Quartus II 13.0
*	Create Date		:	2017-06-25
*	Revision		   :	v1.1
*	Description		:  DDS功能模块，根据频率控制字和相位控制字产生对应正弦数据输出
**************************************************/

module DDS_Module(
	Clk,
	Rst_n,
	EN,
	Fword,
	Pword,
	Pwidth,
	DA_Clk,
	DA_Data,
	num,
	sel,
	ensig
	
);

	input Clk;/*系统时钟*/
	input Rst_n;/*系统复位*/
	input EN;/*DDS模块使能*/
	input [31:0]Fword;/*频率控制字*/
	input [15:0]Pword;/*相位控制字*/
	input [15:0]Pwidth;
	input	[15:0]num;	
	output DA_Clk;/*DA数据输出时钟*/
	output [13:0]DA_Data;/*D输出输出A*/
	output reg sel;
	input ensig;
	reg	[15:0] count;
	reg flag1=1;
	reg flag2=1;
	reg flag;
	reg [31:0]Fre_acc;	
	reg [15:0]Rom_Addr;
	reg	[13:0]out_data;
/*---------------相位累加器------------------*/	
	always @(posedge Clk or negedge Rst_n or posedge EN)
	if(!Rst_n)
		Fre_acc <= 32'd0;
	else if(EN)
		Fre_acc <= 32'd0;
	else if(sel)
		Fre_acc <= Fre_acc + Fword;
	else 
		Fre_acc <= 32'd0;
/*----------生成查找表地址---------------------*/
	
	always @(posedge Clk or negedge Rst_n or posedge EN)
	if(!Rst_n)
		Rom_Addr <= 16'd0;
	else if(EN)
		Rom_Addr <= 16'd0;
	else if(sel)
		Rom_Addr <= Fre_acc[31:16] + Pword;
	else
		Rom_Addr <= 16'd0;
	
	always @(posedge Clk or negedge Rst_n or posedge EN)
	if(!Rst_n)
		sel<=1;
	else if(EN)
		sel<=1;
	else if(count==num)
		sel<=0;
	else
		sel<=sel;

/*----------例化查找表ROM-------*/	

	always @(posedge Clk or negedge Rst_n or posedge EN)
		if(!Rst_n)
			count<=0;
		else if(EN)
			count<=0;
		else if(~flag1&flag2)	
			count<=count+1;
		else
			count<=count;
	always @(posedge Clk )
	begin
		flag1<=flag;
		flag2<=flag1;
	end
	
	always @(posedge Clk or negedge Rst_n or posedge EN)
	if(!Rst_n)
		out_data <= 14'h1fff;
	else if(EN)
		out_data <= 14'h1fff;
	else if(Pwidth>Rom_Addr && sel)
		begin
		flag<=1;
		out_data <= 14'h3fff;
		end
	else
	begin
		flag<=0;
		out_data <= 14'h1fff;
	end
	
	/* ddsrom ddsrom(
		.address(Rom_Addr),
		.clock(Clk),
		.q(DA_Data)
	); */

		
/*----------输出DA时钟----------*/
	assign DA_Clk = (sel&ensig)?Clk:1'b1;
	assign DA_Data = out_data;

endmodule
