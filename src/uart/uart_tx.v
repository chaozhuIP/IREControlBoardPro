`timescale 1ns/1ps

/*
作者 : ValentineHP
联系方式 : 微信公众号  FPGA之旅
*/



/*串口发送模块*/
module  UART_TX(
    input       sys_clk,       /*系统时钟 50M*/
    input       rst_n,         /*系统复位 低电平有效*/

    input       uart_tx_req,   /*串口发送请求*/
    output      uart_tx_done,  /*串口发送完成*/

    input[7:0]  idat,          /*发送数据*/
    output      uarttx         /*uart tx数据线*/
);



parameter   UARTBaud   = 'd115200;     /*波特率*/
localparam  UARTCLKPer =  (('d1000_000_000 / UARTBaud) /20) -1;   /*每Bit所占的时钟周期*/


localparam  UART_Idle       =   4'b0001;    /*空闲态*/
localparam  UART_Start      =   4'b0010;    /*起始态*/
localparam  UART_Data       =   4'b0100;    /*数据态*/
localparam  UART_Stop       =   4'b1000;    /*停止态*/

reg[3:0]    state , next_state;
reg[19:0]   UARTCnt;           /*串口时钟周期计*/


reg         UART_Req_Reg;      /*串口发送请求寄存器*/
reg[7:0]    UART_TxData_Reg;   /*串口发送数据寄存器*/
reg         UART_TX_Reg;       /*串口发送数据线寄存器*/
reg[2:0]    UART_Bit;          /*串口发送bit数计数*/

assign      uarttx = UART_TX_Reg;
assign      uart_tx_done = (state == UART_Stop && (UARTCnt == (UARTCLKPer - 1'b1))) ? 1'b1 : 1'b0;

always @(posedge sys_clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        state <= UART_Idle;
    else
        state <= next_state;
end

/*状态机*/
always@(*)
begin
    case (state)
        UART_Idle: 
            if(UART_Req_Reg == 1'b1)    /*请求来了后，发送数据*/
                next_state <= UART_Start;
            else
                next_state <= UART_Idle;
        UART_Start:                     /*开始状态*/
            if(UARTCnt == UARTCLKPer)
                next_state <= UART_Data;
            else
                next_state <= UART_Start;
        UART_Data:
            if(UART_Bit == 'd7 && UARTCnt == UARTCLKPer)  /*数据发送完成*/
                next_state <= UART_Stop;
            else
                next_state <= UART_Data;
        UART_Stop:
            if(UARTCnt == UARTCLKPer)   
                next_state <= UART_Idle;
            else
                next_state <= UART_Stop;
        default: next_state <= UART_Idle;
    endcase
end



/*发送请求寄存器*/
always @(posedge sys_clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        UART_Req_Reg <= 1'b0;
    else
        UART_Req_Reg <= uart_tx_req;
end

/*发送数据寄存器*/
always @(posedge sys_clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        UART_TxData_Reg <= 'd0;
    else if(uart_tx_req == 1'b1)
        UART_TxData_Reg <= idat;
    else if(state == UART_Stop)  /*发送完成，寄存器清零*/
        UART_TxData_Reg <= 'd0;
    else
        UART_TxData_Reg <= UART_TxData_Reg;
end

/*串口Bit使用周期计数*/
always @(posedge sys_clk or negedge rst_n) 
begin
    if(rst_n == 1'b0)
        UARTCnt <= 'd0;
    else if(UARTCnt == UARTCLKPer)   /*计数到最大值后，清零*/
        UARTCnt <= 'd0;
    else if(state == UART_Start)
        UARTCnt <= UARTCnt + 1'b1;
    else if(state == UART_Data)
        UARTCnt <= UARTCnt + 1'b1;
    else if(state == UART_Stop)
        UARTCnt <= UARTCnt + 1'b1;
    else
        UARTCnt <= 'd0;
end

/*发送bit计数*/
always@(posedge sys_clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        UART_Bit <= 'd0;
    else if(state == UART_Stop)  /*一组数据发送完成了，bit数清零*/
        UART_Bit <= 'd0;
    else if(state == UART_Data && UARTCnt == UARTCLKPer)
        UART_Bit <= UART_Bit + 1'b1;
    else
        UART_Bit <= UART_Bit;
end


/*数据发送*/
always@(posedge sys_clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        UART_TX_Reg <= 1'b1;
    else if(state == UART_Start)
        UART_TX_Reg <= 1'b0;
    else if(state == UART_Data)
        UART_TX_Reg <= UART_TxData_Reg[UART_Bit];
    else
        UART_TX_Reg <= 1'b1;
end

endmodule