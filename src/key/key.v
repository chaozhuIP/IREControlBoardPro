module key(clk,key_in,led_out,flag_key2);
input clk; //50Mhz
input  key_in;
output  led_out;
output flag_key2;
reg [19:0] count;
reg  key_scan; //按键扫描值

always @(posedge clk) //采样按键值，采样频率小于按键毛刺频率，相当于滤除掉了高频毛刺信号。
begin
   if(count >=20'b1111_0100_0010_0100_0000) begin//20ms扫描一次按键
        count <= 20'b0;
        key_scan <= key_in;
   end
   else
        count <= count+20'b1;
end

reg key_scan_r;
always @(posedge clk)
    key_scan_r <= key_scan;
    
wire flag_key1 = key_scan_r & (~key_scan);  //当检测到按键有上沿变化时，代表该按键抬起
assign flag_key2 = (~key_scan_r) & key_scan;  //当检测到按键有下降沿变化时，代表该按键按下 
//reg  temp_led;
always @ (posedge clk)
begin            
   if ( flag_key2 && (~flag_key1)) led_out <= 1'b0;   //某个按键值变化时，LED将做亮灭翻转
   else if(flag_key1 && (~flag_key2)) led_out <= 1'b1;
   else	led_out<=led_out;
	
end
//assign led_out = temp_led ? 1'b1 : 1'b0;     //LED翻转输出

            
endmodule
