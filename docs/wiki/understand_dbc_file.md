# Understand the dbc file

> [!NOTE]  
> This article focuses on decoding the **Data field** of a CAN frame. If you are not familiar with the structure of a CAN message, please check the previous article: 
> ⬅️ **[How is a CAN Frame Structured?](./can_frame_structure.md)**  
> A detailed instruction regarding Continental SRR308-21 Radar used in this project can be found in [SRR308 Configuration Handbook](/docs/wiki/srr308_configuration_handbook.md).

A CAN DBC file is a text file that contains information for decoding raw CAN data, which are defined different from different OEM. The following fields are normally used in DBC file. For Python programming, [```cantools```](https://cantools.readthedocs.io/en/latest/) is a package to parse the CAN BUS data. 
- **NS_** (New Symbol) Claim the keywords that will be used in the dbc file.
- **BS_** (Bus Speed) Define the Baud Rate of the CAN Bus. Normally it is configured in through hardware or ROS2 Driver.
- **BU_** (Bus Unit) Define the ECU or hardware name that connected to the CAN Bus.
- **BO_** (Message) Define the message of one CAN Bus frame, include **message id**, **message name**, **data length (bytes)**, and **transmitter**. 
  - Syntax: ```B0_ [MessageID] [Message Name]: [DLC] [Transmitter]```
  - For example: ```BO_ 1579 Obj_1_General_2: 8 SRR308```
    - ```1579``` is CAN ID in decimal.
    - ```Obj_1_General_2``` is the name of the message.
    - ```8``` this frmae of CAN message include 8 bytes。
    - ```SRR308``` this message is sent by radar SRR308.
- **SG_** (Signal) Define what physical value does one range of bits in this message represent, include **signal name**, **start bit|length@byte order+value type**, **(factor, offset)**,**minimum|maximum**,**unit**, **receiver**.
  - Syntax ```SG_ [SignalName] : [StartBit]|[Length]@[ByteOrder][ValueType] ([Factor],[Offset]) [[Min]|[Max]] "[Unit]" [Receiver]```
  - For example: ```SG_ Obj_VrelLat : 45|9@0+ (0.25,-64) [-64|63.75] "m/s"  ExternalUnit```
    - ```Obj_VrelLat``` Name of the signal. Object relative lateral velocity.
    - ```45|9``` Start from no. 45 bit, occupied 9 bits.
    - ```@0``` represents Motorola format.
    - ```+``` stands for Unsigned.
    - ```(0.25,-64)``` Physical Value = Raw Value $\times$ 0.25 + (-64).
    - ```[-64|63.75]``` the valid range of this physical value.
    - ```m/s``` unit.
    - ```ExternalUnit``` Reveiver of this signal is an external unit.
- **CM_** (Comment) the comment of message, signal for human reading.
- **VAL_** (Value Table) map the numbers into a string with actual meanings.
  - Syntax ```VAL_ [MessageId] [SignalName] [Value1] "[String1]" [Value2] "[String2]" ... ;```
  - For example ```VAL_ 1661 Obj_Class 7 "Description for the value '0x7'" 6 "Wide" 5 "Bicycle" 4 "Motorcycle" 3 "Pedestrian" 2 "Truck" 1 "Car" 0 "Point" ;```
    - If ```Obj_Class``` is ```1```, then the object is a Car. 
  
- **EV_** (Environment Variable) Vitural Variable that only for simulation.
- **VAL_TABLE_** (Value Table) A table that for global lookup.
  - Syntax ```VAL_TABLE_ [TableName] [Value1] "[String1]" [Value2] "[String2]" ...;```

<br/>
<p>
  <small><i>A good reference: <a href="https://www.csselectronics.com/pages/can-dbc-file-database-intro">CAN DBC File Introduction</a></i></small>
</p>