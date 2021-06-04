----------------------------------------------------------------------------------
-- Company: Dartmouth 21S - Engs 31 
-- Engineer: Alex Carney 
-- 
-- Create Date: 05/31/2021 12:57:11 PM
-- Design Name: Input Handling 
-- Module Name: Converter - Behavioral
-- Project Name: Digital Calculator  
-- Target Devices: 
-- Tool Versions: 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Converter is
Port ( 
        clk, Push, Clear 	: 	in 	STD_LOGIC;
		Data_in					:	in	std_logic_vector(7 downto 0) := (others => '0');
		Data_ready              :   out std_logic;
		Data_out				:	out	std_logic_vector(31 downto 0) := (others => '0')
);
end Converter;

architecture Behavioral of Converter is

--FSM states
type state_type is (Start, Reset, FullS, PushS, PopS, ClearS, Convert, Output);
signal current_state, next_state : state_type;

--Control signals
signal push_en, pop_en, clear_en, full_sig, empty_sig, compCarr_en, popCount_en, acc_en,
carriage_detect, count_clr, acc_clr, data_out_en:	std_logic := '0';

--Registers
type regfile is array(0 to 4) of std_logic_vector(7 downto 0);
signal Stack_reg : regfile;
signal accumulator_reg:  std_logic_vector (31 downto 0) := (others => '0');
signal count_reg: unsigned(2 downto 0) := (others => '0'); --keep an internal register for our counter 
signal Data_reg: std_logic_vector(7 downto 0) := (others => '0'); 

--due to the nature of stacks, our read and write memory pointers point to the same address always
signal S_ADDR : integer := 0;

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

nextStateLogic: process(current_state, Push, Clear, full_sig, empty_sig, carriage_detect)
begin

--default control signals
push_en <= '0';
pop_en <= '0';
Clear_en <= '0';

compCarr_en <= '0';
popCount_en <= '0';
acc_en <= '0';
acc_clr <= '0';
count_clr <= '0';
data_out_en <= '0';

--default state
next_state <= current_state;

--default outputs
data_ready <= '0';



case (current_state) is
	
    when Start =>

        if Clear = '1' then
        	next_state <= ClearS;
        elsif Push = '1' then
        	next_state <= PushS;
        else
        	next_state <= Start;
        end if;
    
    when PushS =>       
        --make sure the input isn't a carriage return
        compCarr_en <= '1';    
        if carriage_detect = '1' then
        	next_state <= PopS;
        elsif full_sig = '1' then
            next_state <= FullS;
        else
        	push_en <= '1';
        	next_state <= Start;
        end if;
    
    when PopS =>
        next_state <= Convert;
        
        if empty_sig = '1' then
        	next_state <= Output; 
        end if;
        
        --continuously pop, counting the number of times we do so, accumulating each number, until it is empty
    	pop_en <= '1';
        popCount_en <= '1';
        
    when Convert =>
        next_state <= PopS;
        if empty_sig = '1' then
        	next_state <= Output;
        end if;
        acc_en <= '1';
        
    when Output =>
        next_state <= Reset;
        data_out_en <= '1'; 
     
    when Reset =>
        
        data_ready <= '1';
    
    	acc_clr <= '1';
        count_clr <= '1';
    	    	
        next_state <= Start; 
    
    when FullS =>
        compCarr_en <= '1';    
        if carriage_detect = '1' then
        	next_state <= PopS;
        else
            next_state <= FullS;
        end if;
    
    when ClearS =>
        Clear_en <= '1';
        next_state <= Start;
        
end case; 

end process nextStateLogic;

----------------------------------
--Datapath
----------------------------------

Datapath: process(clk, push_en, pop_en, compCarr_en, acc_en, popCount_en, Data_in, S_ADDR, stack_reg, data_out_en) 
begin

--default control signals
Full_sig <= '0';
Empty_sig <= '0';
carriage_detect <= '0';


--clocked components
if rising_edge(clk) then
   
    --write PUSH function 
    if(push_en = '1') then
    
        --IF unsigned(Data_in) < 48 OR unsigned(Data_in) > 57
    
        stack_reg(S_ADDR) <= Data_in; --push the new data on the stack 
        S_ADDR <= S_ADDR + 1; --due to how stacks work, we only need 1 pointer
    
    end if;
    
    --POP function
    if(pop_en = '1') then
     
        stack_reg(S_addr) <= (others => '0');
        S_addr <= S_addr - 1;
        
    end if;
    
    --data register
    --clear function TODO
    if(clear_en = '1') then
        stack_reg <= (others => (others => '0'));
        s_addr <= 0;
    end if;
    
    --pop counter
    if(count_clr = '1') then
        count_reg <= (others => '0');
    end if;
            
    if(popCount_en = '1') then
        count_reg <= count_reg + 1;
    end if;

    --Data register
    if(data_out_en = '1') then
        data_out <= accumulator_reg; 
    end if;
    
    --accumulator
    if(acc_en = '1') then
    
    
        case (count_reg) is
            when "001" =>
                accumulator_reg <= std_logic_vector(unsigned(accumulator_reg) + (unsigned(Data_reg) )); 	
            when "010" =>
                accumulator_reg <= std_logic_vector(unsigned(accumulator_reg) + (10*unsigned(Data_reg)) ); 
            when "011" =>
                accumulator_reg <= std_logic_vector(unsigned(accumulator_reg) + (100*unsigned(Data_reg)) ); 
            when "100" =>
                accumulator_reg <= std_logic_vector(unsigned(accumulator_reg) + resize((1000*(resize(unsigned(Data_reg), 32))), 32) ); 
            when others =>
                accumulator_reg <= accumulator_reg;
        end case; 
           
    elsif(acc_clr = '1') then
        accumulator_reg <= (others => '0');
    end if;
    

end if; --end clock

--async components (Read)
Data_reg <= std_logic_vector( unsigned(stack_reg(S_addr)) - 48);

--async components (comparators)
if(s_addr = 0) then
	empty_sig <= '1';
end if;

--carriage return detector
if(compCarr_en = '1') then
	if(Data_in = "00001101") then
    	carriage_detect <= '1';
    end if;
end if;

--Full detector
if(s_addr = 4) then
	full_sig <= '1';
end if;
    

end process Datapath; 


end Behavioral;
