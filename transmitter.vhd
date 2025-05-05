library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity transmitter is
generic(
periodTb:integer := 208; -- Change to 500 for 100 kHz
periodTa:integer := 10); -- clock cycles for trigTa
port(
clk: in std_logic;
reset: in std_logic;
trigTb: buffer std_logic; -- 100kHz
trigTa: buffer std_logic;
trigTs: buffer std_logic; -- 10kHz
in_B: in std_logic; -- input from comparator: higher or lower?
Q: buffer std_logic_vector(7 downto 0); -- parallel output to flatcable
o_Dtx: out std_logic; -- to UART port on the FPGA
o_LEDS: out std_logic_vector(7 downto 0));
end entity;
architecture a_transmitter of transmitter is
signal counterTb: std_logic_vector(20 downto 0);
signal counterTa: std_logic_vector(20 downto 0);
type StateType is (U,SAR7,SAR6,SAR5,SAR4,SAR3,SAR2,SAR1,SAR0,STOP); -- list of
states
signal state: StateType;
signal r_Q_Data: std_logic_vector(9 downto 0);
signal B1: std_logic;
signal B: std_logic;
begin
-- Tb and Ta triggers
process(clk)
begin
if rising_edge(clk) then
if reset='0' then
counterTb <= (others => '0');
counterTa <= (others => '0');
else
if counterTb=periodTb-1 then
counterTb <= (others => '0');
trigTb <= '1';
if counterTa=periodTa-1 then
counterTa <= (others => '0');
trigTa <= '1';
else
counterTa <= counterTa+1;
trigTa <= '0';
end if;
else
counterTb <= counterTb+1;
trigTb <= '0';
end if;
end if;
end if;
end process;
-- Doube-clocking of B
process(clk)
begin
if rising_edge(clk) then
B1 <= in_B;
B <= B1;
end if;
end process;
-- SAR function process
process(clk)
begin
if rising_edge(clk) then
if trigTs = '1' then
state <= SAR7;
Q <= "10000000"; -- half of the maximum value
elsif trigTb = '1' then
case state is
when SAR7 =>
Q(7) <= B; -- MSB
Q(6) <= '1';
state <= SAR6;
when SAR6 =>
Q(6) <= B;
Q(5) <= '1';
state <= SAR5;
when SAR5 =>
Q(5) <= B;
Q(4) <= '1';
state <= SAR4;
when SAR4 =>
Q(4) <= B;
Q(3) <= '1';
state <= SAR3;
when SAR3 =>
Q(3) <= B;
Q(2) <= '1';
state <= SAR2;
when SAR2 =>
Q(2) <= B;
Q(1) <= '1';
state <= SAR1;
when SAR1 =>
Q(1) <= B;
Q(0) <= '1';
state <= SAR0;
when SAR0 =>
Q(0) <= B; -- LSB
state <= STOP;
when others => -- do nothing in STOP state
o_LEDS <= Q; -- Q to LEDs
end case;
end if;
end if;
end process;
-- Parallel to serial process
process(clk)
begin
if rising_edge(clk) then
if trigTs = '1' then
r_Q_Data(0) <= '0';
r_Q_Data(9) <= '1';
r_Q_Data(8 downto 1) <= Q;
elsif(trigTb = '1') then
r_Q_Data(8 downto 0) <= r_Q_Data(9 downto 1); -- Shift next bit into
place.
end if;
end if;
end process;
o_Dtx <= r_Q_Data(0);
-- Ts signal and-gate
trigTs <= trigTa and trigTb;
end architecture;
-- force clk 0 0ns, 1 10ns -repeat 20ns; force reset 0 0ns, 1 20ns;
-- force B 0 5000ns, 0 15000ns, 1 25000ns, 1 35000ns, 0 45000ns, 0 55000ns, 0
65000ns, 0 75000ns -repeat 100us
-- run 500us
