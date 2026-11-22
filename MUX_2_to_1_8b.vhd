----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/14/2026 07:46:55 PM
-- Design Name: 
-- Module Name: MUX_2_to_1_8b - Behavioral
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

entity MUX_2_to_1_8b is
    Port ( d_in0 : in STD_LOGIC_VECTOR (7 downto 0);
           d_in1 : in STD_LOGIC_VECTOR (7 downto 0);
           ctrl : in STD_LOGIC;
           d_out : out STD_LOGIC_VECTOR (7 downto 0));
end MUX_2_to_1_8b;

architecture Behavioral of MUX_2_to_1_8b is

begin

process(ctrl)
begin
    d_out <= d_in1;
    if ctrl = '0' then
        d_out <= d_in0;
    end if;
end process;


end Behavioral;
