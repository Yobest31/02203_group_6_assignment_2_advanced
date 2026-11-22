library ieee;
use ieee.std_logic_1164.all;
use work.sobel_pkg.all;

entity pixel_acc_vhd is
  generic (
    BUF_AW    : integer := 15;
    BUF_DEPTH : integer := 25344;
    IMG_WIDTH : integer := 88
  );
  port (
    clk          : in  std_logic;
    rst_n        : in  std_logic;

    ibuf_rd_en   : out std_logic;
    ibuf_rd_addr : out std_logic_vector(BUF_AW-1 downto 0);
    ibuf_rd_data : in  std_logic_vector(31 downto 0);

    obuf_wr_en   : out std_logic;
    obuf_wr_addr : out std_logic_vector(BUF_AW-1 downto 0);
    obuf_wr_data : out std_logic_vector(31 downto 0);

    start        : in  std_logic;
    finish       : out std_logic
  );
end entity pixel_acc_vhd;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sobel_pkg.all;

architecture rtl of pixel_acc_vhd is
  signal lb_first_w, lb_last_w, lb_first_row, lb_last_row, alu_en : std_logic;
  signal lb_shift_en, lb_flush : std_logic;
  signal lb_pixels_out : quad_kernel_t;
  signal lb_d_out : std_logic_vector(143 downto 0);

begin

  gen_map : for i in 0 to 5 generate
    lb_pixels_out(i)      <= lb_d_out(96 + 8*i + 7 downto 96 + 8*i);  -- top row
    lb_pixels_out(6 + i)  <= lb_d_out(48 + 8*i + 7 downto 48 + 8*i);  -- middle row
    lb_pixels_out(12 + i) <= lb_d_out(8*i + 7 downto 8*i);            -- bottom row
  end generate;

  u_fsm : entity work.pixel_fsm
    generic map (
      BUF_AW      => BUF_AW,
      BUF_DEPTH   => BUF_DEPTH,
      IMG_WIDTH   => IMG_WIDTH,
      EDGE_MIRROR => true,
      OUT_BASE    => 0
    )
    port map (
      clk          => clk,
      rst_n        => rst_n,
      start        => start,
      finish       => finish,
      ibuf_rd_en   => ibuf_rd_en,
      ibuf_rd_addr => ibuf_rd_addr,
      obuf_wr_en   => obuf_wr_en,
      obuf_wr_addr => obuf_wr_addr,
      lb_shift_en  => lb_shift_en,
      lb_flush     => lb_flush,
      lb_first_w   => lb_first_w,
      lb_last_w    => lb_last_w,
      lb_first_row => lb_first_row,
      lb_last_row  => lb_last_row,
      alu_en       => alu_en
    );

  u_linebuf : entity work.IBUF_v1
    port map (
      clk          => clk,
      rst          => rst_n,
      -- en           => lb_shift_en,
      -- flush        => lb_flush,
      eol          => lb_last_w,
      sol          => lb_first_w,
      rowfirst     => lb_first_row,
      rowlast      => lb_last_row,
      d_in         => ibuf_rd_data,
      d_out        => lb_d_out
    );

  u_sobel : entity work.sobel
    port map (
      clk => clk, 
      rst_n => rst_n, 
      pixels_in => lb_pixels_out, 
      pixels_out => obuf_wr_data
    );

end architecture rtl;