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
        
        rx_isreturn, rx_isoper, rx_isequals, rx_isclear :	in	std_logic;
        
        conv_en             :   out std_logic;
        disp				: 	out std_logic_vector(31 downto 0) := (others => '0')
        
        );
end Calculator;
architecture behavior of Calculator is

--FSM states
type state_type is (Idle, StoreOne, StoreOp, StoreTwo, Calc, WaitForOp, WaitForNum, WaitForEquals, ReuseOp, Clear, Chaining);

signal current_state : state_type := Idle;
signal next_state : state_type;

--Control signals 
signal reg1_en, regOp_en, reg2_en, calc_en, muxDisp_en, reg1_ow, ovrflw_en	:	std_logic := '0';
signal reg1_clr, regOp_clr, reg2_clr, calc_clr : std_logic := '0';
signal disp_en : std_logic_vector(2 downto 0) := (others => '0');

--Registers
signal Reg1 : std_logic_vector(31 downto 0) := (others => '0');
signal Reg2 : std_logic_vector(31 downto 0) := (others => '0');
signal RegOp : std_logic_vector(7 downto 0) := (others => '0');

signal CalcReg : std_logic_vector(31 downto 0) := (others => '0');
signal DispReg : std_logic_vector(31 downto 0) := (others => '0');



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

nextStateLogic: process(current_state, rx_Data_in, conv_Data_in, conv_Data_ready, rx_Data_ready, rx_isreturn, rx_isoper, rx_isequals, rx_isclear)
begin

--default control signals
reg1_en <= '0';
regOp_en <= '0';
reg2_en <= '0';
calc_en <= '0';
disp_en <= "000";
muxDisp_en <= '0'; 
reg1_ow <= '0'; --reg1_overwrite
ovrflw_en <= '0';

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
    	state_bin <= "0000";
    	conv_en <= '1';
        if (conv_data_ready = '1') then
        	next_state <= StoreOne; 
		end if;
            
    when StoreOne => 
    	state_bin <= "0001";
        reg1_en <= '1';
        
    --    disp_en <= "01";
        
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
    	state_bin <= "0010";
    	if(rx_isoper = '1') then
    	   regOp_en <= '1';
    	end if;
        --regOp_en <= '1';
 --       disp_en <= "01";
 
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
    	state_bin <= "0100";
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
    	state_bin <= "0011"; 
        calc_en <= '1';
        disp_en <= "011";
        
         if(rx_data_ready = '1' and rx_isclear = '1') then
           next_state <= Clear;
         elsif(rx_data_ready = '1' and rx_isoper = '1') then
        	next_state <= ReuseOp;
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
        
  --     if(rx_data_ready = '1' and rx_isreturn = '1') then
  --      	next_state <= Idle;
  --      elsif(rx_data_ready = '1' and rx_isoper = '1') then
  --      	next_state <= ReuseOp;
  --      end if;
        
    when ReuseOp =>
        reg1_ow <= '1';
        --regOp_en <= '1';
        next_state <= StoreOp;     
        
end case;

end process nextStateLogic; 

----------------------------------
--Datapath
----------------------------------

Datapath: process(clk, reg1_en, calc_clr, regOp_en, reg2_en, calc_en, RegOp, Reg1, Reg2, disp_en, CalcReg, reg1_ow) 
begin

--clocked components
if rising_edge(clk) then
	--Register 1
    if(reg1_ow = '1') then
        Reg1 <= CalcReg;
    elsif(reg1_en = '1') then
    	Reg1 <= conv_Data_in;
    elsif(reg1_clr = '1') then
        Reg1 <= (others => '0');    		
    end if;
    
--    if(reg1_ow = '1') then
--        Reg1 <= CalcReg;
--    end if; 
    
    --Register Op
    if(regOp_en = '1') then
    	RegOp <= rx_Data_in;
    elsif(regOp_clr = '1') then
        RegOp <= (others => '0');
    end if;
    
    --Register 2
    if(reg2_en = '1') then
    	Reg2 <= conv_Data_in;
    elsif(reg2_clr = '1') then
        Reg2 <= (others => '0');	
    end if;
    
    --Output register
    if(disp_en = "001") then
        disp <= Reg1;
    elsif(disp_en = "010") then
        disp <= Reg2;
    elsif(disp_en = "011") then
        disp <= CalcReg;  
    elsif(disp_en = "100") then
        disp <= (others => '0');         
    end if;
    
    
    --disp <= DispReg;
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
    
if calc_clr = '1' then
   CalcReg <= (others => '0');     
end if;
   
end if; --end clocked component

--async components

--overflow comparator
if(ovrflw_en = '1') then
    if(unsigned(CalcReg) > to_unsigned("9999")) then
 --       CalcReg <= std_logic_vector("9999");
          CalcReg <= std_logic_vector( to_unsigned("9999") );
    end if;
end if;

    
--if calc_clr = '1' then
 --  CalcReg <= (others => '0');  
--end if;   
    

end process Datapath;
        
end behavior;         
