library ieee;
use ieee.std_logic_1164.all;

entity UART is
	port (clk            : in  std_logic;
			start_transmit : in  std_logic;
			din            : in  std_logic_vector(0 to 6);

			seg            : out std_logic_vector(6 downto 0);
			en             : out std_logic_vector(3 downto 0);
			zero				: out std_logic := '0';

			data           : out std_logic_vector(0 to 6);
			err            : out std_logic := '0';
			data_valid     : out std_logic := '0');
end UART;

architecture Behave of UART is

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
