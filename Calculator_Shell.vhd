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

-- Signals for Converter
signal conv_Clear  :   STD_LOGIC   := '0';
signal conv_Data_out         :   STD_LOGIC_VECTOR(31 downto 0)  :=  (others => '0');

-- Signals for Calculator
-- signal conv_Data_in         :   STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal conv_Data_ready      :   STD_LOGIC := '0';
signal disp             :   STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
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
        rx_isequals :   out STD_LOGIC );  
	END COMPONENT;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Calculator_Converter
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
COMPONENT Converter is
    Port ( 
            clk, Push, Clear 	    : 	in 	STD_LOGIC;
            Data_in					:	in	std_logic_vector(7 downto 0) := (others => '0');
            Data_ready              :   out std_logic;
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
        
        rx_isreturn, rx_isoper, rx_isequals :	in	std_logic;
        
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
COMPONENT blk_mem_gen_0
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
    rx_isequals => rx_isequals );

-- Converter port map
Stack : Converter PORT MAP ( 
    clk => clk10,
    Push => rx_done_tick,
    Clear => conv_Clear,
    Data_in => rx_data,
    Data_ready => conv_Data_ready,
    Data_out => conv_Data_out );


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
    disp => disp );



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
to_bcd : blk_mem_gen_0
PORT MAP (
  clka => clk10,
  ena => '1',
  addra => small_disp,
  douta => calc_display);


end Structural;

























-- ----------
-- --=============================================================
-- --Library Declarations
-- --=============================================================
-- library IEEE;
-- use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.numeric_std.ALL;			-- needed for arithmetic
-- use ieee.math_real.all;				-- needed for automatic register sizing
-- library UNISIM;						-- needed for the BUFG component
-- use UNISIM.Vcomponents.ALL;

-- --=============================================================
-- --Shell Entitity Declarations
-- --=============================================================
-- entity Calculator_Shell is
-- port (  
--     --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--     --Timing
--     --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--         mclk		: in STD_LOGIC;	    -- FPGA board master clock (100 MHz)
--         mode        : in STD_LOGIC;
--     --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--     --SPI BUS
--     --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--         spi_sclk : out STD_LOGIC;
--         take_sample_LA : out STD_LOGIC;
--         spi_cs : out STD_LOGIC;
--         spi_s_data : in STD_LOGIC;

--     --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--     --7 Segment Display
--     --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--         seg	: out STD_LOGIC_vector(0 to 6);
--         dp    : out STD_LOGIC;
--         an 	: out STD_LOGIC_vector(3 downto 0) );  
-- end Calculator_Shell; 

-- --=============================================================
-- --Architecture + Component Declarations
-- --=============================================================
-- architecture Behavioral of Calculator_Shell is
-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- --Controller
-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- component lab4_controller is
-- 	port(clk			:in STD_LOGIC;
--     	 take_sample 	:in STD_LOGIC;
-- 		 shift_en		:out STD_LOGIC;
-- 		 load_en		:out STD_LOGIC;
-- 		 spi_cs			:out STD_LOGIC
-- 		 );
-- end component;
         
-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- --Datapath
-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- component shift_register_12b is
-- 	port(	clk			:in STD_LOGIC;
-- 			shift_en 	:in STD_LOGIC;
-- 			load_en		:in STD_LOGIC;
-- 			spi_s_data	:in STD_LOGIC;
-- 			adc_data		:out STD_LOGIC_vector(11 downto 0)
-- 			);
-- end component;

-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- --7 Segment Display
-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- component mux7seg is
--     Port ( 	clk : in  STD_LOGIC;
--            	y0, y1, y2, y3 : in  STD_LOGIC_VECTOR (3 downto 0);	
--            	dp_set : in STD_LOGIC_vector(3 downto 0);					
--            	seg : out  STD_LOGIC_VECTOR (0 to 6);	
--           	dp : out STD_LOGIC;
--            	an : out  STD_LOGIC_VECTOR (3 downto 0) );			
-- end component;

-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- --7 Segment Display
-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- COMPONENT blk_mem_gen_0
--   PORT (
--     clka : IN STD_LOGIC;
--     ena : IN STD_LOGIC;
--     addra : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
--     douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
--   );
-- END COMPONENT;
-- --=============================================================
-- --Local Signal Declaration
-- --=============================================================
-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- --Timing Signals:
-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- -- 1 MHz SERIAL CLOCK (SCLK)
-- -- Signals for the clock divider, which divides the master clock down to 1 MHz
-- -- Master clock frequency / CLOCK_DIVIDER_VALUE = 2 MHz
-- constant sclk_tc: integer := 100 / 2; 
-- constant sclk_count_length: integer := integer(ceil( log2( real(sclk_tc) ) ));
-- signal sclk_count: unsigned(sclk_count_length-1 downto 0) := (others => '0');
-- signal sclk_tog: STD_LOGIC := '0';                      
-- signal sclk: STD_LOGIC := '0';

-- --10 HZ TAKE SAMPLE
-- --Signals for the 10 Hz tick generator, take_sample:
-- constant take_sample_tc: integer := 100000; 
-- constant take_sample_count_length: integer := integer(ceil( log2( real(take_sample_tc) ) ));
-- signal take_sample_count: unsigned(take_sample_count_length-1 downto 0) := (others => '0');    
-- signal take_sample: STD_LOGIC := '0';                      

-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- --Intermediate Signals:
-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
-- signal shift_en: STD_LOGIC := '0';
-- signal load_en: STD_LOGIC := '0';
-- signal adc_data: STD_LOGIC_vector(11 downto 0) := (others => '0');	-- A/D output
-- signal douta: STD_LOGIC_vector(15 downto 0) := (others => '0');	-- A/D output
-- signal to_mux7seg_y3 : STD_LOGIC_vector(3 downto 0) := (others => '0');
-- signal to_mux7seg_y2 : STD_LOGIC_vector(3 downto 0) := (others => '0');
-- signal to_mux7seg_y1 : STD_LOGIC_vector(3 downto 0) := (others => '0');
-- signal to_mux7seg_y0 : STD_LOGIC_vector(3 downto 0) := (others => '0');
-- signal measured_voltage : STD_LOGIC_vector(15 downto 0) := (others => '0');
-- signal ian : STD_LOGIC_vector(3 downto 0) := (others => '1'); 

-- begin
-- --=============================================================
-- --Timing:
-- --=============================================================		
-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- --1 MHz Serial Clock (sclk) Generation
-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- -- Clock buffer for the 1 MHz sclk
-- -- The BUFG component puts the serial clock onto the FPGA clocking network
-- Slow_clock_buffer: BUFG
-- 	port map (I => sclk_tog,
-- 		      O => sclk );
    
-- -- Divide the 100 MHz clock down to 2 MHz, then toggling a flip flop gives the final 
-- -- 1 MHz system clock
-- Serial_clock_divider: process(mclk)
-- begin
-- 	if rising_edge(mclk) then
-- 	   	if sclk_count = sclk_tc-1 then 
-- 			sclk_count <= (others => '0');
-- 			sclk_tog <= NOT(sclk_tog);
-- 		else
-- 			sclk_count <= sclk_count + 1;
-- 		end if;
-- 	end if;
-- end process Serial_clock_divider;

-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- --1 MHz Serial Clock (sclk) Forwarding
-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- ODDR_inst : ODDR
-- generic map(
-- 	DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
-- 	INIT => '0', -- Initial value for Q port ('1' or '0')
-- 	SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
-- port map (
-- 	Q => spi_sclk, -- 1-bit DDR output
-- 	C => sclk, -- 1-bit clock input
-- 	CE => '1', -- 1-bit clock enable input
-- 	D1 => '1', -- 1-bit data input (positive edge)
-- 	D2 => '0', -- 1-bit data input (negative edge)
-- 	R => '0', -- 1-bit reset input
-- 	S => '0' -- 1-bit set input
-- );

-- -- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- -- --10 Hz take sample tick (high for 1 sclk cycle) generation 
-- -- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- -- take_sample_gen : process(sclk)
-- -- begin
-- -- 	if rising_edge(sclk) then
-- -- 	   	if take_sample_count = take_sample_tc-1 then 
-- -- 	   	    take_sample <= '1';
-- -- 			take_sample_count <= (others => '0');
-- -- 		else
-- --             take_sample <= '0';
-- -- 			take_sample_count <= take_sample_count + 1;
-- -- 		end if;
-- -- 	end if;
-- -- end process take_sample_gen;

-- --=============================================================
-- --Port Maps:
-- --=============================================================
-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- --Outputs
-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- take_sample_LA <= take_sample;

-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- --Controller
-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- control: lab4_controller port map(
--     clk => sclk,
--     take_sample => take_sample,
--     shift_en => shift_en,
--     load_en => load_en,
--     spi_cs => spi_cs);

-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- --Core Datapath
-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- datapath: shift_register_12b port map(
--     clk => sclk,
--     shift_en => shift_en,
--     load_en => load_en,
--     spi_s_data => spi_s_data,
--     adc_data => adc_data);

-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- --Mux to 7-Seg
-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- --Input Multiplexer
-- display_mux: process(mode, measured_voltage, adc_data, ian)
-- begin
--     if mode = '1' then
--         to_mux7seg_y3 <= measured_voltage(15 downto 12);
--         to_mux7seg_y2 <= measured_voltage(11 downto 8);
--         to_mux7seg_y1 <= measured_voltage(7 downto 4);
--         to_mux7seg_y0 <= measured_voltage(3 downto 0);
--         an <= ian;
--     else
--         to_mux7seg_y3 <= "0000";
--         to_mux7seg_y2 <= adc_data(11 downto 8);
--         to_mux7seg_y1 <= adc_data(7 downto 4);
--         to_mux7seg_y0 <= adc_data(3 downto 0);
--         an <= ian OR "1000";
--     end if;
-- end process;

-- --7-Segment Display Port Map
-- display: mux7seg port map( 
--     clk => sclk,				-- runs on the 1 MHz clock
--     y3 => to_mux7seg_y3, 		        
--     y2 => to_mux7seg_y2, -- A/D converter output  	
--     y1 => to_mux7seg_y1, 		
--     y0 => to_mux7seg_y0,		
--     dp_set => "0000",           -- decimal points off
--     seg => seg,
--     dp => dp,
--     an => ian );	
    
-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- --Block Memory
-- --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++    
-- your_instance_name : blk_mem_gen_0
--   PORT MAP (
--     clka => sclk,
--     ena => '1',
--     addra => adc_data,
--     douta => measured_voltage);
  	
-- end Behavioral; 