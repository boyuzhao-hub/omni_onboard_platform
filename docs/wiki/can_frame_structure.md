# How is a CAN Frame Structured?
There are multiple variants of CAN exist currently, please refer the difference in the table below.

| Property | Fault-tolerant CAN<br>(low-speed CAN) | Classical CAN 2.0<br>(high-speed CAN) | CAN FD<br>(Flexible Data-rate) | CAN XL |
| :--- | :--- | :--- | :--- | :--- |
| **Max baud rate speed** | 0.125 Mbit/s | 1 Mbit/s | 8 Mbit/s (data phase) | 20 Mbit/s |
| **Max data payload size** | 8 bytes | 8 bytes | 64 bytes | 2048 bytes |
| **Baud rate type** | Fixed | Fixed | Variable (faster data field) | Variable (higher rates) |
| **Use cases** | Fault-tolerant, body control modules | Real-time automotive applications | High data throughput, ADAS, EV applications | Future high-data applications |
| **Key features** | Fault-tolerant operation, continue even if one bus line is damaged | Low cost, robust error detection, most commonly deployed | Increased payload, speed and reliability | Increased payload, speed and reliability |

Here, we talk about some details regarding classic CAN 2.0 with 11 bits idertifier. 
<div align="center">
  <img src="/docs/assets/CAN_Standard_Frame.svg" alt="Standard CAN Frame" width="90%">
  <p><i>Image Source: <a href="https://www.csselectronics.com/pages/can-bus-simple-intro-tutorial">CAN Bus Explained - A Simple Intro [2025] </a></i></p>
</div>

| Field | Full Name | Bits | Description |
| :--- | :--- | :--- | :--- |
| **SOF** | Start of Frame | 1 | The Start of Frame is a 'dominant 0' to tell the other nodes that a CAN node intends to talk. |
| **ID** | Standard Identifier | 11 | The ID is the frame identifier - **lower values have higher priority**. |
| **RTR** | Remote Transmission Request | 1 | The Remote Transmission Request indicates whether a node sends data or requests dedicated data from another node. |
| **Control** | Control Field | 6 | The Control contains the Identifier Extension Bit (IDE) which is a 'dominant 0' for 11-bit. It also contains the 4-bit Data Length Code (DLC) that specifies the length of the data bytes to be transmitted (0 to 8 bytes). |
| **Data** | Data Field | 0-64 | The Data contains the data bytes aka payload, which includes CAN signals that can be decoded for information. |
| **CRC** | Cyclic Redundancy Check | 16 | The Cyclic Redundancy Check is used to ensure data integrity. |
| **ACK** | Acknowledgement | 2 | The ACK slot indicates if the node has acknowledged and received the data correctly. |
| **EOF** | End of Frame | 7 | The EOF marks the end of the CAN frame. |

Raw CAN bus data is not human-readable. A DBC file, in this case, provided by OEM is designed for the engineers to decode raw CAN bus data into physical values.

> [!TIP]
> **Next Step: Decoding the Data Payload**  
> 
> How do we make sense of the raw bytes inside the CAN Frame `Data` field? 
> 
> ➡️ **[How to Understand a DBC File](./understand_dbc_file.md)**


<br/>
<p>
  <small><i>Reference: <a href="https://www.csselectronics.com/pages/can-bus-simple-intro-tutorial">CAN Bus Explained - A Simple Intro [2025]</a></i></small>
</p>