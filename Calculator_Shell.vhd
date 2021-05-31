--=============================================================
--Library Declarations
--=============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;			-- needed for arithmetic
use ieee.math_real.all;				-- needed for automatic register sizing
library UNISIM;						-- needed for the BUFG component
use UNISIM.Vcomponents.ALL;

--=============================================================
--Shell Entitity Declarations
--=============================================================
entity Calculator_Shell is
port (  
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    --Timing
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        mclk		: in std_logic;	    -- FPGA board master clock (100 MHz)
        mode        : in std_logic;
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    --SPI BUS
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        spi_sclk : out std_logic;
        take_sample_LA : out std_logic;
        spi_cs : out std_logic;
        spi_s_data : in std_logic;

    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    --7 Segment Display
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        seg	: out std_logic_vector(0 to 6);
        dp    : out std_logic;
        an 	: out std_logic_vector(3 downto 0) );  
end Calculator_Shell; 

--=============================================================
--Architecture + Component Declarations
--=============================================================
architecture Behavioral of Calculator_Shell is
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Controller
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component lab4_controller is
	port(clk			:in std_logic;
    	 take_sample 	:in std_logic;
		 shift_en		:out std_logic;
		 load_en		:out std_logic;
		 spi_cs			:out std_logic
		 );
end component;
         
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Datapath
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component shift_register_12b is
	port(	clk			:in std_logic;
			shift_en 	:in std_logic;
			load_en		:in std_logic;
			spi_s_data	:in std_logic;
			adc_data		:out std_logic_vector(11 downto 0)
			);
end component;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--7 Segment Display
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component mux7seg is
    Port ( 	clk : in  STD_LOGIC;
           	y0, y1, y2, y3 : in  STD_LOGIC_VECTOR (3 downto 0);	
           	dp_set : in std_logic_vector(3 downto 0);					
           	seg : out  STD_LOGIC_VECTOR (0 to 6);	
          	dp : out std_logic;
           	an : out  STD_LOGIC_VECTOR (3 downto 0) );			
end component;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--7 Segment Display
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
COMPONENT blk_mem_gen_0
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END COMPONENT;
--=============================================================
--Local Signal Declaration
--=============================================================
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Timing Signals:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- 1 MHz SERIAL CLOCK (SCLK)
-- Signals for the clock divider, which divides the master clock down to 1 MHz
-- Master clock frequency / CLOCK_DIVIDER_VALUE = 2 MHz
constant sclk_tc: integer := 100 / 2; 
constant sclk_count_length: integer := integer(ceil( log2( real(sclk_tc) ) ));
signal sclk_count: unsigned(sclk_count_length-1 downto 0) := (others => '0');
signal sclk_tog: std_logic := '0';                      
signal sclk: std_logic := '0';

--10 HZ TAKE SAMPLE
--Signals for the 10 Hz tick generator, take_sample:
constant take_sample_tc: integer := 100000; 
constant take_sample_count_length: integer := integer(ceil( log2( real(take_sample_tc) ) ));
signal take_sample_count: unsigned(take_sample_count_length-1 downto 0) := (others => '0');    
signal take_sample: std_logic := '0';                      

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Intermediate Signals:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
signal shift_en: std_logic := '0';
signal load_en: std_logic := '0';
signal adc_data: std_logic_vector(11 downto 0) := (others => '0');	-- A/D output
signal douta: std_logic_vector(15 downto 0) := (others => '0');	-- A/D output
signal to_mux7seg_y3 : std_logic_vector(3 downto 0) := (others => '0');
signal to_mux7seg_y2 : std_logic_vector(3 downto 0) := (others => '0');
signal to_mux7seg_y1 : std_logic_vector(3 downto 0) := (others => '0');
signal to_mux7seg_y0 : std_logic_vector(3 downto 0) := (others => '0');
signal measured_voltage : std_logic_vector(15 downto 0) := (others => '0');
signal ian : std_logic_vector(3 downto 0) := (others => '1'); 

begin
--=============================================================
--Timing:
--=============================================================		
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--1 MHz Serial Clock (sclk) Generation
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Clock buffer for the 1 MHz sclk
-- The BUFG component puts the serial clock onto the FPGA clocking network
Slow_clock_buffer: BUFG
	port map (I => sclk_tog,
		      O => sclk );
    
-- Divide the 100 MHz clock down to 2 MHz, then toggling a flip flop gives the final 
-- 1 MHz system clock
Serial_clock_divider: process(mclk)
begin
	if rising_edge(mclk) then
	   	if sclk_count = sclk_tc-1 then 
			sclk_count <= (others => '0');
			sclk_tog <= NOT(sclk_tog);
		else
			sclk_count <= sclk_count + 1;
		end if;
	end if;
end process Serial_clock_divider;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--1 MHz Serial Clock (sclk) Forwarding
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ODDR_inst : ODDR
generic map(
	DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
	INIT => '0', -- Initial value for Q port ('1' or '0')
	SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
port map (
	Q => spi_sclk, -- 1-bit DDR output
	C => sclk, -- 1-bit clock input
	CE => '1', -- 1-bit clock enable input
	D1 => '1', -- 1-bit data input (positive edge)
	D2 => '0', -- 1-bit data input (negative edge)
	R => '0', -- 1-bit reset input
	S => '0' -- 1-bit set input
);

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--10 Hz take sample tick (high for 1 sclk cycle) generation 
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
take_sample_gen : process(sclk)
begin
	if rising_edge(sclk) then
	   	if take_sample_count = take_sample_tc-1 then 
	   	    take_sample <= '1';
			take_sample_count <= (others => '0');
		else
            take_sample <= '0';
			take_sample_count <= take_sample_count + 1;
		end if;
	end if;
end process take_sample_gen;

--=============================================================
--Port Maps:
--=============================================================
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Outputs
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
take_sample_LA <= take_sample;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Controller
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
control: lab4_controller port map(
    clk => sclk,
    take_sample => take_sample,
    shift_en => shift_en,
    load_en => load_en,
    spi_cs => spi_cs);

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Core Datapath
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
datapath: shift_register_12b port map(
    clk => sclk,
    shift_en => shift_en,
    load_en => load_en,
    spi_s_data => spi_s_data,
    adc_data => adc_data);

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Mux to 7-Seg
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Input Multiplexer
display_mux: process(mode, measured_voltage, adc_data, ian)
begin
    if mode = '1' then
        to_mux7seg_y3 <= measured_voltage(15 downto 12);
        to_mux7seg_y2 <= measured_voltage(11 downto 8);
        to_mux7seg_y1 <= measured_voltage(7 downto 4);
        to_mux7seg_y0 <= measured_voltage(3 downto 0);
        an <= ian;
    else
        to_mux7seg_y3 <= "0000";
        to_mux7seg_y2 <= adc_data(11 downto 8);
        to_mux7seg_y1 <= adc_data(7 downto 4);
        to_mux7seg_y0 <= adc_data(3 downto 0);
        an <= ian OR "1000";
    end if;
end process;

--7-Segment Display Port Map
display: mux7seg port map( 
    clk => sclk,				-- runs on the 1 MHz clock
    y3 => to_mux7seg_y3, 		        
    y2 => to_mux7seg_y2, -- A/D converter output  	
    y1 => to_mux7seg_y1, 		
    y0 => to_mux7seg_y0,		
    dp_set => "0000",           -- decimal points off
    seg => seg,
    dp => dp,
    an => ian );	
    
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Block Memory
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++    
your_instance_name : blk_mem_gen_0
  PORT MAP (
    clka => sclk,
    ena => '1',
    addra => adc_data,
    douta => measured_voltage);
  	
end Behavioral; 