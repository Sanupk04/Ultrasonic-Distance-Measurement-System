# Ultrasonic-Distance-Measurement-System
# Ultrasonic Distance Measurement System

An embedded systems project implementing a non-contact distance measurement system using an HC-SR04 ultrasonic sensor, developed as part of the ECE322 Embedded Systems course at IIIT Kottayam.

---

## About

This project implements the same core system on two different microcontroller platforms — ARM Cortex-M3 (LPC1343) and 8051 (AT89C51) — to compare their performance and understand low-level hardware-software integration.

The system measures distance using the **time-of-flight (TOF)** principle:
- A trigger pulse is sent to the HC-SR04 sensor
- The sensor emits ultrasonic waves and waits for the echo
- The microcontroller measures echo duration using internal timers
- Distance is calculated as: `Distance = (Time × Speed of Sound) / 2`
- Result is displayed in real time on a 16×2 LCD

---

## Implementations

### 1. ARM Cortex-M3 — LPC1343
- `LPC1343_embedded_c.c` — Embedded C implementation
- `LPC1343_assembly.s` — ARM Thumb Assembly implementation
- Uses **Timer32** for high-resolution echo timing
- LCD interfaced in 8-bit mode via GPIO Port 1 and Port 2
- Built-in pull-up resistors — no external resistor pack needed

### 2. 8051 — AT89C51
- `8051_embedded_c.c` — Embedded C implementation
- `8051_assembly.asm` — 8051 Assembly implementation
- Uses **Timer0 in Mode 1** (16-bit) for echo timing
- LCD data bus on Port 2, control pins on Port 0
- External resistor pack required on Port 0 (open-drain)

---

## Hardware Components

| Component | Details |
|---|---|
| Ultrasonic Sensor | HC-SR04 |
| Microcontroller 1 | LPC1343 (ARM Cortex-M3) |
| Microcontroller 2 | AT89C51 (8051) |
| Display | 16×2 LCD (LM016L) |
| Power Supply | 5V DC |

---

## Software Tools

| Tool | Purpose |
|---|---|
| Keil µVision | Code development and compilation |
| Proteus | Circuit simulation and validation |

---

## Pin Connections

### LPC1343
| Signal | LPC1343 Pin | Direction |
|---|---|---|
| LCD Data (D0–D7) | PIO1.0 – PIO1.7 | Output |
| LCD RS | PIO2.0 | Output |
| LCD RW | PIO2.1 | Output |
| LCD EN | PIO2.2 | Output |
| TRIG | PIO3.0 | Output |
| ECHO | PIO3.1 | Input |

### 8051
| Signal | 8051 Pin | Direction |
|---|---|---|
| LCD Data (D0–D7) | P2.0 – P2.7 | Output |
| LCD RS | P0.0 | Output |
| LCD RW | P0.1 | Output |
| LCD EN | P0.2 | Output |
| TRIG | P3.5 | Output |
| ECHO | P3.2 | Input |

---

## How It Works

```
1. Microcontroller sends 10µs trigger pulse to HC-SR04
2. Sensor emits 8 ultrasonic bursts at 40kHz
3. ECHO pin goes HIGH when wave is transmitted
4. ECHO pin goes LOW when reflected wave is received
5. Timer measures the HIGH duration of ECHO
6. Distance = (Timer Count × Speed of Sound) / 2
7. Result displayed on LCD in centimeters
```

---

## Results

Both implementations were successfully simulated in Proteus:
- ARM Cortex-M3 (LPC1343): Higher precision due to faster clock and Timer32
- 8051 (AT89C51): Reliable readings with Timer0, centimeter-level accuracy

Accuracy: typically within ±1 cm for short-range measurements (2–400 cm)

---

## Skills Demonstrated

- Embedded C programming
- ARM Thumb Assembly and 8051 Assembly
- Sensor interfacing (HC-SR04)
- Timer/counter configuration
- LCD interfacing (8-bit mode)
- GPIO control
- Simulation using Proteus and Keil µVision

---

## Author

**Sanu P K**  
B.Tech Electronics and Communication Engineering  
Indian Institute of Information Technology Kottayam  
