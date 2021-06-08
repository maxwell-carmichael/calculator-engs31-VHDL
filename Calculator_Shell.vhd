----------------------------------------------------------------------------------
-- Company: ENGS031/COSC056
-- Engineer: Max Carmichael and Alex Carney
-- 
-- Create Date: 05/13/2021 09:52:28 PM
-- Design Name: 
-- Module Name: Calculator_Shell - Structural
-- Project Name: 
-- Target Devices: 
-- Tool Versions: Vivado 2018.3.1
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library UNISIM;					-- needed for the BUFG component
use UNISIM.Vcomponents.ALL;

entity Calculator_Shell is
    Port (  clk     : in  STD_LOGIC;					-- 100 MHz board clock
            RsRx    : in  STD_LOGIC;                    -- Rx input
    --7 Segment Display
            seg	: out STD_LOGIC_vector(0 to 6);
            dp  : out STD_LOGIC;
            an 	: out STD_LOGIC_vector(3 downto 0) );				
end Calculator_Shell;


architecture Structural of Calculator_Shell is

-- Signals for the 100 MHz to 10 MHz clock divider
constant CLOCK_DIVIDER_VALUE: integer := 5;
signal clkdiv: integer := 0;			-- the clock divider counter
signal clk_en: STD_LOGIC := '0';		-- terminal count
signal clk10: STD_LOGIC;				-- 10 MHz clock signal

-- Signals for Calculator_SCI
signal rx_data : STD_LOGIC_vector(7 downto 0);
signal rx_done_tick : STD_LOGIC;
signal rx_isnumber  : STD_LOGIC;
signal rx_isreturn  : STD_LOGIC;
signal rx_isoper    : STD_LOGIC;
signal rx_isequals  : STD_LOGIC;
signal rx_isclear   : STD_LOGIC;

-- Signals for Converter
signal conv_Clear  :   STD_LOGIC   := '0';
signal conv_Data_out         :   STD_LOGIC_VECTOR(31 downto 0)  :=  (others => '0');
signal Enable       :   std_logic := '0';

-- Signals for Calculator
-- signal conv_Data_in         :   STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal conv_Data_ready      :   STD_LOGIC := '0';
signal disp             :   STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal conv_en          :   std_logic := '0';
signal small_disp       :   STD_LOGIC_VECTOR(13 downto 0) := (others => '0');


-- Signals for 7 segment display
signal calc_display     : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Calculator_SCI
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
COMPONENT Calculator_SCI
	PORT(
		Clk         : IN STD_LOGIC;
		RsRx        : IN STD_LOGIC;      
		rx_data     :  out STD_LOGIC_vector(7 downto 0);
		rx_done_tick : out STD_LOGIC;
        
        rx_isnumber :   out STD_LOGIC;
        rx_isreturn :   out STD_LOGIC;
        rx_isoper   :   out STD_LOGIC;
        rx_isclear  :   out STD_LOGIC;
        rx_isequals :   out STD_LOGIC );  
	END COMPONENT;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Calculator_Converter
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
COMPONENT Converter is
    Port ( 
            clk, Push, Clear	    : 	in 	STD_LOGIC;
            Data_in					:	in	std_logic_vector(7 downto 0) := (others => '0');
            Data_ready              :   out std_logic;
            Enable                  :   in  std_logic;
            Data_out				:	out	std_logic_vector(31 downto 0) := (others => '0')
    );
    END COMPONENT;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Calculator_Calculator
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
COMPONENT Calculator IS
PORT (	clk 				 	: 	in 	STD_LOGIC;
		
        rx_Data_in				:	in std_logic_vector(7 downto 0) := (others => '0');
        rx_Data_ready			:	in std_logic; 
        
        conv_Data_in			:	in	std_logic_vector(31 downto 0) := (others => '0');
		conv_Data_ready			:	in	std_logic;
        
        rx_isreturn, rx_isoper, rx_isequals, rx_isclear :	in	std_logic;
        
        
        conv_en             :   out std_logic;
        disp				: 	out std_logic_vector(31 downto 0)
        
        );
end COMPONENT;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--7 Segment Display
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component mux7seg is
    Port ( 	clk : in  STD_LOGIC;
           	y0, y1, y2, y3 : in  STD_LOGIC_VECTOR (3 downto 0);	
           	dp_set : in STD_LOGIC_vector(3 downto 0);					
           	seg : out  STD_LOGIC_VECTOR (0 to 6);	
          	dp : out STD_LOGIC;
           	an : out  STD_LOGIC_VECTOR (3 downto 0) );			
end component;


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- number to bcd
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
COMPONENT blk_mem_gen_1
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(13 downto 0);
    douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END COMPONENT;

-------------------------
BEGIN

-- Clock buffer for 10 MHz clock
-- The BUFG component puts the slow clock onto the FPGA clocking network
Slow_clock_buffer: BUFG
      port map (I => clk_en,
                O => clk10 );

-- Divide the 100 MHz clock down to 20 MHz, then toggling the 
-- clk_en signal at 20 MHz gives a 10 MHz clock with 50% duty cycle
Clock_divider: process(clk)
begin
	if rising_edge(clk) then
	   	if clkdiv = CLOCK_DIVIDER_VALUE-1 then 
	   		clk_en <= NOT(clk_en);		
			clkdiv <= 0;
		else
			clkdiv <= clkdiv + 1;
		end if;
	end if;
end process Clock_divider;

------------------------------
-- PORT MAPS
------------------------------
-- Calculator_SCI port map
Receiver : Calculator_SCI PORT MAP(
    Clk => clk10,				-- receiver is clocked with 10 MHz clock
    RsRx => RsRx,
    rx_data => rx_data,
    rx_done_tick => rx_done_tick,
    rx_isnumber => rx_isnumber,
    rx_isreturn => rx_isreturn,
    rx_isoper => rx_isoper,
    rx_isclear => rx_isclear,
    rx_isequals => rx_isequals );

-- Converter port map
Stack : Converter PORT MAP ( 
    clk => clk10,
    Push => rx_done_tick,
    Clear => conv_Clear,
    Data_in => rx_data,
    Data_ready => conv_Data_ready,
    Data_out => conv_Data_out,
    Enable => conv_en
     );


-- Calculator port map
Calc : Calculator PORT MAP(
    clk => clk10,
    rx_Data_in => rx_data,
    rx_Data_ready => rx_done_tick,
    conv_Data_in => conv_Data_out,
    conv_Data_ready => conv_Data_ready,
    rx_isreturn => rx_isreturn,
    rx_isoper => rx_isoper,
    rx_isequals => rx_isequals,
    rx_isclear => rx_isclear,
    disp => disp,
    conv_en => conv_en
     );



--7-Segment Display Port Map
small_disp <= disp(13 downto 0);

display: mux7seg port map( 
    clk => clk10,				-- runs on the 10 MHz clock
    y3 => calc_display(15 downto 12), 		        
    y2 => calc_display(11 downto 8),	
    y1 => calc_display(7 downto 4), 		
    y0 => calc_display(3 downto 0),		
    dp_set => "0000",           -- decimal points off
    seg => seg,
    dp => dp,
    an => an );

-- Block memory Port Map   
to_bcd : blk_mem_gen_1
PORT MAP (
  clka => clk10,
  ena => '1',
  addra => small_disp,
  douta => calc_display);


end Structural;
