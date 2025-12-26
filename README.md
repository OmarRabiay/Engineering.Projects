
  

# UART‑Based Serial Data Transmitter and Receiver (VHDL)

  

**Alexandria University — Faculty of Engineering**

**Electrical Engineering Department — Communication and Electronics Program**

**Course:** ECE242: Digital Logic Design

**Instructor:** Dr. Nayera Sadek

**Date:** December 2025

  

**Team:** 
 
- Gannat Radwan Nour 
- Rawan Magdy Hassan
- Shaden Islam Ibrahim 
- Omar Islam Rabiay
- Abdullah Mohamed Elrweny
  

---

  

## Introduction

Serial communication is widely used in digital systems to transfer data efficiently using a **minimum number of connections**. **UART (Universal Asynchronous Receiver/Transmitter)** originated in the 1960s and remains common in microcontrollers and many electronic devices.

In this project, a **UART‑style system is implemented using VHDL**. The design ensures correct data transfer with error detection and displays the transmitted and received data on **seven‑segment displays** for easy monitoring.

  

### Operation Technique

-  **Load 7‑bit parallel data** into the transmitter when enabled.

-  **Compute an even parity bit** from the data for error checking.

-  **Construct a UART frame** with start bit, data bits, parity, and stop bit.

-  **Send the frame serially**, one bit per clock cycle.

-  **Receive the serial bits** and reconstruct them into parallel data.

-  **Compare received parity** with calculated parity to detect errors.

-  **Verify the stop bit** to ensure correct frame reception.

-  **Display the transmitted and received data** on seven‑segment displays.

  


  

---

  

## Serial Transmitter

**Input conditions**

-  `din(0..6)` — 7‑bit input data

-  `start_transmit = '1'` — start signal

-  `tx_busy = '0'` — transmitter ready to send new data

  

**Parity bit generation**

Even parity is computed by XOR of the seven data bits:

- Parity = `0` → even number of 1’s

- Parity = `1` → odd number of 1’s

  

**Frame construction**

The frame consists of: **Start(1)** + **7 Data bits** + **Parity** + **Stop(1)**, concatenated into a transmission register.

  

**Transmission process**

At each rising edge of `clk`, one bit from the frame is placed on `serial_out`, and a counter advances until all bits are sent.

  

**End of transmission**

After the stop bit, `tx_busy` is cleared, `serial_out` returns to idle (`'0'`), and the counter resets.

  

### Transmitter Code Snippet

```vhdl

	-- Transmitter

	process(clk)
		variable parity 	: std_logic;
	begin
		if rising_edge(clk) then
			if start_transmit = '1' and tx_busy = '0' then
				parity := din(0) xor din(1) xor din(2) xor
							 din(3) xor din(4) xor din(5) xor
							 din(6);

				tx_channel <= '1' & din & parity & '1';
				tx_busy <= '1';
				tx_cnt <= 0;

			elsif tx_busy = '1' then
				if tx_cnt < 10 then
					serial_out <= tx_channel(tx_cnt);
					tx_cnt <= tx_cnt + 1;
				else
					tx_busy <= '0';
					serial_out <= '0';
					tx_cnt <= 0;
				end if;
			end if;
		end if;
	end process;

	tx_byte(6 downto 0) <= din;
	tx_byte(7) <= '0';
	
	serial_in <= serial_out;

```

  

---

  

## Serial Receiver

**Idle state**

The receiver waits for a new frame (`rx_busy = '0'`). When a frame starts, `data_valid` and `err` are cleared, `rx_busy` is set, and the bit counter resets.

  

**Data reception**

Seven data bits are sampled sequentially and stored in `temp_data(rx_cnt)` while `rx_cnt` increments.

  

**Parity checking**

After the data bits, parity is recomputed (`tparity`) and compared to the received parity bit (`rparity`).

  

**Stop bit verification & frame validation**

If parity matches and the stop bit is correct, `data_valid` is set; otherwise `err = '1'`.

  

**Data output**

The 7‑bit data appears on `data(0..6)` and is mirrored to `rx_byte` (MSB = 0) for display.

  

### Receiver Code Snippet

```vhdl

-- Receiver
 
	process(clk)
		variable rparity 	: std_logic;
		variable tparity 	: std_logic;
	begin
		if rising_edge(clk) then
			if serial_in = '1' and rx_busy = '0' then
				data_valid <= '0';
				err <= '0';
				rx_busy <= '1';
				rx_cnt <= 0;

			elsif rx_busy = '1' then
				if rx_cnt < 7 then
					temp_data(rx_cnt) <= serial_in;
					rx_cnt <= rx_cnt + 1;

				elsif rx_cnt = 7 then
					tparity := temp_data(0) xor temp_data(1) xor temp_data(2) xor
								  temp_data(3) xor temp_data(4) xor temp_data(5) xor
								  temp_data(6);
					rparity := serial_in;
					rx_cnt <= rx_cnt + 1;

				elsif rx_cnt = 8 then
					if rparity = tparity and serial_in = '1' then
						data_valid <= '1';
						err <= '0';
					else
						data_valid <= '0';
						err <= '1';
					end if;

					rx_busy <= '0';
					rx_cnt <= 0;
				end if;
			end if;
		end if;
	end process;

	data <= temp_data;
	
	rx_byte(6 downto 0) <= temp_data;
	rx_byte(7) <= '0';
	
```

  

---

  

## Integration of Transmitter and Receiver

- Transmitter and receiver are implemented in the **same UART module**.

-  `serial_out` is **looped back internally** to `serial_in`.

- The receiver reconstructs the data and checks parity and stop bit.

- Valid data raises `data_valid`; errors raise `err`.

- Integration simplifies **verification and testing**.

  

---

  

## Seven‑Segment Hex Display

The 7‑segment section shows **TX** and **RX** bytes on **four displays** using **time‑multiplexing**.

  

### Splitting bytes into 4‑bit groups

-  `tx_hi` / `rx_hi` — most significant 4 bits

-  `tx_lo` / `rx_lo` — least significant 4 bits

  

Each nibble represents a single hexadecimal digit (0–F).

  

### Display multiplexing

`display_cnt` cycles through `"00" → "01" → "10" → "11"`, each value enabling one display via `en` and selecting a nibble for `hex_digit`.

  

### Hexadecimal to 7‑segment conversion

Each 4‑bit `hex_digit` is decoded to the 7‑bit `seg(a..g)` control.

  

### 7‑Segment Driver Code Snippet

```vhdl

-- 7 Segment Display
	
	tx_hi <= tx_byte(7 downto 4);
	tx_lo <= tx_byte(3 downto 0);
	rx_hi <= rx_byte(7 downto 4);
	rx_lo <= rx_byte(3 downto 0);

	process(clk)
	begin
		if rising_edge(clk) then
			case display_cnt is
				when "00" => display_cnt <= "01";
				when "01" => display_cnt <= "10";
				when "10" => display_cnt <= "11";
				when others => display_cnt <= "00";
			end case;
		end if;
	end process;

	process(display_cnt)
	begin
		case display_cnt is
			when "00" =>
				en <= "1110";
				hex_digit <= rx_lo;
			when "01" =>
				en <= "1101";
				hex_digit <= rx_hi;
			when "10" =>
				en <= "1011";
				hex_digit <= tx_lo;
			when others =>
				en <= "0111";
				hex_digit <= tx_hi;
		end case;
	end process;

	process(hex_digit)
	begin
		case hex_digit is
			when "0000" => seg <= "1111110"; -- 0
			when "0001" => seg <= "0110000"; -- 1
			when "0010" => seg <= "1101101"; -- 2
			when "0011" => seg <= "1111001"; -- 3
			when "0100" => seg <= "0110011"; -- 4
			when "0101" => seg <= "1011011"; -- 5
			when "0110" => seg <= "1011111"; -- 6
			when "0111" => seg <= "1110010"; -- 7
			when "1000" => seg <= "1111111"; -- 8
			when "1001" => seg <= "1111011"; -- 9
			when "1010" => seg <= "1110111"; -- A
			when "1011" => seg <= "0011111"; -- b
			when "1100" => seg <= "1001110"; -- C
			when "1101" => seg <= "0111101"; -- d
			when "1110" => seg <= "1001111"; -- E
			when "1111" => seg <= "1000111"; -- F
			when others => seg <= "0000000"; -- off
		end case;
	end process;
```

  

---

  

## Full Code

```vhdl

library ieee;
use ieee.std_logic_1164.all;

entity UART_7seg is
	port (clk            : in  std_logic;
			start_transmit : in  std_logic;
			din            : in  std_logic_vector(0 to 6);

			seg            : out std_logic_vector(6 downto 0);
			en             : out std_logic_vector(3 downto 0);
			zero				: out std_logic := '0';

			data           : out std_logic_vector(0 to 6);
			err            : out std_logic := '0';
			data_valid     : out std_logic := '0');
end UART_7seg;

architecture Behave of UART_7seg is

signal tx_channel	 	: std_logic_vector(0 to 9);
signal tx_cnt    		: integer range 0 to 10 := 0;
signal tx_busy    	: std_logic := '0';

signal rx_cnt     	: integer range 0 to 10 := 0;
signal rx_busy    	: std_logic := '0';

signal temp_data  	: std_logic_vector(0 to 6);
signal serial_out 	: std_logic := '0';
signal serial_in  	: std_logic := '0';

signal tx_byte 		: std_logic_vector(7 downto 0);
signal rx_byte 		: std_logic_vector(7 downto 0);

signal tx_hi, tx_lo 	: std_logic_vector(3 downto 0);
signal rx_hi, rx_lo 	: std_logic_vector(3 downto 0);

signal display_cnt	: std_logic_vector(1 downto 0) := "00";
signal hex_digit   	: std_logic_vector(3 downto 0);

begin

	-- Transmitter

	process(clk)
		variable parity 	: std_logic;
	begin
		if rising_edge(clk) then
			if start_transmit = '1' and tx_busy = '0' then
				parity := din(0) xor din(1) xor din(2) xor
							 din(3) xor din(4) xor din(5) xor
							 din(6);

				tx_channel <= '1' & din & parity & '1';
				tx_busy <= '1';
				tx_cnt <= 0;

			elsif tx_busy = '1' then
				if tx_cnt < 10 then
					serial_out <= tx_channel(tx_cnt);
					tx_cnt <= tx_cnt + 1;
				else
					tx_busy <= '0';
					serial_out <= '0';
					tx_cnt <= 0;
				end if;
			end if;
		end if;
	end process;

	tx_byte(6 downto 0) <= din;
	tx_byte(7) <= '0';
	
	serial_in <= serial_out;

	-- Receiver
 
	process(clk)
		variable rparity 	: std_logic;
		variable tparity 	: std_logic;
	begin
		if rising_edge(clk) then
			if serial_in = '1' and rx_busy = '0' then
				data_valid <= '0';
				err <= '0';
				rx_busy <= '1';
				rx_cnt <= 0;

			elsif rx_busy = '1' then
				if rx_cnt < 7 then
					temp_data(rx_cnt) <= serial_in;
					rx_cnt <= rx_cnt + 1;

				elsif rx_cnt = 7 then
					tparity := temp_data(0) xor temp_data(1) xor temp_data(2) xor
								  temp_data(3) xor temp_data(4) xor temp_data(5) xor
								  temp_data(6);
					rparity := serial_in;
					rx_cnt <= rx_cnt + 1;

				elsif rx_cnt = 8 then
					if rparity = tparity and serial_in = '1' then
						data_valid <= '1';
						err <= '0';
					else
						data_valid <= '0';
						err <= '1';
					end if;

					rx_busy <= '0';
					rx_cnt <= 0;
				end if;
			end if;
		end if;
	end process;

	data <= temp_data;
	
	rx_byte(6 downto 0) <= temp_data;
	rx_byte(7) <= '0';
	
	-- 7 Segment Display
	
	tx_hi <= tx_byte(7 downto 4);
	tx_lo <= tx_byte(3 downto 0);
	rx_hi <= rx_byte(7 downto 4);
	rx_lo <= rx_byte(3 downto 0);

	process(clk)
	begin
		if rising_edge(clk) then
			case display_cnt is
				when "00" => display_cnt <= "01";
				when "01" => display_cnt <= "10";
				when "10" => display_cnt <= "11";
				when others => display_cnt <= "00";
			end case;
		end if;
	end process;

	process(display_cnt)
	begin
		case display_cnt is
			when "00" =>
				en <= "1110";
				hex_digit <= rx_lo;
			when "01" =>
				en <= "1101";
				hex_digit <= rx_hi;
			when "10" =>
				en <= "1011";
				hex_digit <= tx_lo;
			when others =>
				en <= "0111";
				hex_digit <= tx_hi;
		end case;
	end process;

	process(hex_digit)
	begin
		case hex_digit is
			when "0000" => seg <= "1111110"; -- 0
			when "0001" => seg <= "0110000"; -- 1
			when "0010" => seg <= "1101101"; -- 2
			when "0011" => seg <= "1111001"; -- 3
			when "0100" => seg <= "0110011"; -- 4
			when "0101" => seg <= "1011011"; -- 5
			when "0110" => seg <= "1011111"; -- 6
			when "0111" => seg <= "1110010"; -- 7
			when "1000" => seg <= "1111111"; -- 8
			when "1001" => seg <= "1111011"; -- 9
			when "1010" => seg <= "1110111"; -- A
			when "1011" => seg <= "0011111"; -- b
			when "1100" => seg <= "1001110"; -- C
			when "1101" => seg <= "0111101"; -- d
			when "1110" => seg <= "1001111"; -- E
			when "1111" => seg <= "1000111"; -- F
			when others => seg <= "0000000"; -- off
		end case;
	end process;
	
end Behave;
```

  

---

  

## Verification & Implementation

-  **Simulation:** Verified in **ModelSim** to confirm correct reception and reliable error detection.

-  **Hardware:** Implemented and tested on the **CI 33004 CPLD development board**, with correct behavior observed on real hardware.

  

---

  

## Key Takeaways

- Hands‑on experience with **RTL design in VHDL**

- Stronger understanding of **UART serial communication**

- Practical exposure to **synchronous digital systems**

- Appreciation of how effective **teamwork** enables complex digital systems

  

---

  

## Notes

- The framing used here is synchronous and tailored to the included receiver logic. For standard asynchronous UART interoperability, add a **baud generator** and **oversampling** and use the conventional **idle=1, start=0, stop=1** framing.

  

---

  

