`timescale 1ns/1ps

/*
作者 : ValentineHP
联系方式 : 微信公众号  FPGA之旅
*/






/*串口接收模块*/
module UART_RX(
    input          sys_clk,        /*系统时钟 50M*/
    input          rst_n,          /*系统复位*/

    output         uart_rx_done,   /*串口接收完成*/
    output[7:0]    odat,           /*接收数据*/

    input          uartrx         /*uart rx数据线*/
);

parameter  UARTBaud = 'd115200;     /*波特率*/
localparam UARTCLKPer = (('d1000_000_000 / UARTBaud) /20) -1;   /*每Bit所占的时钟周期*/

localparam  UART_Idle       =   4'b0001;    /*空闲态*/
localparam  UART_Start      =   4'b0010;    /*起始态*/
localparam  UART_Data       =   4'b0100;    /*数据态*/
localparam  UART_Stop       =   4'b1000;    /*停止态*/

reg[3:0]    state , next_state;
reg[19:0]   UARTCnt;           /*串口时钟周期计*/


reg[7:0]    UART_RxData_Reg;   /*串口接收数据寄存器*/
reg[2:0]    UART_Bit;          /*串口接收bit数计数*/

/*缓存rx数据*/
reg uartrxd0,uartrxd1,uartrxd2;
/*检测rx 上下边沿*/
wire  uartrxPosedge , uartrxNegedge;

assign uartrxPosedge = (uartrxd1) & ( ~uartrxd2);
assign uartrxNegedge = (~uartrxd1) & ( uartrxd2);


assign uart_rx_done = (UART_Bit == 'd7 && UARTCnt == UARTCLKPer) ? 1'b1 : 1'b0;
assign odat         = UART_RxData_Reg;

/*缓存rx时钟线*/
always@(posedge sys_clk or negedge rst_n)
begin
    if(rst_n == 1'b0) 
    begin
        uartrxd0 <= 1'b1;
        uartrxd1 <= 1'b1;
        uartrxd2 <= 1'b1;
    end
    else 
    begin
        uartrxd0 <= uartrx;
        uartrxd1 <= uartrxd0;
        uartrxd2 <= uartrxd1;
    end
end


always@(posedge sys_clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        state <= UART_Idle;
    else
        state <= next_state;
end
/*状态机*/
always@(*)
begin
    case(state)
    UART_Idle:
        if(uartrxNegedge == 1'b1)
            next_state <= UART_Start;
        else
            next_state <= UART_Idle;
    UART_Start:
        if(UARTCnt == UARTCLKPer)
            next_state <= UART_Data;
        else
            next_state <= UART_Start;
    UART_Data:
        if(UART_Bit == 'd7 && UARTCnt == UARTCLKPer)
            next_state <= UART_Stop;
        else
            next_state <= UART_Data;
    UART_Stop:
        if(UARTCnt == (UARTCLKPer / 2))
            next_state <= UART_Idle;
        else
            next_state <= UART_Stop;
    default: next_state <= UART_Idle;
    endcase
end



/*串口Bit使用周期计数*/
always@(posedge sys_clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        UARTCnt <= 'd0;
    else if(UARTCnt == UARTCLKPer)
        UARTCnt <= 'd0;
    else if(state == UART_Data)
        UARTCnt <= UARTCnt + 1'b1;
    else if(state == UART_Stop)
        UARTCnt <= UARTCnt + 1'b1;
    else if(state == UART_Start)
        UARTCnt <= UARTCnt + 1'b1;
    else
        UARTCnt <= 'd0;
end


/*接收数据bit计数*/
always@(posedge sys_clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        UART_Bit <= 'd0;
    else if(state == UART_Data && UARTCnt == UARTCLKPer)
        UART_Bit <= UART_Bit + 1'b1;
    else if(state == UART_Stop)
        UART_Bit <= 'd0;
    else 
        UART_Bit <= UART_Bit;
end


/*接送数据*/
always@(posedge sys_clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        UART_RxData_Reg <= 'd0;
    else if(state == UART_Data && UARTCnt == (UARTCLKPer / 2))
        UART_RxData_Reg <= {uartrx,UART_RxData_Reg[7:1]};   /*先接收低位*/
    else if(state == UART_Idle)
        UART_RxData_Reg <= 'd0;
    else
        UART_RxData_Reg <= UART_RxData_Reg;
end


endmodule