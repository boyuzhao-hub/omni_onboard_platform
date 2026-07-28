# What is Serializaiton in ROS2?

## RMW & DDS  
**RMW** stands for **ROS Middlewar Interface**, which handles the interaction betwen Operating System and User Code. It acts as an abstraction layer, hiding the complex details of the underlying network implementation from the user.

<div align="center">
  <img src="/docs/assets/ROS_2_Architecture_Overivew.drawio.svg" alt="ROS 2 Architecture" width="70%">
  <p><i>Figure 1: ROS 2 Architecture Overview</i></p>
</div>

- **DDS:** A decentralized, publish-subscribe communication protocol.
- **RMW:** The ROS Middleware Interface that hides the details of the specific DDS implementations.
- **rclcpp:** The C++ client library designed for efficiency and fast response times.
- **rclpy:** The Python client library ideal for prototyping and shorter development times.

**DDS** stands for **Data Distribution Service**. It is a communication protocol standard designed for real-time and scalable data distribution in distributed systems. 

A fundamental aspect of DDS is **QoS** (Quality of Service). QoS allows developers to implement fine-grained control over the characteristics and behavior of data communication (e.g., reliability, history, and durability). The available QoS option can be found [**here (QoS Compatibilities)**](https://docs.ros.org/en/humble/Concepts/Intermediate/About-Quality-of-Service-Settings.html#qos-compatibilities).

The concepts and design of DDS are illustrated below:

| DDS Overview | Publish-Subscribe Design |
| :---: | :---: |
| <img src="/docs/assets/ROS_2_DDS_Overview.jpg" alt="DDS Overview" width="100%"> | <img src="/docs/assets/ROS_2_DDS_publish_subscribe.webp" alt="DDS Publish-Subscribe Design" width="100%"> |

> [!NOTE]
> ### 📚 Further Reading
> 
> * 📖 **[Introduction to DDS](https://erhanbakirhan.medium.com/introduction-to-dds-data-distribution-service-real-time-data-communication-made-easy-d6f4badddd6f)**
>   *An overview of Data Distribution Service and real-time communication.*
> * ⚙️ **[Creating an RMW Implementation](https://docs.ros.org/en/humble/Tutorials/Advanced/Creating-An-RMW-Implementation.html)**
>   *Official ROS 2 Humble tutorial on middleware integration.*

## Serialization

Now that we understand RMW and DDS, we can answer the main question. Before a ROS 2 message (like a C++ struct or a Python object) can be sent over the network via DDS, it must be converted into a format suitable for transmission. 

- **Serialization** is the process of converting in-memory data structures (your ROS 2 messages) into a linear byte stream. 
- **Deserialization** is the reverse process: taking that byte stream from the network and reconstructing the original data structure in the receiving node's memory.

### How it works in ROS 2:
1. **Message Definition:** You define a message using ROS 2 `.msg` files.
2. **Type Support (`rosidl`):** ROS 2 uses a code generation pipeline (`rosidl`) to create "Type Support" structures for these messages.
3. **The Handoff:** When you call `publisher->publish(msg)`, your user code passes the in-memory object down to the RMW layer.
4. **Serialization via CDR:** The RMW layer invokes the specific DDS vendor's serialization functions. Most DDS implementations use **CDR (Common Data Representation)** as their standard binary serialization format. The message is serialized into a CDR byte stream and transmitted over the network.

By handling serialization at the middleware layer, ROS 2 ensures that a node written in C++ running on Linux can seamlessly communicate with a node written in Python running on Windows or vice versa, as they both agree on how the data is packed and unpacked.