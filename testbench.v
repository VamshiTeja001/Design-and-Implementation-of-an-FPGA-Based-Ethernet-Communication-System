`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.11.2024 23:15:49
// Design Name: 
// Module Name: testbench
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

`timescale 1ns / 1ps

module top_level_tb();

  // Testbench signals
  reg clk;
  reg rst_n;

  // Ethernet interface signals
  reg [47:0] eth_rx_data;
  reg eth_rx_valid;
  wire eth_rx_ready;
  wire [47:0] eth_tx_data;
  wire eth_tx_valid;
  reg eth_tx_ready;

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk; // 100 MHz clock

  // Instantiate the top_level module
  top_level uut (
    .clk(clk),
    .rst_n(rst_n),
    .eth_rx_data(eth_rx_data),
    .eth_rx_valid(eth_rx_valid),
    .eth_rx_ready(eth_rx_ready),
    .eth_tx_data(eth_tx_data),
    .eth_tx_valid(eth_tx_valid),
    .eth_tx_ready(eth_tx_ready)
  );

  // Test procedure
  initial begin
    // Reset initialization
    rst_n = 0;
    eth_rx_data = 0;
    eth_rx_valid = 0;
    eth_tx_ready = 0;
    #20;
    rst_n = 1;

    // Simulate transmission of GET /STATUS_LIGHT request
    #50;
    eth_tx_ready = 1; // Ready to accept Ethernet transmissions

    // Simulate response from the server
    #100;
    eth_rx_data = 48'h4F4E; // "ON" in ASCII
    eth_rx_valid = 1;
    #10;
    eth_rx_valid = 0; // Clear valid signal

    #100;
    eth_rx_data = 48'h4F4646; // "OFF" in ASCII
    eth_rx_valid = 1;
    #10;
    eth_rx_valid = 0;

    // End simulation
    #200;
    $stop;
  end

  // Monitor for debug
  initial begin
    $monitor("Time: %0t | eth_tx_valid: %b | eth_tx_data: %h | eth_rx_valid: %b | eth_rx_data: %h", 
             $time, eth_tx_valid, eth_tx_data, eth_rx_valid, eth_rx_data);
  end

endmodule

