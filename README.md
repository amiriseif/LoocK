# SmartLock Project

This project is developed during Labs of the subject IoT Architecture

By:
- **Amiri Seif Eddine**
- **Adam Becheikh**

Under-graduated students,  
Embedded Systems and IoT Bachelors

Under the supervision of:  
**Hanen KARAMTI**,  
Computer Science, Assistant Professor,  
Higher Institute of Multimedia Arts of Manouba (ISAMM),  
University of Manouba Tunisia

---

## Project title:
**SmartLock System Using Raspberry Pi**

## Description:
The SmartLock system is designed to enhance door security using a Raspberry Pi and is controlled through both a mobile application and a keypad. Each resident has a unique code for identification, and access can be managed remotely via the mobile app. The system records the status of the door and includes a doorbell for visitors, which is detectable from the app.

In case of three incorrect code attempts, the doorbell continues to ring until the correct code is entered or the alert is stopped through the mobile app.

## Problem statement and objectives:
This project aims to provide a smart door locking mechanism that combines ease of use and robust security. It allows residents to manage access via mobile app or keypad while ensuring unauthorized access attempts are handled securely.

### Objectives:
- Ensure easy remote access through a mobile app.
- Provide unique identification for each resident.
- Implement a notification system for visitor access requests and security alerts.
- Enhance security by alerting residents after failed entry attempts.

---

## Requirements (both hardware and software):
### Hardware:
- Raspberry Pi
- Keypad
- Motorized lock
- Doorbell
- Sensors for door status (open/closed)
- Android mobile device
- Wi-Fi connection for app communication

### Software:
- Python code for controlling Raspberry Pi
- Android app for remote control and notifications
- Database for storing resident codes and door activity
- Notification system (e.g., Firebase)

---

## Instructions for equipment installation:
1. **Raspberry Pi Setup:**
   - Install the Raspberry Pi OS and set up GPIO pins for the keypad, door lock, and doorbell.
   
2. **Keypad and Lock Mechanism:**
   - Connect the keypad to the Raspberry Pi to handle code inputs.
   - Attach the motorized lock to the door and link it to the Raspberry Pi.

3. **Mobile Application:**
   - Install the SmartLock Android app on residents' phones.
   - Ensure the app connects to the Raspberry Pi over the network.

4. **Testing and Configuration:**
   - Test door lock functionality using both the keypad and the mobile app.
   - Simulate incorrect code inputs and check that the alert system responds correctly.

