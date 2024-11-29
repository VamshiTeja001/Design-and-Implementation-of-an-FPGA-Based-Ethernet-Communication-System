`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.11.2024 22:45:01
// Design Name: 
// Module Name: tcp_ip_stack
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tcp_ip_stack (
  input wire clk,
  input wire rst_n,
  
  // Application layer interface
  input wire [31:0] app_tx_data,
  input wire app_tx_valid,
  output wire app_tx_ready,
  output wire [31:0] app_rx_data,
  output wire app_rx_valid,
  input wire app_rx_ready,
  
  // Ethernet layer interface
  output wire [31:0] eth_tx_data,
  output wire eth_tx_valid,
  input wire eth_tx_ready,
  input wire [31:0] eth_rx_data,
  input wire eth_rx_valid,
  output wire eth_rx_ready
);

  // TCP parameters
  parameter LOCAL_IP = 32'hC0A80001; // 192.168.0.1
  parameter LOCAL_PORT = 16'h1234;
  parameter REMOTE_IP = 32'hC0A80002; // 192.168.0.2
  parameter REMOTE_PORT = 16'h5678;

  // TCP state machine states
  parameter STATE_CLOSED = 2'b00;
  parameter STATE_SYN_SENT = 2'b01;
  parameter STATE_ESTABLISHED = 2'b10;
  parameter STATE_FIN_WAIT = 2'b11;

  // Internal registers
  reg [1:0] tcp_state;
  reg [31:0] tx_seq_num; // Transmission sequence number
  reg [31:0] rx_ack_num; // Reception acknowledgment number
  reg [31:0] tx_buffer;  // Buffer for outgoing packets
  reg [31:0] rx_buffer;  // Buffer for incoming packets
  reg tx_valid_flag;     // Valid flag for outgoing packets
  reg rx_valid_flag;     // Valid flag for incoming packets

  // Reset logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tcp_state <= STATE_CLOSED;
      tx_seq_num <= 0;
      rx_ack_num <= 0;
      tx_valid_flag <= 0;
      rx_valid_flag <= 0;
    end else begin
      case (tcp_state)
        STATE_CLOSED: begin
          if (app_tx_valid) begin
            // Initiate connection with SYN
            tx_seq_num <= {$random} % 32'hFFFFFFFF;
            tx_buffer <= {LOCAL_PORT, REMOTE_PORT, tx_seq_num, 16'h0002}; // SYN
            tx_valid_flag <= 1;
            tcp_state <= STATE_SYN_SENT;
          end
        end

        STATE_SYN_SENT: begin
          if (eth_rx_valid && eth_rx_data[31:16] == LOCAL_PORT &&
              eth_rx_data[15:0] == REMOTE_PORT && eth_rx_data[15]) begin
            // Received SYN-ACK
            rx_ack_num <= eth_rx_data[31:0] + 1;
            tx_buffer <= {LOCAL_PORT, REMOTE_PORT, tx_seq_num, rx_ack_num, 16'h0010}; // ACK
            tx_valid_flag <= 1;
            tcp_state <= STATE_ESTABLISHED;
          end
        end

        STATE_ESTABLISHED: begin
          if (app_tx_valid && app_tx_ready) begin
            // Transmit application data
            tx_buffer <= {LOCAL_PORT, REMOTE_PORT, tx_seq_num, rx_ack_num, 16'h0018, app_tx_data}; // PSH-ACK
            tx_valid_flag <= 1;
            tx_seq_num <= tx_seq_num + 1;
          end
          if (eth_rx_valid) begin
            // Receive data packet
            rx_buffer <= eth_rx_data;
            rx_valid_flag <= 1;
          end
        end

        STATE_FIN_WAIT: begin
          if (eth_rx_valid && eth_rx_data[15:0] == 16'h0011) begin
            // Close connection
            tcp_state <= STATE_CLOSED;
          end
        end
      endcase

      // Clear valid flags when data is processed
      if (tx_valid_flag && eth_tx_ready) begin
        tx_valid_flag <= 0;
      end
      if (rx_valid_flag && app_rx_ready) begin
        rx_valid_flag <= 0;
      end
    end
  end

  // Outputs
  assign eth_tx_data = tx_buffer;
  assign eth_tx_valid = tx_valid_flag;
  assign eth_rx_ready = !rx_valid_flag || app_rx_ready;
  assign app_tx_ready = (tcp_state == STATE_ESTABLISHED) && !tx_valid_flag;
  assign app_rx_data = rx_buffer;
  assign app_rx_valid = rx_valid_flag;

endmodule

