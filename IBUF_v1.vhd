----------------------------------------------------------------------------------
<<<<<<< HEAD
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
=======
-- Company:
-- Engineer:
--
-- Create Date: 11/12/2026 08:59:34 AM
-- Design Name:
-- Module Name: FSMD_IBUF - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description: Line buffer for the Sobel accelerator.
--              One 32-bit word (4 pixels) is shifted in per clock when en = '1'.
--              sv_mem_dout(4*w + b) = byte b of the word that came in w words ago:
--                  n (newest word)   = 0 .. 3
--                  c (centre word)   = 4 .. 7
--                  p (previous word) = 8 .. 11
--              One image row = 88 words = 352 positions, so
--                  bottom row = +0, middle row = +352, top row = +704.
--              Window for each row (6 bytes = columns c-1 .. c+4):
--                  e0 = p.byte3 (+11)   -> sol = '1': copy c.byte0 (+4)
--                  e1..e4 = c.byte0..3 (+4 .. +7)
--                  e5 = n.byte0 (+0)    -> eol = '1': copy c.byte3 (+7)
--              Highest position used = 704 + 11 = 715  ->  716 registers.
--
-- Dependencies: dram_8b.vhd, MUX_2_to_1_8b.vhd
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - Correct tap positions, 716 registers, en input, SOL/EOL muxes
-- Revision 0.03 - End-of-chain registers mem_712..mem_715 (one per byte lane), GEN_REG 4..711
-- Additional Comments:
--
>>>>>>> c9bb346b1aabb5e8dadd725aa9a9b01e13b0b7d8
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
<<<<<<< HEAD
           eol : in STD_LOGIC;
           sol : in STD_LOGIC;
           rowfirst : in STD_LOGIC;
           rowlast : in STD_LOGIC;
=======
           en : in STD_LOGIC;
           eol : in STD_LOGIC;
           sol : in STD_LOGIC;
>>>>>>> c9bb346b1aabb5e8dadd725aa9a9b01e13b0b7d8
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
<<<<<<< HEAD
    
=======

>>>>>>> c9bb346b1aabb5e8dadd725aa9a9b01e13b0b7d8
    component MUX_2_to_1_8b is
    Port ( d_in0 : in STD_LOGIC_VECTOR (7 downto 0);
           d_in1 : in STD_LOGIC_VECTOR (7 downto 0);
           ctrl : in STD_LOGIC;
           d_out : out STD_LOGIC_VECTOR (7 downto 0));
    end component;
<<<<<<< HEAD
    
    type vector8 is array (natural range <>) of std_logic_vector(7 downto 0);
    signal sv_mem_dout : vector8(712 downto 0);
    signal sv_mux_leftright_out : vector8(5 downto 0);
    signal sv_mux_fl_out : vector8(3 downto 0);
    signal sv_mux_ll_out : vector8(5 downto 0);
    
begin
    GEN_REG1 :
    for I in 4 to 351 generate
        memx : dram_8b port map (rst => rst, clk => clk, en => '1', d_in => sv_mem_dout(I-4), d_out => sv_mem_dout(I));
    end generate GEN_REG1;
    GEN_REG2 :
    for I in 356 to 712 generate
        memx : dram_8b port map (rst => rst, clk => clk, en => '1', d_in => sv_mem_dout(I-4), d_out => sv_mem_dout(I));
    end generate GEN_REG2;
    
    
    mem_0 :     dram_8b port map (rst => rst, clk => clk, en => '1', d_in => d_in(7 downto 0), d_out => sv_mem_dout(0));
    mem_1 :     dram_8b port map (rst => rst, clk => clk, en => '1', d_in => d_in(15 downto 8), d_out => sv_mem_dout(1));
    mem_2 :     dram_8b port map (rst => rst, clk => clk, en => '1', d_in => d_in(23 downto 16), d_out => sv_mem_dout(2));
    mem_3 :     dram_8b port map (rst => rst, clk => clk, en => '1', d_in => d_in(31 downto 24), d_out => sv_mem_dout(3));
    mem_712 :   dram_8b port map (rst => rst, clk => clk, en => '1', d_in => sv_mem_dout(712-4), d_out => sv_mem_dout(712));
    
    --First Line write registers
    mem_352 :   dram_8b port map (rst => rst, clk => clk, en => '1', d_in => sv_mux_fl_out(0), d_out => sv_mem_dout(352));
    mem_353 :   dram_8b port map (rst => rst, clk => clk, en => '1', d_in => sv_mux_fl_out(1), d_out => sv_mem_dout(353));
    mem_354 :   dram_8b port map (rst => rst, clk => clk, en => '1', d_in => sv_mux_fl_out(2), d_out => sv_mem_dout(354));
    mem_355 :   dram_8b port map (rst => rst, clk => clk, en => '1', d_in => sv_mux_fl_out(3), d_out => sv_mem_dout(355));
    
    --SOL muxes
    mux0 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(712), d_in1 => sv_mem_dout(711), ctrl => sol, d_out => sv_mux_leftright_out(5));
    mux1 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(360), d_in1 => sv_mem_dout(359), ctrl => sol, d_out => sv_mux_leftright_out(4));
    mux2 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(8), d_in1 => sv_mem_dout(7), ctrl => sol, d_out => sv_mux_leftright_out(3));
    --EOL muxes
    mux3 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(707), d_in1 => sv_mem_dout(708), ctrl => eol, d_out => sv_mux_leftright_out(2));
    mux4 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(355), d_in1 => sv_mem_dout(356), ctrl => eol, d_out => sv_mux_leftright_out(1));
    mux5 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(3), d_in1 => sv_mem_dout(4), ctrl => eol, d_out => sv_mux_leftright_out(0));
    --First Line Write Muxes
    mux6 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(348) , d_in1 => d_in(7 downto 0), ctrl => rowfirst, d_out => sv_mux_fl_out(0));
    mux7 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(349) , d_in1 => d_in(15 downto 8), ctrl => rowfirst, d_out => sv_mux_fl_out(1));
    mux8 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(350) , d_in1 => d_in(23 downto 16), ctrl => rowfirst, d_out => sv_mux_fl_out(2));
    mux9 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(351) , d_in1 => d_in(31 downto 24), ctrl => rowfirst, d_out => sv_mux_fl_out(3));
    --Last Line Write Muxes
    mux10 :      MUX_2_to_1_8b port map (d_in0 => sv_mux_leftright_out(0), d_in1 => sv_mux_leftright_out(2), ctrl => rowlast, d_out => sv_mux_ll_out(0));
    mux11 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(4), d_in1 => sv_mem_dout(356), ctrl => rowlast, d_out => sv_mux_ll_out(1));
    mux12 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(5), d_in1 => sv_mem_dout(357), ctrl => rowlast, d_out => sv_mux_ll_out(2));
    mux13 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(6), d_in1 => sv_mem_dout(358), ctrl => rowlast, d_out => sv_mux_ll_out(3));
    mux14 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(7), d_in1 => sv_mem_dout(359), ctrl => rowlast, d_out => sv_mux_ll_out(4));
    mux15 :      MUX_2_to_1_8b port map (d_in0 => sv_mux_leftright_out(1), d_in1 => sv_mux_leftright_out(3), ctrl => rowlast, d_out => sv_mux_ll_out(5));
    
    --Output Area 1
    d_out(7 downto 0) <= sv_mux_ll_out(0);
    d_out(15 downto 8) <= sv_mux_ll_out(1);
    d_out(23 downto 16) <= sv_mux_ll_out(2);
    d_out(31 downto 24) <= sv_mux_ll_out(3);
    d_out(39 downto 32) <= sv_mux_ll_out(4);
    d_out(47 downto 40) <= sv_mux_ll_out(5);
    --Output Area 2
    d_out(55 downto 48) <= sv_mux_leftright_out(2);
=======

    type vector8 is array (natural range <>) of std_logic_vector(7 downto 0);
    signal sv_mem_dout : vector8(715 downto 0);
    signal sv_dout : vector8(5 downto 0);

begin
    GEN_REG :
    for I in 4 to 711 generate
        memx : dram_8b port map (rst => rst, clk => clk, en => en, d_in => sv_mem_dout(I-4), d_out => sv_mem_dout(I));
    end generate GEN_REG;

    mem_0 :     dram_8b port map (rst => rst, clk => clk, en => en, d_in => d_in(7 downto 0), d_out => sv_mem_dout(0));
    mem_1 :     dram_8b port map (rst => rst, clk => clk, en => en, d_in => d_in(15 downto 8), d_out => sv_mem_dout(1));
    mem_2 :     dram_8b port map (rst => rst, clk => clk, en => en, d_in => d_in(23 downto 16), d_out => sv_mem_dout(2));
    mem_3 :     dram_8b port map (rst => rst, clk => clk, en => en, d_in => d_in(31 downto 24), d_out => sv_mem_dout(3));
    
    mem_712 :   dram_8b port map (rst => rst, clk => clk, en => en, d_in => sv_mem_dout(712-4), d_out => sv_mem_dout(712));
    mem_713 :   dram_8b port map (rst => rst, clk => clk, en => en, d_in => sv_mem_dout(713-4), d_out => sv_mem_dout(713));
    mem_714 :   dram_8b port map (rst => rst, clk => clk, en => en, d_in => sv_mem_dout(714-4), d_out => sv_mem_dout(714));
    mem_715 :   dram_8b port map (rst => rst, clk => clk, en => en, d_in => sv_mem_dout(715-4), d_out => sv_mem_dout(715));

    --SOL muxes (e0 of each row): sol = '0' -> p.byte3, sol = '1' -> c.byte0
    mux0 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(11),  d_in1 => sv_mem_dout(4),   ctrl => sol, d_out => sv_dout(0));
    mux1 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(363), d_in1 => sv_mem_dout(356), ctrl => sol, d_out => sv_dout(1));
    mux2 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(715), d_in1 => sv_mem_dout(708), ctrl => sol, d_out => sv_dout(2));
    --EOL muxes (e5 of each row): eol = '0' -> n.byte0, eol = '1' -> c.byte3
    mux3 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(0),   d_in1 => sv_mem_dout(7),   ctrl => eol, d_out => sv_dout(3));
    mux4 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(352), d_in1 => sv_mem_dout(359), ctrl => eol, d_out => sv_dout(4));
    mux5 :      MUX_2_to_1_8b port map (d_in0 => sv_mem_dout(704), d_in1 => sv_mem_dout(711), ctrl => eol, d_out => sv_dout(5));

    --Output Area 1 (bottom row)
    d_out(7 downto 0) <= sv_dout(0);
    d_out(15 downto 8) <= sv_mem_dout(4);
    d_out(23 downto 16) <= sv_mem_dout(5);
    d_out(31 downto 24) <= sv_mem_dout(6);
    d_out(39 downto 32) <= sv_mem_dout(7);
    d_out(47 downto 40) <= sv_dout(3);
    --Output Area 2 (middle row)
    d_out(55 downto 48) <= sv_dout(1);
>>>>>>> c9bb346b1aabb5e8dadd725aa9a9b01e13b0b7d8
    d_out(63 downto 56) <= sv_mem_dout(356);
    d_out(71 downto 64) <= sv_mem_dout(357);
    d_out(79 downto 72) <= sv_mem_dout(358);
    d_out(87 downto 80) <= sv_mem_dout(359);
<<<<<<< HEAD
    d_out(95 downto 88) <= sv_mux_leftright_out(3);
    --Output Area 3
    d_out(103 downto 96) <= sv_mux_leftright_out(4);
=======
    d_out(95 downto 88) <= sv_dout(4);
    --Output Area 3 (top row)
    d_out(103 downto 96) <= sv_dout(2);
>>>>>>> c9bb346b1aabb5e8dadd725aa9a9b01e13b0b7d8
    d_out(111 downto 104) <= sv_mem_dout(708);
    d_out(119 downto 112) <= sv_mem_dout(709);
    d_out(127 downto 120) <= sv_mem_dout(710);
    d_out(135 downto 128) <= sv_mem_dout(711);
<<<<<<< HEAD
    d_out(143 downto 136) <= sv_mux_leftright_out(5);
    
=======
    d_out(143 downto 136) <= sv_dout(5);

>>>>>>> c9bb346b1aabb5e8dadd725aa9a9b01e13b0b7d8
end Behavioral;
