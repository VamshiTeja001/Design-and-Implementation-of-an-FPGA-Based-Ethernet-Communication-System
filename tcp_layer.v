`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.11.2024 22:39:45
// Design Name: 
// Module Name: tcp_layer
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

module tcp_layer (
  input wire clk,
  input wire rst_n,
  
  // IP layer interface
  input wire [31:0] ip_rx_data,
  input wire ip_rx_valid,
  output wire ip_rx_ready,
  output wire [31:0] ip_tx_data,
  output wire ip_tx_valid,
  input wire ip_tx_ready,
  
  // Application layer interface
  output wire [31:0] app_rx_data,
  output wire app_rx_valid,
  input wire app_rx_ready,
  input wire [31:0] app_tx_data,
  input wire app_tx_valid,
  output wire app_tx_ready
);

  // TCP state definitions
  parameter TCP_STATE_IDLE = 2'b00;
  parameter TCP_STATE_SYN_SENT = 2'b01;
  parameter TCP_STATE_ESTABLISHED = 2'b10;
  parameter TCP_STATE_FIN_WAIT = 2'b11;

  // TCP parameters
  parameter TCP_SRC_PORT = 16'h1234;
  parameter TCP_DST_PORT = 16'h5678;
  parameter TCP_WINDOW_SIZE = 16'h7FFF;

  // State variables
  reg [1:0] tcp_state;
  reg [31:0] tx_buffer; // Transmission buffer
  reg [31:0] rx_buffer; // Reception buffer
  reg tx_buffer_valid;  // Transmission buffer valid flag
  reg rx_buffer_valid;  // Reception buffer valid flag
  reg [31:0] seq_num;   // TCP sequence number
  reg [31:0] ack_num;   // TCP acknowledgment number

  // Reset logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tcp_state <= TCP_STATE_IDLE;
      tx_buffer <= 0;
      rx_buffer <= 0;
      tx_buffer_valid <= 0;
      rx_buffer_valid <= 0;
      seq_num <= 0;
      ack_num <= 0;
    end else begin
      case (tcp_state)
        // Idle state: wait for application layer to send data
        TCP_STATE_IDLE: begin
          if (app_tx_valid) begin
            tcp_state <= TCP_STATE_SYN_SENT;
            seq_num <= 0;
            tx_buffer <= {TCP_SRC_PORT, TCP_DST_PORT, seq_num, 16'h0, TCP_WINDOW_SIZE}; // SYN packet
            tx_buffer_valid <= 1;
          end
        end

        // SYN sent state: wait for SYN-ACK from server
        TCP_STATE_SYN_SENT: begin
          if (ip_rx_valid) begin
            if (ip_rx_data[31:16] == TCP_DST_PORT && ip_rx_data[15:0] == 16'h5002) begin
              ack_num <= ip_rx_data[47:32] + 1; // Acknowledge SYN
              tcp_state <= TCP_STATE_ESTABLISHED;
              tx_buffer <= {TCP_SRC_PORT, TCP_DST_PORT, seq_num, ack_num, 16'h5010, TCP_WINDOW_SIZE}; // ACK packet
              tx_buffer_valid <= 1;
            end
          end
        end

        // Established state: ready for data exchange
        TCP_STATE_ESTABLISHED: begin
          if (app_tx_valid && app_tx_ready) begin
            tx_buffer <= app_tx_data; // Send application data
            tx_buffer_valid <= 1;
            seq_num <= seq_num + 1;
          end
          if (ip_rx_valid) begin
            rx_buffer <= ip_rx_data; // Receive application data
            rx_buffer_valid <= 1;
          end
        end

        // FIN_WAIT: handle connection termination
        TCP_STATE_FIN_WAIT: begin
          if (ip_rx_valid) begin
            if (ip_rx_data[15:0] == 16'h5011) begin
              tcp_state <= TCP_STATE_IDLE; // Connection closed
            end
          end
        end
      endcase

      // Clear valid flags when data is consumed
      if (tx_buffer_valid && ip_tx_ready) begin
        tx_buffer_valid <= 0;
      end
      if (rx_buffer_valid && app_rx_ready) begin
        rx_buffer_valid <= 0;
      end
    end
  end

  // Outputs
  assign app_rx_data = rx_buffer;
  assign app_rx_valid = rx_buffer_valid;
  assign ip_rx_ready = !rx_buffer_valid || app_rx_ready;
  assign ip_tx_data = tx_buffer;
  assign ip_tx_valid = tx_buffer_valid;
  assign app_tx_ready = (tcp_state == TCP_STATE_ESTABLISHED) && !tx_buffer_valid;

endmodule

