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
-- Description: Provides the master controller for the Digital Calculator, along with the datapath components necessary
--              to perform calculations on numbers that are stored as std_logic_vectors in the internal registers. 
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
use IEEE.NUMERIC_STD.ALL;

ENTITY Calculator IS
PORT (	clk 				 	: 	in 	STD_LOGIC;
		
		--communication with the SCI receiver 
        rx_Data_in				:	in std_logic_vector(7 downto 0) := (others => '0');
        rx_Data_ready			:	in std_logic; 
        
        rx_isreturn             :   in std_logic;
        rx_isoper               :   in std_logic;
        rx_isequals             :   in std_logic;
        rx_isclear              :   in std_logic;
        
        --communication with the Stack converter 
        conv_Data_in			:	in	std_logic_vector(31 downto 0) := (others => '0');
		conv_Data_ready			:	in	std_logic;
        conv_en                 :   out std_logic;
        
        --communication to shell and LED display 
        disp				    : 	out std_logic_vector(31 downto 0) := (others => '0')
        
        );
end Calculator;
architecture behavior of Calculator is

--FSM states
type state_type is (Idle, StoreOne, StoreOp, StoreTwo, Calc, WaitForOp, WaitForNum, WaitForEquals, ReuseOp, Clear, Chaining, Overflow);

signal current_state : state_type := Idle;
signal next_state : state_type;

--------------------
--Control signals 
--------------------

--from FSM to datapath
signal reg1_en, regOp_en, reg2_en, calc_en, ovrflw_en, reg1_ow	:	std_logic := '0';
--from datapath to FSM
signal ovrflw_detect    : std_logic := '0';
--clear signals
signal reg1_clr, regOp_clr, reg2_clr, calc_clr : std_logic := '0';
--output reg signal 
signal disp_en : std_logic_vector(2 downto 0) := (others => '0');

--Registers
signal Reg1 : std_logic_vector(31 downto 0) := (others => '0');
signal Reg2 : std_logic_vector(31 downto 0) := (others => '0');
signal RegOp : std_logic_vector(7 downto 0) := (others => '0');
signal CalcReg : std_logic_vector(31 downto 0) := (others => '0');

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

nextStateLogic: process(current_state, rx_Data_in, conv_Data_in, conv_Data_ready, rx_Data_ready, rx_isreturn, rx_isoper, rx_isequals, rx_isclear, ovrflw_detect)
begin

--default enable signals
reg1_en <= '0';
regOp_en <= '0';
reg2_en <= '0';
calc_en <= '0';
disp_en <= "000";
reg1_ow <= '0'; --reg1_overwrite
ovrflw_en <= '0';

--default clear signals
reg1_clr <= '0';
reg2_clr <= '0';
regOp_clr <= '0';
calc_clr <= '0';

--default state
next_state <= current_state;

--default outputs
conv_en <= '0';

case (current_state) is

	when Idle => 
    	conv_en <= '1';
    	
        if (conv_data_ready = '1') then
        	next_state <= StoreOne; 
		end if;
            
    when StoreOne => 
        reg1_en <= '1';
        
        if(rx_isreturn = '1') then
            next_state <= WaitForOp;
        end if; 
		
    when WaitForOp =>
        disp_en <= "001";
        
        --operations come directly from the SCI receiver
        if(rx_data_ready = '1' and rx_isclear = '1') then
            next_state <= Clear; 
        elsif(rx_data_ready = '1' and rx_isoper = '1') then
        	next_state <= StoreOp;
		end if;
		
        
    when StoreOp =>
    	if(rx_isoper = '1') then
    	   regOp_en <= '1';
    	end if;
        if(rx_isreturn = '1') then
            next_state <= WaitForNum;
        end if;
    
    when WaitForNum =>
        disp_en <= "001";
        conv_en <= '1';
        
        if(rx_data_ready = '1' and rx_isclear = '1') then
            next_state <= Clear; 
        end if;
        if(conv_data_ready = '1') then
        	next_state <= StoreTwo;
        end if; 
        
    when StoreTwo => 
        reg2_en <= '1';
        
        if(rx_isreturn = '1') then
            next_state <= WaitForEquals;
        end if;
        
    when WaitForEquals =>
        disp_en <= "010";  
        
        if(rx_data_ready = '1' and rx_isclear = '1') then
           next_state <= Clear;        
        elsif(rx_data_ready = '1' and rx_isequals = '1') then     
        	next_state <= Calc;
        elsif(rx_data_ready = '1' and rx_isoper = '1') then
            next_state <= Chaining; 	
        end if;   
    
    when Chaining => 
        calc_en <= '1';
        disp_en <= "011"; 
        
        next_state <= ReuseOp;    
        
    when Calc => 
        calc_en <= '1';
        disp_en <= "011";
        ovrflw_en <= '1';
        
        if(ovrflw_detect = '1') then
           next_state <= Overflow; 
        elsif(rx_data_ready = '1' and rx_isclear = '1') then
           next_state <= Clear;
         elsif(rx_data_ready = '1' and rx_isoper = '1') then
        	next_state <= ReuseOp;
        end if;
        
        
    when Overflow => 
        reg1_clr <= '1';
        reg2_clr <= '1';
        regOp_clr <= '1';
        calc_clr <= '1';
        disp_en <= "101"; 
        
        if(rx_isreturn = '1') then
            next_state <= Idle; 
        end if;
            
        
    when Clear =>       
        reg1_clr <= '1';
        reg2_clr <= '1';
        regOp_clr <= '1';
        calc_clr <= '1';
        disp_en <= "100";
        
        if(rx_isreturn = '1') then
            next_state <= Idle; 
        end if;

    when ReuseOp =>
        reg1_ow <= '1';
       
        next_state <= StoreOp;     
        
end case;

end process nextStateLogic; 

----------------------------------
--Datapath
----------------------------------

Datapath: process(clk, reg1_en, calc_clr, regOp_en, reg2_en, calc_en, RegOp, Reg1, Reg2, disp_en, CalcReg, reg1_ow, ovrflw_en) 
begin

--default control signals -- (ones set back to FSM) 
ovrflw_detect <= '0';

--clocked components
if rising_edge(clk) then

    ---------------------
    --Registers
    --------------------- 


	--Register for 1st number
    if(reg1_ow = '1') then
        Reg1 <= CalcReg;
    elsif(reg1_en = '1') then
    	Reg1 <= conv_Data_in;
    elsif(reg1_clr = '1') then
        Reg1 <= (others => '0');    		
    end if;
    
    --Register for Operations
    if(regOp_en = '1') then
    	RegOp <= rx_Data_in;
    elsif(regOp_clr = '1') then
        RegOp <= (others => '0');
    end if;
    
    --Register for 2nd number
    if(reg2_en = '1') then
    	Reg2 <= conv_Data_in;
    elsif(reg2_clr = '1') then
        Reg2 <= (others => '0');	
    end if;
    
    --Register for calculated values (more below) 
    if(calc_clr = '1') then
        CalcReg <= (others => '0');     
    end if;
    
    --Output display register
    if(disp_en = "001") then
        disp <= Reg1;
    elsif(disp_en = "010") then
        disp <= Reg2;
    elsif(disp_en = "011") then
        disp <= CalcReg;  
    elsif(disp_en = "100") then
        disp <= (others => '0');
    elsif(disp_en = "101") then
        disp <= std_logic_vector( to_unsigned(9999, 32) );             
    end if;

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
    
end if; --end calculator 
   
end if; --end clocked components

--async components

--overflow comparator
if(ovrflw_en = '1') then
    if(unsigned(CalcReg) > to_unsigned(9999, 32)) then
          ovrflw_detect <= '1';
    end if;
end if;

end process Datapath;
        
end behavior;         
