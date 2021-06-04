----------------------------------------------------------------------------------
-- Company: ENGS056/COSC031
-- Engineer: Maxwell Carmichael and Alex Carney
-- 
-- Create Date: 05/13/2021 07:51:11 PM
-- Design Name: 
-- Module Name: Calculator_Shell_tb - testbench
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
ENTITY Calculator_Shell_tb IS
END Calculator_Shell_tb;

--=============================================================
--Architecture Declaration:
--=============================================================
ARCHITECTURE behavior OF Calculator_Shell_tb IS 

component Calculator_Shell
port (  clk: in  STD_LOGIC;                             --100MHz system clock
        RsRx: in  STD_LOGIC;                            --received bit stream
        seg	: out STD_LOGIC_vector(0 to 6);
        dp  : out STD_LOGIC;
        an 	: out STD_LOGIC_vector(3 downto 0) );				-- Rx input
end component; 

--=============================================================
--Signal Declaration:
--=============================================================
--Inputs
signal clk  : STD_LOGIC := '0';
signal RsRx : STD_LOGIC := '1';
signal seg  : STD_LOGIC_VECTOR(0 to 6) := (others => '0');
signal dp   : STD_LOGIC := '0';
signal an   : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');

constant bit_time  : time := 104167ns;
constant clk_period : time := 10ns;


-- ASCII constants
constant ascii_5        : STD_LOGIC_VECTOR(7 downto 0) := "00110101";
constant ascii_3        : STD_LOGIC_VECTOR(7 downto 0) := "00110011";
constant ascii_7        : STD_LOGIC_VECTOR(7 downto 0) := "00110111";
constant ascii_plus     : STD_LOGIC_VECTOR(7 downto 0) := "00101011";
constant ascii_minus    : STD_LOGIC_VECTOR(7 downto 0) := "00101101";  
constant ascii_times    : STD_LOGIC_VECTOR(7 downto 0) := "00101010";  
constant ascii_equals   : STD_LOGIC_VECTOR(7 downto 0) := "00111101";
constant ascii_return   : STD_LOGIC_VECTOR(7 downto 0) := "00001101";

-- 5 * 33 + 7375 = - 3 =
-- aka (165) + 7375 = - 3 =
-- aka 7537
BEGIN 

--=============================================================
--Signal Declaration:
--=============================================================
uut: Calculator_Shell port map(
    clk => clk, 
    RsRx => RsRx,
    seg => seg,
    dp => dp,
    an => an );

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
    -- 5
    RsRx <= '0';
    wait for bit_time;

    for bitcount in 0 to 7 loop
        RsRx <= ascii_5(bitcount);
        wait for bit_time;
    end loop;

    RsRx <= '1';
    wait for bit_time;

    -- RETURN
    RsRx <= '0';
    wait for bit_time;

    for bitcount in 0 to 7 loop
        RsRx <= ascii_return(bitcount);
        wait for bit_time;
    end loop;

    RsRx <= '1';
    wait for bit_time;

    -- wait for some time
    wait for 2*baud_rate;
    wait for 50*clk_period;

    -- *
    RsRx <= '0';
    wait for bit_time;

    for bitcount in 0 to 7 loop
        RsRx <= ascii_times(bitcount);
        wait for bit_time;
    end loop;

    RsRx <= '1';
    wait for bit_time;

    -- 33
    RsRx <= '0';
    wait for bit_time;

    for bitcount in 0 to 7 loop
        RsRx <= ascii_3(bitcount);
        wait for bit_time;
    end loop;

    RsRx <= '1';
    wait for bit_time;
    RsRx <= '0';
    wait for bit_time;

    for bitcount in 0 to 7 loop
        RsRx <= ascii_3(bitcount);
        wait for bit_time;
    end loop;

    RsRx <= '1';
    wait for bit_time;

    -- RETURN
    RsRx <= '0';
    wait for bit_time;

    for bitcount in 0 to 7 loop
        RsRx <= ascii_return(bitcount);
        wait for bit_time;
    end loop;

    RsRx <= '1';
    wait for bit_time;

    -- +
    RsRx <= '0';
    wait for bit_time;

    for bitcount in 0 to 7 loop
        RsRx <= ascii_plus(bitcount);
        wait for bit_time;
    end loop;

    RsRx <= '1';
    wait for bit_time;

    -- RETURN
    RsRx <= '0';
    wait for bit_time;

    for bitcount in 0 to 7 loop
        RsRx <= ascii_return(bitcount);
        wait for bit_time;
    end loop;

    RsRx <= '1';
    wait for bit_time;

    -- 7375
    RsRx <= '0';
    wait for bit_time;

    for bitcount in 0 to 7 loop
        RsRx <= ascii_7(bitcount);
        wait for bit_time;
    end loop;

    RsRx <= '1';
    wait for bit_time;
    RsRx <= '0';
    wait for bit_time;

    for bitcount in 0 to 7 loop
        RsRx <= ascii_3(bitcount);
        wait for bit_time;
    end loop;

    RsRx <= '1';
    wait for bit_time;
    RsRx <= '0';
    wait for bit_time;

    for bitcount in 0 to 7 loop
        RsRx <= ascii_7(bitcount);
        wait for bit_time;
    end loop;

    RsRx <= '1';
    wait for bit_time;
    RsRx <= '0';
    wait for bit_time;

    for bitcount in 0 to 7 loop
        RsRx <= ascii_5(bitcount);
        wait for bit_time;
    end loop;

    RsRx <= '1';
    wait for bit_time;

    -- RETURN
    RsRx <= '0';
    wait for bit_time;

    for bitcount in 0 to 7 loop
        RsRx <= ascii_return(bitcount);
        wait for bit_time;
    end loop;

    RsRx <= '1';
    wait for bit_time;

    -- =
    RsRx <= '0';
    wait for bit_time;

    for bitcount in 0 to 7 loop
        RsRx <= ascii_equals(bitcount);
        wait for bit_time;
    end loop;

    RsRx <= '1';
    wait for bit_time;

    -- RETURN
    RsRx <= '0';
    wait for bit_time;

    for bitcount in 0 to 7 loop
        RsRx <= ascii_return(bitcount);
        wait for bit_time;
    end loop;

    RsRx <= '1';
    wait for bit_time;

    -- -
    RsRx <= '0';
    wait for bit_time;

    for bitcount in 0 to 7 loop
        RsRx <= ascii_minus(bitcount);
        wait for bit_time;
    end loop;

    RsRx <= '1';
    wait for bit_time;

    -- RETURN
    RsRx <= '0';
    wait for bit_time;

    for bitcount in 0 to 7 loop
        RsRx <= ascii_return(bitcount);
        wait for bit_time;
    end loop;

    RsRx <= '1';
    wait for bit_time;

    -- 3
    RsRx <= '0';
    wait for bit_time;

    for bitcount in 0 to 7 loop
        RsRx <= ascii_3(bitcount);
        wait for bit_time;
    end loop;

    RsRx <= '1';
    wait for bit_time;

    -- RETURN
    RsRx <= '0';
    wait for bit_time;

    for bitcount in 0 to 7 loop
        RsRx <= ascii_return(bitcount);
        wait for bit_time;
    end loop;

    RsRx <= '1';
    wait for bit_time;

    -- =
    RsRx <= '0';
    wait for bit_time;

    for bitcount in 0 to 7 loop
        RsRx <= ascii_equals(bitcount);
        wait for bit_time;
    end loop;

    RsRx <= '1';
    wait for bit_time;

    -- RETURN
    RsRx <= '0';
    wait for bit_time;

    for bitcount in 0 to 7 loop
        RsRx <= ascii_return(bitcount);
        wait for bit_time;
    end loop;

    RsRx <= '1';
    wait for bit_time;

    wait;


end process;

END;