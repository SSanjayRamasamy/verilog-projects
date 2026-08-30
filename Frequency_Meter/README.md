# FPGA-Based Frequency Meter

## Overview

This project implements an FPGA-based frequency meter using the **EDGE Zynq-7020 development board**. The system measures the frequency of an input signal by converting it into a digital pulse waveform, counting the pulses over a fixed time interval, and displaying the measured frequency on a four-digit seven-segment display.

The analog input signal is first conditioned to make it compatible with the FPGA input. The FPGA then uses a **1-second measurement window**, where the number of detected input cycles directly represents the frequency in Hertz.

## Signal Conditioning

The input signal is processed through an analog signal-conditioning stage before being connected to the FPGA.

An **LM339 comparator** converts the input analog waveform into a digital pulse train while preserving its frequency information. The output is then passed through an **MCP6021-based level-shifting stage** to ensure that the signal voltage is within the **0–3.3 V range**, making it suitable for the FPGA input pins.

The conditioned digital signal is then provided to the FPGA for frequency measurement.

## Verilog Modules

### `frequency_counter`

This is the main frequency measurement module.

The FPGA operates using a **50 MHz system clock**. A clock counter generates a **1-second timing flag (`sec_flag`)**, which defines the measurement window.

The input signal (`async_in`) is sampled using the FPGA clock and monitored for state transitions. The module detects complete cycles of the input waveform and increments the pulse counter accordingly.

At the end of every 1-second interval:

* The pulse count is stored in `freq`
* The counter is reset
* A new measurement cycle begins

Since the measurement window is one second, the number of counted cycles directly represents the input frequency in Hertz.

### `digit_spliter`

The measured frequency is stored as a binary value. The `digit_spliter` module separates this value into individual decimal digits.

The frequency value is divided into:

* Units
* Tens
* Hundreds
* Thousands

Each digit is represented using 4 bits and combined into a 16-bit output bus for the seven-segment display module.

### `clk_divider`

The seven-segment display requires a slower clock for digit multiplexing.

The `clk_divider` module divides the **50 MHz FPGA system clock** to generate a **10 kHz clock**. This clock is used to periodically switch between the display digits fast enough for them to appear continuously illuminated.

### `seg7_decoder`

This module converts a 4-bit decimal digit into the corresponding seven-segment display pattern.

It supports decimal digits from **0 to 9** and generates the required output signals for the seven segments (`a` to `g`).

### `seven_seg`

This module controls the four-digit seven-segment display using multiplexing.

The module:

* Uses the divided clock to cycle through the four display positions
* Selects one digit at a time
* Sends the corresponding decimal value to the `seg7_decoder`
* Enables the appropriate seven-segment display

By rapidly switching between all four digits, the complete frequency value appears continuously on the display.

### `top`

The `top` module integrates all the individual modules.

The overall data flow is:


## Hardware Platform

* **FPGA Board:** EDGE Zynq-7020
* **Comparator:** LM339
* **Level-Shifting Circuit:** MCP6021
* **Display:** Four-Digit Seven-Segment Display

## Project Summary

This project demonstrates the integration of analog signal conditioning with FPGA-based digital signal measurement. The conditioned input waveform is converted into a pulse train, measured using a Verilog-based frequency counter, converted into decimal digits, and displayed in real time on a seven-segment display.
