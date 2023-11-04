`timescale 1ns/1ps


/*
���� : ValentineHP
�ϵ��ʽ : ΢�Ź��ں�  FPGA֮��
*/




/*���ڽ���ģ��*/
module UART_MulRX #(
    parameter MulRXNum = 3      /*ÿ�η��͵��ֽ���*/
)(
    input                             sys_clk,        /*ϵͳʱ�� 50M*/
    input                             rst_n,          /*ϵͳ��λ*/

    output                            uart_rxs_done,   /*���ڽ�������*/
    output[MulRXNum * 'd8 - 'd1:0]    odats,           /*��������*/

    input                             uartrx         /*uart rx������*/
);


wire        uart_rx_done;
wire[7:0]   odat;

reg[7:0]    MulRxCnt;
reg[MulRXNum * 'd8 - 'd1:0] RXDataReg;
reg			uart_rxs_donereg;

/*���ݽ�������*/
assign uart_rxs_done = uart_rxs_donereg;//((MulRxCnt == (MulRXNum - 'd1)) && uart_rx_done == 1'b1) ? 1'b1 : 1'b0;

assign odats = RXDataReg;
/*���յ����ݼ���*/
always@(posedge sys_clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        MulRxCnt <= 'd0;
    else if(uart_rxs_done == 1'b1)
        MulRxCnt <= 'd0;
    else if(uart_rx_done == 1'b1) 
        MulRxCnt <= MulRxCnt + 1'b1;
    else
        MulRxCnt <= MulRxCnt;
end

always@(posedge sys_clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		uart_rxs_donereg <= 1'b0;
	else if((odat=="e" && uart_rx_done == 1'b1))
		uart_rxs_donereg <= 1'b1;
	else
		uart_rxs_donereg <= 1'b0;
end

/*�������ݼĴ���*/
always@(posedge sys_clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        RXDataReg <= 'd0;
    else if(uart_rx_done == 1'b1)
        RXDataReg <= {RXDataReg[(MulRXNum -1)* 'd8 - 'd1:0],odat};
    else
        RXDataReg <= RXDataReg;
end



/*���ڽ���ģ��*/
UART_RX #(
    .UARTBaud(115200)
)UART_RXHP(
    .sys_clk            (sys_clk),        /*ϵͳʱ�� 50M*/
    .rst_n              (rst_n),          /*ϵͳ��λ*/

    .uart_rx_done       (uart_rx_done),   /*���ڽ�������*/
    .odat               (odat),           /*��������*/

    .uartrx             (uartrx)         /*uart rx������*/
);


endmodule