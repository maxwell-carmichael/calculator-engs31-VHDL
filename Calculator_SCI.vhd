----------------------------------------------------------------------------------
-- Company: ENGS031/COSC056
-- Engineer: Max Carmichael
-- 
-- Create Date: 05/13/2021 09:52:28 PM
-- Design Name: 
-- Module Name: Calculator_SCI - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

entity Calculator_SCI is
    Port (  clk: in  STD_LOGIC;                             --10MHz clock
            RsRx: in  STD_LOGIC;                            --received bit stream
            -- rx_shift : out STD_LOGIC;                       --for testing
            rx_data : out  STD_LOGIC_VECTOR (7 downto 0);   --data byte
            rx_done_tick : out  STD_LOGIC );                --data ready tick
end Calculator_SCI;

architecture Behavioral of Calculator_SCI is

--- Synchronizer Signals ---
signal RsRx_sync1      : STD_LOGIC := '0';
signal Data_in         : STD_LOGIC := '0';

------ Counter Signals -----
constant N              : integer := 1042;  -- clock frequency / baud rate = 10000000 / 9600
constant N_ov_2         : integer := 521; -- N / 2
signal baud_count     : UNSIGNED(12 downto 0) := (others => '0');
signal bit_count    : UNSIGNED(3 downto 0)  := (others => '0');
signal baud_count_tc          : STD_LOGIC := '0';
signal bit_count_tc         : STD_LOGIC := '0';

----- Controller Signals ---
type state_type is (sIdle, sShiftWait, sShift, sLoad, sReady);
signal cs, ns   : state_type;
signal baud_count_en    : std_logic := '0';
signal baud_count_clr   : std_logic := '0';
signal bit_count_en     : std_logic := '0';
signal bit_count_clr    : std_logic := '0';

signal shift_clr    : STD_LOGIC := '0';
signal shift_en     : STD_LOGIC := '0';
signal load_en      : STD_LOGIC := '0';

------ Datapath Signals ----
signal rx_shift_reg: STD_LOGIC_VECTOR(9 downto 0) := (others => '0');
signal data_reg: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');


begin
----------------------------
-- Double-flip-flop Synchronizer
----------------------------
synchronizer : process(clk)
begin
    if rising_edge(clk) then
        RsRx_sync1 <= RsRx;
        Data_in <= RsRx_sync1;
    end if;
end process synchronizer;

----------------------------
-- Controller
----------------------------
state_update : process(clk)
begin
    if rising_edge(clk) then
        cs <= ns;
    end if;
end process state_update;

next_state_logic : process(cs, baud_count_tc, bit_count_tc, Data_in)
begin
    -- default values
    ns <= cs;
    baud_count_en <= '0';
    baud_count_clr <= '0';
    bit_count_en <= '0';
    bit_count_clr <= '0';
    shift_en <= '0';
    shift_clr <= '0';
    load_en <= '0';
    rx_done_tick <= '0';
    
    -- State update logic
    case cs is
        when sIdle =>
            baud_count_clr <= '1';
            bit_count_clr <= '1';
            shift_clr <= '1';

            if Data_in = '0' then
                ns <= sShiftWait;
            end if;

        when sShiftWait =>
            baud_count_en <= '1';
            -- next state logic
            if baud_count_tc = '1' then
                ns <= sShift;
            end if;
            
        when sShift =>
            baud_count_en <= '1';
            bit_count_en <= '1';
            shift_en <= '1';
            -- next state logic
            if bit_count_tc = '1' then
                ns <= sLoad;
            else
                ns <= sShiftWait;
            end if;
            
        when sLoad =>
            load_en <= '1';
            -- next state logic
            ns <= sReady;
            
        when sReady =>
            rx_done_tick <= '1';
            -- next state logic
            ns <= sIdle;
    end case;

end process next_state_logic;



----------------------------
-- Counters
----------------------------
bit_counter  : process(clk, bit_count)
begin
    if rising_edge(clk) then
        if bit_count_clr = '1' then
            bit_count <= (others => '0');
        elsif bit_count_en = '1' then
            bit_count <= bit_count + 1;
        end if;
    end if;

    -- async tc
    if bit_count = 9 then
        bit_count_tc <= '1';
    else
        bit_count_tc <= '0';
    end if;
end process bit_counter;

baud_counter : process(clk, baud_count)
begin
    if rising_edge(clk) then
        if baud_count_clr = '1' then
            baud_count <= to_unsigned(N_ov_2, baud_count'length);
        elsif baud_count = N - 1 then   -- loop again
            baud_count <= (others => '0');
        elsif baud_count_en = '1' then
            baud_count <= baud_count + 1;
        end if;
    end if;

    -- async tc
    if baud_count = N - 1 then
        baud_count_tc <= '1';
    else
        baud_count_tc <= '0';
    end if;
end process baud_counter;



----------------------------
-- Datapath
----------------------------
shift_reg_10b : process(clk)
begin
    if rising_edge(clk) then
        if shift_clr = '1' then
            rx_shift_reg <= (others => '0');
        elsif shift_en = '1' then
            rx_shift_reg <= Data_in & rx_shift_reg(9 downto 1); -- shift right
        end if;
    end if;
end process shift_reg_10b;


parallel_reg_8b: process(clk, data_reg)
begin
    if rising_edge(clk) then
        if load_en = '1' then
            data_reg <= rx_shift_reg(8 downto 1);
        end if;
    end if;

    rx_data <= data_reg;
end process parallel_reg_8b;


end Behavioral;
        
