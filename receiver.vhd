library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity receiver is
generic(
tbperiod:integer := 208); --Change to 500 for 100 kHz
port(
reset, cp2: in std_logic;
in_DRx: in std_logic;
Q2: buffer std_logic_vector(7 downto 0);
Tb2: buffer std_logic;
Ts2: buffer std_logic;
o_LEDS: out std_logic_vector(7 downto 0));
end entity;
architecture a_receiver of receiver is
type StateType is (U,STOP,START,TRIG);
signal state: StateType;
signal counter: std_logic_vector(20 downto 0); --time between trigpulses Tb
signal bitcounter: std_logic_vector(20 downto 0); --controls number of trigpulses
signal r_Q2_data: std_logic_vector(7 downto 0);
signal DRx1: std_logic;
signal DRx: std_logic;
begin
-- Doube-clocking of in_DRx
process(cp2)
begin
if rising_edge(cp2) then
DRx1 <= in_DRx;
DRx <= DRx1;
end if;
end process;
process(cp2)
begin
if rising_edge(cp2) then
if reset='0' then
state <= STOP;
else
Tb2 <= '0'; -- default
Ts2 <= '0';
case state is
when STOP => -- wait for stop bit '1'
if DRx='1' then
state <= START;
end if;
when START => -- wait for start bit '0'
if DRx='0' then
state <= TRIG;
counter <= (others => '0');
bitcounter <= (others => '0');
end if;
when others => -- state TRIG
counter <= counter+1;
if counter=tbperiod/2-1 then
Tb2 <= '1';
bitcounter <= bitcounter+1;
if bitcounter=9 then
Ts2 <= '1';
bitcounter <= (others => '0');
state <= STOP;
end if;
elsif counter=tbperiod-1 then
counter <= (others => '0');
end if;
end case;
end if;
end if;
end process; -- trig signals
-- Serial to parallel process
process(cp2)
begin
if rising_edge(cp2) then
if Ts2 = '1' then
Q2 <= r_Q2_data;
elsif(Tb2 = '1') then
r_Q2_data(6 downto 0) <= r_Q2_data(7 downto 1); -- Shift next bit into
place.
r_Q2_data(7) <= DRx;
end if;
end if;
end process;
o_LEDS <= Q2;
end architecture;
--force cp2 0 0ns, 1 10ns -repeat 20ns
--force in_Drx 0 50us, 1 100us -repeat 100us
--force reset 0 0ns, 1 40ns
--run 500us
