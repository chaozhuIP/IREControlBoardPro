`timescale 1ns/1ps


/*
作者 : ValentineHP
联系方式 : 微信公众号  FPGA之旅
*/




/*多次发送*/
module UART_MulTX #( 
    parameter MulTXNum = 3)   /*每次发送的字节数*/
(
    
    input                           sys_clk,
    input                           rst_n,

    input                           uart_tx_req,   /*串口发送请求*/
    output                          uart_txs_done,  /*串口发送完成*/       

    input[MulTXNum*'d8 - 'd1:0]     idats,          /*发送的数据*/
    output                          uarttx         /*uart tx数据线*/
);



reg [MulTXNum*'d8 - 'd1:0] idatsReg;   /*数据暂存*/
reg[7:0]  txdata;   /*发送的数据*/
reg       UART_TX_Reg;   /*发送请求寄存器*/
reg[7:0]  MulTxCnt;     /*发送byte数计数*/
reg        UART_TXing;  /*发送数据中标志*/
wire      uart_tx_done;

assign    uart_txs_done = ((MulTxCnt == (MulTXNum -'d1)) && uart_tx_done == 1'b1) ? 1'b1 : 1'b0;   

/*请求暂存*/
always@(posedge sys_clk  or negedge rst_n)
begin
    if(rst_n == 1'b0)
        UART_TX_Reg <= 1'b0;
    else if(uart_txs_done == 1'b1)   /*数据发送完成，清除请求*/
        UART_TX_Reg <= 1'b0;
    else if(uart_tx_req == 1'b1 && UART_TXing == 1'b0)   /*发送请求来了，暂存请求*/
        UART_TX_Reg <= 1'b1;
    else
        UART_TX_Reg <= UART_TX_Reg;
end

/*发送数据标志*/
always@(posedge sys_clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        UART_TXing <= 1'b0;
    else if(uart_txs_done == 1'b1)
        UART_TXing <= 1'b0;
    else if(uart_tx_req == 1'b1)
        UART_TXing <= 1'b1;
    else
        UART_TXing <= UART_TXing;
        


end


/*发送数据计数*/
always@(posedge sys_clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        MulTxCnt <= 'd0;
    else if(uart_txs_done == 1'b1)
        MulTxCnt <= 'd0;
    else if(uart_tx_done == 1'b1)
        MulTxCnt <= MulTxCnt + 1'b1;
    else
        MulTxCnt <= MulTxCnt;
end

/*发送数据暂存*/
always@(posedge sys_clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        idatsReg <= 'd0;
    else if(uart_tx_done == 1'b1)
        idatsReg <= idatsReg >> 8;
    else if(uart_tx_req == 1'b1 && UART_TXing == 1'b0)
        idatsReg <=  idats >> 8;
    else
        idatsReg <= idatsReg;
end


/*获取单次发送的数据*/
always@(posedge sys_clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        txdata <= 'd0;
    else if(uart_tx_done == 1'b1)
        txdata <= idatsReg[7:0];
    else if(uart_tx_req == 1'b1 && UART_TXing == 1'b0)
        txdata <= idats[7:0];
    else
        txdata <= txdata;
end

 UART_TX #(
    .UARTBaud(115200)   /*设置波特率*/
 )UART_TXHP
 (
    .sys_clk           (sys_clk),       /*系统时钟 50M*/
    .rst_n              (rst_n),         /*系统复位 低电平有效*/

    .uart_tx_req        (UART_TX_Reg),   /*串口发送请求*/
    .uart_tx_done       (uart_tx_done),  /*串口发送完成*/

    .idat               (txdata),          /*发送数据*/
    .uarttx             (uarttx)        /*uart tx数据线*/
);

    
endmodule