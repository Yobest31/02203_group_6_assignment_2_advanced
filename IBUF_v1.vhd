----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/12/2026 08:59:34 AM
-- Design Name: 
-- Module Name: FSMD_IBUF - Behavioral
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

entity IBUF_v1 is
    Port ( rst : in STD_LOGIC;
           clk : in STD_LOGIC;
           eol : in STD_LOGIC;
           sol : in STD_LOGIC;
           rowfirst : in STD_LOGIC;
           rowlast : in STD_LOGIC;
           d_in : in STD_LOGIC_VECTOR (31 downto 0);
           d_out : out STD_LOGIC_VECTOR (143 downto 0));
end IBUF_v1;

architecture Behavioral of IBUF_v1 is
    component dram_8b is
        Port ( rst : in STD_LOGIC;
               clk : in STD_LOGIC;
               en : in STD_LOGIC;
               d_in : in STD_LOGIC_VECTOR (7 downto 0);
               d_out : out STD_LOGIC_VECTOR (7 downto 0));
    end component;
    
    component MUX_2_to_1_8b is
    Port ( d_in0 : in STD_LOGIC_VECTOR (7 downto 0);
           d_in1 : in STD_LOGIC_VECTOR (7 downto 0);
           ctrl : in STD_LOGIC;
           d_out : out STD_LOGIC_VECTOR (7 downto 0));
    end component;
    
    type vector8 is array (natural range <>) of std_logic_vector(7 downto 0);
    signal sv_mem_dout : vector8(712 downto 0);
    signal sv_mux_leftright_out : vector8(5 downto 0);
    signal sv_mux_fl_out : vector8(3 downto 0);
    signal sv_mux_ll_out : vector8(5 downto 0);
    
begin
    GEN_REG1 :
    for I in 4 to 351 generate
        --GEN_REG_IF1:
        --if NOT((I = 352) OR (I = 353) OR (I = 354) OR (I = 355)) generate
            memx : dram_8b port map (rst => rst, clk => clk, en => '1', d_in => sv_mem_dout(I-4), d_out => sv_mem_dout(I));
        --end generate GEN_REG_IF1;
    end generate GEN_REG1;
    GEN_REG2 :
    for I in 356 to 712 generate
        memx : dram_8b port map (rst => rst, clk => clk, en => '1', d_in => sv_mem_dout(I-4), d_out => sv_mem_dout(I));
    end generate GEN_REG2;
    
    mem_0 :     dram_8b port map (rst => rst, clk => clk, en => '1', d_in => d_in(31 downto 24), d_out => sv_mem_dout(0));
    mem_1 :     dram_8b port map (rst => rst, clk => clk, en => '1', d_in => d_in(23 downto 16), d_out => sv_mem_dout(1));
    mem_2 :     dram_8b port map (rst => rst, clk => clk, en => '1', d_in => d_in(15 downto 8), d_out => sv_mem_dout(2));
    mem_3 :     dram_8b port map (rst => rst, clk => clk, en => '1', d_in => d_in(7 downto 0), d_out => sv_mem_dout(3));
    
    --First Line write registers
    mem_352 :   dram_8b port map (rst => rst, clk => clk, en => '1', d_in => sv_mux_fl_out(0), d_out => sv_mem_dout(352));
    mem_353 :   dram_8b port map (rst => rst, clk => clk, en => '1', d_in => sv_mux_fl_out(1), d_out => sv_mem_dout(353));
    mem_354 :   dram_8b port map (rst => rst, clk => clk, en => '1', d_in => sv_mux_fl_out(2), d_out => sv_mem_dout(354));
    mem_355 :   dram_8b port map (rst => rst, clk => clk, en  => '1', d_in => sv_mux_fl_out(3), d_out => sv_mem_dout(355));
    
    --SOL muxes
    mux0 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(712), d_in1 => sv_mem_dout(711), ctrl => sol, d_out => sv_mux_leftright_out(5));
    mux1 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(360), d_in1 => sv_mem_dout(359), ctrl => sol, d_out => sv_mux_leftright_out(3));
    mux2 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(8), d_in1 => sv_mem_dout(7), ctrl => sol, d_out => sv_mux_leftright_out(1));
    --EOL muxes
    mux3 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(707), d_in1 => sv_mem_dout(708), ctrl => eol, d_out => sv_mux_leftright_out(4));
    mux4 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(355), d_in1 => sv_mem_dout(356), ctrl => eol, d_out => sv_mux_leftright_out(2));
    mux5 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(3), d_in1 => sv_mem_dout(4), ctrl => eol, d_out => sv_mux_leftright_out(0));
    --First Line Write Muxes
    mux6 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(352-4) , d_in1 => d_in(31 downto 24), ctrl => rowfirst, d_out => sv_mux_fl_out(0));
    mux7 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(353-4) , d_in1 => d_in(23 downto 16), ctrl => rowfirst, d_out => sv_mux_fl_out(1));
    mux8 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(354-4) , d_in1 => d_in(15 downto 8), ctrl => rowfirst, d_out => sv_mux_fl_out(2));
    mux9 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(355-4) , d_in1 => d_in(7 downto 0), ctrl => rowfirst, d_out => sv_mux_fl_out(3));
    --Last Line Write Muxes
    mux10 :     MUX_2_to_1_8b port map (d_in0 => sv_mux_leftright_out(0), d_in1 => sv_mux_leftright_out(2), ctrl => rowlast, d_out => sv_mux_ll_out(0));
    mux11 :     MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(4), d_in1 => sv_mem_dout(356), ctrl => rowlast, d_out => sv_mux_ll_out(1));
    mux12 :     MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(5), d_in1 => sv_mem_dout(357), ctrl => rowlast, d_out => sv_mux_ll_out(2));
    mux13 :     MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(6), d_in1 => sv_mem_dout(358), ctrl => rowlast, d_out => sv_mux_ll_out(3));
    mux14 :     MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(7), d_in1 => sv_mem_dout(359), ctrl => rowlast, d_out => sv_mux_ll_out(4));
    mux15 :     MUX_2_to_1_8b port map (d_in0 => sv_mux_leftright_out(1), d_in1 => sv_mux_leftright_out(3), ctrl => rowlast, d_out => sv_mux_ll_out(5));
    
    --Output Area 1
    d_out(7 downto 0) <= sv_mux_ll_out(0);
    d_out(15 downto 8) <= sv_mux_ll_out(1);
    d_out(23 downto 16) <= sv_mux_ll_out(2);
    d_out(31 downto 24) <= sv_mux_ll_out(3);
    d_out(39 downto 32) <= sv_mux_ll_out(4);
    d_out(47 downto 40) <= sv_mux_ll_out(5);
    --Output Area 2
    d_out(55 downto 48) <= sv_mux_leftright_out(2);
    d_out(63 downto 56) <= sv_mem_dout(356);
    d_out(71 downto 64) <= sv_mem_dout(357);
    d_out(79 downto 72) <= sv_mem_dout(358);
    d_out(87 downto 80) <= sv_mem_dout(359);
    d_out(95 downto 88) <= sv_mux_leftright_out(3);
    --Output Area 3
    d_out(103 downto 96) <= sv_mux_leftright_out(4);
    d_out(111 downto 104) <= sv_mem_dout(708);
    d_out(119 downto 112) <= sv_mem_dout(709);
    d_out(127 downto 120) <= sv_mem_dout(710);
    d_out(135 downto 128) <= sv_mem_dout(711);
    d_out(143 downto 136) <= sv_mux_leftright_out(5);
    
end Behavioral;
