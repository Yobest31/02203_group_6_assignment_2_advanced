----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/12/2026 09:09:55 AM
-- Design Name: 
-- Module Name: dram_8b - Behavioral
-- Project Name: 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dram_8b is
    Port ( rst : in STD_LOGIC;
           clk : in STD_LOGIC;
           en : in STD_LOGIC;
           d_in : in STD_LOGIC_VECTOR (7 downto 0);
           d_out : out STD_LOGIC_VECTOR (7 downto 0));
end dram_8b;

architecture Behavioral of dram_8b is
begin

reg: process(RST, CLK)
    variable var : STD_LOGIC_VECTOR(7 downto 0);
begin
    
    if rst = '1' then
        var := "00000000";
    elsif clk'event and clk = '1' then
        if en = '1' then
            var := d_in;
        end if;
    end if; 
    
    d_out <= var;
    
end process;

end Behavioral;

