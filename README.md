# Design-and-Implementation-of-an-FPGA-Based-Ethernet-Communication-System
Interfacing FPGA with Ethernet PHY. Designed and Deployed to operate on Zynq 7020 board with RTL8211E Ethernet PHY

Overview

This project demonstrates the design and implementation of an FPGA-based Ethernet communication system. The FPGA interfaces with an Ethernet PHY to establish a TCP/IP communication link. The project implements a layered architecture, including Ethernet, IP, and TCP layers, and processes application-specific data such as handling requests and sending responses over the network.

The system is capable of:

Sending a predefined request (e.g., GET /STATUS_LIGHT) from the FPGA to a server.
Receiving server responses (ON or OFF) and handling them appropriately.
This project integrates FPGA design with network protocols, enabling real-time communication in embedded systems for use cases such as IoT, industrial automation, or data acquisition systems.

Features
Ethernet Communication: Interfaces an FPGA with an Ethernet PHY for data transmission and reception.
TCP/IP Stack Implementation: Custom modules for TCP, IP, and Ethernet layers handle reliable communication.
Application Layer Integration: Processes requests and responses, demonstrating real-world use cases like querying status.
Hardware-Software Interaction: Example Python server script to respond to the FPGA’s requests for testing purposes.
Scalable Design: Modular architecture allows easy extension to other protocols or applications.
Project Structure
The project consists of the following components:

FPGA Design:

Ethernet Layer: Handles low-level Ethernet frame management.
IP Layer: Encapsulates data in IP packets with source/destination IP handling.
TCP Layer: Implements reliable transport, handling sequence numbers and acknowledgments.
Top-Level Module: Integrates all layers and includes application logic for request/response handling.
Server Implementation:

Python-based TCP server that simulates responses (ON/OFF) to FPGA requests.
