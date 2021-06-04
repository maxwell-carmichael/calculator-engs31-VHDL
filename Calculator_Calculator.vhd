----------------------------------------------------------------------------------
-- Company: Engs 31 Final
-- Engineer: Alex Carney 
-- 
-- Create Date: 06/04/2021 06:24:32 PM
-- Design Name: Calculator
-- Module Name: Calculator - Behavioral
-- Project Name: Digital Calculator  
-- Target Devices: Basys 3
-- Tool Versions: 
-- Description: Proves the calculation functionality for the Digital Calculator 
-- 
-- Dependencies: Digital Calculator input module 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
ENTITY Calculator IS
PORT (	clk 				 	: 	in 	STD_LOGIC;
		
        rx_Data_in				:	in std_logic_vector(7 downto 0) := (others => '0');
        rx_Data_ready			:	in std_logic; 
        
        conv_Data_in			:	in	std_logic_vector(31 downto 0) := (others => '0');
		conv_Data_ready			:	in	std_logic;
        
        rx_isreturn, rx_isoper, rx_isequals :	in	std_logic;
        
        Calc_out				: 	out std_logic_vector(31 downto 0)
        
        );
end Calculator;
architecture behavior of Calculator is

--FSM states
type state_type is (Idle, StoreOne, StoreOp, StoreTwo, Calc);
signal current_state, next_state : state_type;

--Control signals 
signal reg1_en, regOp_en, reg2_en, calc_en, calc_out_en, calc_clr	:	std_logic := '0';

--Registers
signal Reg1 : std_logic_vector(31 downto 0) := (others => '0');
signal Reg2 : std_logic_vector(31 downto 0) := (others => '0');
signal RegOp : std_logic_vector(7 downto 0) := (others => '0');

signal CalcReg : std_logic_vector(31 downto 0) := (others => '0');

--other signals (playground only)
signal state_bin : std_logic_vector(3 downto 0) := (others => '0');
signal next_state_bin : std_logic_vector(3 downto 0) := (others => '0');

begin

---------------------------------
--Finite State Machine
---------------------------------

stateUpdate: process(clk)
begin
	if rising_edge(clk) then
        current_state <= next_state;
    end if;
end process stateUpdate;

nextStateLogic: process(current_state, rx_Data_in, conv_Data_in, conv_Data_ready, rx_Data_ready, rx_isreturn, rx_isoper, rx_isequals)
begin

--default control signals
reg1_en <= '0';
regOp_en <= '0';
reg2_en <= '0';
calc_en <= '0';
calc_out_en <= '0';
calc_clr <= '0';

--default state
next_state <= current_state;

--default outputs


case (current_state) is

	when Idle => 
    	state_bin <= "0000";
        if (conv_data_ready = '1') then
        	next_state <= StoreOne; 
		end if;
            
    when StoreOne => 
    	state_bin <= "0001";
        reg1_en <= '1';
        
        --operations come directly from the SCI receiver 
        if(rx_data_ready = '1' and rx_isoper = '1') then
        	next_state <= StoreOp;
		end if;
        
    when StoreOp =>
    	state_bin <= "0010";
        regOp_en <= '1';
        
        if(conv_data_ready = '1') then
        	next_state <= StoreTwo;
        end if; 
        
    when StoreTwo => 
    	state_bin <= "0100";
        reg2_en <= '1';
        
        if(rx_data_ready = '1' and rx_isequals = '1') then
        	next_state <= Calc;
        end if; 
        
        
    when Calc => 
    	state_bin <= "0011"; 
        calc_en <= '1';
        calc_out_en <= '1';
        
        
        if(rx_data_ready = '1' and rx_isreturn = '1') then
        	next_state <= Idle;
        elsif(rx_data_ready = '1' and rx_isoper = '1') then
        	next_state <= StoreOp;
        end if;
end case;

end process nextStateLogic; 

----------------------------------
--Datapath
----------------------------------

Datapath: process(clk, reg1_en, regOp_en, reg2_en, calc_en, RegOp, Reg1, Reg2, calc_out_en, CalcReg) 
begin

--clocked components
if rising_edge(clk) then
	--Register 1
    if(reg1_en = '1') then
    	Reg1 <= conv_Data_in;
    end if;
    
    --Register Op
    if(regOp_en = '1') then
    	RegOp <= rx_Data_in;
    end if;
    
    --Register 2
    if(reg2_en = '1') then
    	Reg2 <= conv_Data_in;
    end if;
    
    --Output register
    if(calc_out_en = '1') then
        calc_out <= CalcReg;
    elsif calc_clr = '1' then
        CalcReg <= (others => '0');       
    end if;
    
end if; --end clocked component


--calculator
if(calc_en = '1') then
	case RegOp is
    	
        --Plus (+)
        when "00101011" =>
        	CalcReg <= std_logic_vector(unsigned(Reg1) + unsigned(Reg2));
        
        --Minus (-)
        when "00101101" =>
        	CalcReg <= std_logic_vector(unsigned(Reg1) - unsigned(Reg2));
            
        --Times (*)
        when "00101010" =>
        	CalcReg <= std_logic_vector(resize( unsigned(Reg1) * unsigned(Reg2) , 32)); 
            
        when others =>
        	CalcReg <= CalcReg;
 
    end case;
end if;


end process Datapath;
        
end behavior;         
