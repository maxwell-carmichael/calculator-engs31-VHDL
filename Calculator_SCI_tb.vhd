----------------------------------------------------------------------------------
-- Company: ENGS056/COSC031
-- Engineer: Maxwell Carmichael
-- 
-- Create Date: 05/13/2021 07:51:11 PM
-- Design Name: 
-- Module Name: Calculator_SCI_tb - testbench
-- Project Name: Final Project
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

--=============================================================
--Library Declarations:
--=============================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.all;

--=============================================================
--Entity Declaration:
--=============================================================
ENTITY Calculator_SCI_tb IS
END Calculator_SCI_tb;

--=============================================================
--Architecture Declaration:
--=============================================================
ARCHITECTURE behavior OF Calculator_SCI_tb IS 

component Calculator_SCI
port (  clk: in  STD_LOGIC;                             --10MHz clock
        RsRx: in  STD_LOGIC;                            --received bit stream
        -- rx_shift : out STD_LOGIC;                       --for testing
        rx_data : out  STD_LOGIC_VECTOR (7 downto 0);   --data byte
        rx_done_tick : out  STD_LOGIC;                  --data ready tick
        rx_isnumber :   out STD_LOGIC;
        rx_isreturn :   out STD_LOGIC;
        rx_isoper   :   out STD_LOGIC;
        rx_isequals :   out STD_LOGIC );      
end component; 

--=============================================================
--Signal Declaration:
--=============================================================
--Inputs
signal clk : STD_LOGIC := '0';
signal RsRx : STD_LOGIC := '1';
-- signal rx_shift : STD_LOGIC := '0';
signal rx_data  : STD_LOGIC_VECTOR (7 downto 0);
signal rx_done_tick : STD_LOGIC := '0';
signal rx_isnumber : STD_LOGIC := '0';
signal rx_isreturn : STD_LOGIC := '0';
signal rx_isoper   : STD_LOGIC := '0';
signal rx_isequals : STD_LOGIC := '0';

constant clk_period : time := 100ns;
constant bit_time  : time := 104167ns;

BEGIN 

--=============================================================
--Signal Declaration:
--=============================================================
uut: Calculator_SCI port map(
    --Timing and IO
    clk => clk, 
    RsRx => RsRx,
    rx_data => rx_data,
    rx_done_tick => rx_done_tick,
    rx_isnumber => rx_isnumber,
    rx_isreturn => rx_isreturn,
    rx_isoper => rx_isoper,
    rx_isequals => rx_isequals );

--=============================================================
--100 MHz clock declaration:
--=============================================================       
-- Clock process definitions
clk_process :process
begin
    clk <= '0';
    wait for clk_period/2;
    clk <= '1';
    wait for clk_period/2;
end process;

-- process which tests datapath
test_process : process
begin
    wait for clk_period/2;

    wait for 10*clk_period;
    -- start
    RsRx <= '0';
    wait for bit_time;
    -- ASCII '5': 00110101
    RsRx <= '1';
    wait for bit_time;
    RsRx <= '0';
    wait for bit_time;
    RsRx <= '1';
    wait for bit_time;
    RsRx <= '0';
    wait for bit_time;
    RsRx <= '1';
    wait for bit_time;
    RsRx <= '1';
    wait for bit_time;
    RsRx <= '0';
    wait for bit_time;
    RsRx <= '0';
    wait for bit_time;
    -- finish
    RsRx <= '1';
    wait for bit_time;

    -- wait for some time
    wait for 2*bit_time;
    wait for 50*clk_period;

    -- start
    RsRx <= '0';
    wait for bit_time;
    -- ASCII '+': 00101011
    RsRx <= '1';
    wait for bit_time;
    RsRx <= '1';
    wait for bit_time;
    RsRx <= '0';
    wait for bit_time;
    RsRx <= '1';
    wait for bit_time;
    RsRx <= '0';
    wait for bit_time;
    RsRx <= '1';
    wait for bit_time;
    RsRx <= '0';
    wait for bit_time;
    RsRx <= '0';
    wait for bit_time;
    -- finish
    RsRx <= '1';
    wait for bit_time;
    
    -- start
    RsRx <= '0';
    wait for bit_time;
    -- ASCII 'RETURN': 00001101
    RsRx <= '1';
    wait for bit_time;
    RsRx <= '0';
    wait for bit_time;
    RsRx <= '1';
    wait for bit_time;
    RsRx <= '1';
    wait for bit_time;
    RsRx <= '0';
    wait for bit_time;
    RsRx <= '0';
    wait for bit_time;
    RsRx <= '0';
    wait for bit_time;
    RsRx <= '0';
    wait for bit_time;
    -- finish
    RsRx <= '1';
    wait for bit_time;

    -- start
    RsRx <= '0';
    wait for bit_time;
    -- ASCII 'U': 01010101
    RsRx <= '1';
    wait for bit_time;
    RsRx <= '0';
    wait for bit_time;
    RsRx <= '1';
    wait for bit_time;
    RsRx <= '0';
    wait for bit_time;
    RsRx <= '1';
    wait for bit_time;
    RsRx <= '0';
    wait for bit_time;
    RsRx <= '1';
    wait for bit_time;
    RsRx <= '0';
    wait for bit_time;
    -- finish
    RsRx <= '1';
    wait for bit_time;
    wait;

end process;

END;