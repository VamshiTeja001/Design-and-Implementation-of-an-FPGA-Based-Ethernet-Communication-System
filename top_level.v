`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/20/2024
// Design Name: Top Level Module
// Module Name: top_level
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Integrates Ethernet, IP, TCP layers, and application logic
//              to send GET /STATUS_LIGHT and process its responses.
// 
// Dependencies: None
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module top_level (
  input wire clk,
  input wire rst_n,
  
  // Ethernet interface
  input wire [47:0] eth_rx_data,
  input wire eth_rx_valid,
  output wire eth_rx_ready,
  output wire [47:0] eth_tx_data,
  output wire eth_tx_valid,
  input wire eth_tx_ready
);

  // Interconnect signals between layers
  wire [31:0] eth_to_ip_data;
  wire eth_to_ip_valid;
  wire eth_to_ip_ready;
  wire [31:0] ip_to_eth_data;
  wire ip_to_eth_valid;
  wire ip_to_eth_ready;

  wire [31:0] ip_to_tcp_data;
  wire ip_to_tcp_valid;
  wire ip_to_tcp_ready;
  wire [31:0] tcp_to_ip_data;
  wire tcp_to_ip_valid;
  wire tcp_to_ip_ready;

  wire [31:0] tcp_to_app_data;
  wire tcp_to_app_valid;
  wire tcp_to_app_ready;
  wire [31:0] app_to_tcp_data;
  wire app_to_tcp_valid;
  wire app_to_tcp_ready;

  // Instantiate the Ethernet layer
  ethernet_layer ethernet_inst (
    .clk(clk),
    .rst_n(rst_n),
    .mac_rx_data(eth_rx_data),
    .mac_rx_valid(eth_rx_valid),
    .mac_rx_ready(eth_rx_ready),
    .mac_tx_data(eth_tx_data),
    .mac_tx_valid(eth_tx_valid),
    .mac_tx_ready(eth_tx_ready),
    .tcp_ip_rx_data(eth_to_ip_data),
    .tcp_ip_rx_valid(eth_to_ip_valid),
    .tcp_ip_rx_ready(eth_to_ip_ready),
    .tcp_ip_tx_data(ip_to_eth_data),
    .tcp_ip_tx_valid(ip_to_eth_valid),
    .tcp_ip_tx_ready(ip_to_eth_ready)
  );

  // Instantiate the IP layer
  ip_layer ip_inst (
    .clk(clk),
    .rst_n(rst_n),
    .eth_rx_data(eth_to_ip_data),
    .eth_rx_valid(eth_to_ip_valid),
    .eth_rx_ready(eth_to_ip_ready),
    .eth_tx_data(ip_to_eth_data),
    .eth_tx_valid(ip_to_eth_valid),
    .eth_tx_ready(ip_to_eth_ready),
    .tcp_rx_data(ip_to_tcp_data),
    .tcp_rx_valid(ip_to_tcp_valid),
    .tcp_rx_ready(ip_to_tcp_ready),
    .tcp_tx_data(tcp_to_ip_data),
    .tcp_tx_valid(tcp_to_ip_valid),
    .tcp_tx_ready(tcp_to_ip_ready)
  );

  // Instantiate the TCP layer
  tcp_layer tcp_inst (
    .clk(clk),
    .rst_n(rst_n),
    .ip_rx_data(ip_to_tcp_data),
    .ip_rx_valid(ip_to_tcp_valid),
    .ip_rx_ready(ip_to_tcp_ready),
    .ip_tx_data(tcp_to_ip_data),
    .ip_tx_valid(tcp_to_ip_valid),
    .ip_tx_ready(tcp_to_ip_ready),
    .app_rx_data(tcp_to_app_data),
    .app_rx_valid(tcp_to_app_valid),
    .app_rx_ready(tcp_to_app_ready),
    .app_tx_data(app_to_tcp_data),
    .app_tx_valid(app_to_tcp_valid),
    .app_tx_ready(app_to_tcp_ready)
  );

  // Application logic: Generate GET /STATUS_LIGHT and handle response
  reg [31:0] app_request_data [0:3]; // Buffer for request
  reg [1:0] app_request_index;       // Index for transmitting request
  reg app_request_valid;             // Valid signal for request
  reg response_processed;            // Tracks if the response is handled

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      app_request_index <= 0;
      app_request_valid <= 0;
      response_processed <= 0;

      // Preload the GET /STATUS_LIGHT request
      app_request_data[0] <= 32'h47455420; // "GET "
      app_request_data[1] <= 32'h2F535441; // "/STA"
      app_request_data[2] <= 32'h5455535F; // "TUS_"
      app_request_data[3] <= 32'h4C494748; // "LIGHT"
    end else begin
      // Transmit request
      if (app_to_tcp_ready && app_request_index < 4) begin
        app_request_valid <= 1;
        app_request_index <= app_request_index + 1;
      end else if (app_request_index == 4) begin
        app_request_valid <= 0; // Transmission complete
      end

      // Process response
      if (tcp_to_app_valid && !response_processed) begin
        case (tcp_to_app_data)
          32'h4F4E: begin
            // "ON" response
            response_processed <= 1;
          end
          32'h4F4646: begin
            // "OFF" response
            response_processed <= 1;
          end
          default: begin
            // Unknown response
            response_processed <= 1;
          end
        endcase
      end
    end
  end

  // Application-to-TCP interface
  assign app_to_tcp_data = app_request_data[app_request_index];
  assign app_to_tcp_valid = app_request_valid;

  // TCP-to-Application interface
  assign tcp_to_app_ready = !response_processed;

endmodule
