library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pixel_fsm is
  generic (
    BUF_AW      : integer := 15;
    BUF_DEPTH   : integer := 25344;
    IMG_WIDTH   : integer := 88;
    EDGE_MIRROR : boolean := false;
    OUT_BASE    : integer := 0  
  );
  port (
    clk, rst_n   : in  std_logic;
    start        : in  std_logic;
    finish       : out std_logic;
    ibuf_rd_en   : out std_logic;
    ibuf_rd_addr : out std_logic_vector(BUF_AW-1 downto 0);
    obuf_wr_en   : out std_logic;
    obuf_wr_addr : out std_logic_vector(BUF_AW-1 downto 0);
    lb_shift_en  : out std_logic;
    lb_flush     : out std_logic;
    lb_first_w, lb_last_w, lb_first_row, lb_last_row : out std_logic;
    alu_en       : out std_logic
  );
end entity;

architecture rtl of pixel_fsm is
  function sel(c : boolean; a, b : integer) return integer is
  begin
    if c then return a; else return b; end if;
  end function;

  constant NROWS     : integer := BUF_DEPTH / IMG_WIDTH;
  constant FIRST_K   : integer := sel(EDGE_MIRROR, IMG_WIDTH + 1, 2*IMG_WIDTH + 1);
  constant N_DUMMY   : integer := sel(EDGE_MIRROR, IMG_WIDTH + 1, 1);
  constant N_OUT     : integer := sel(EDGE_MIRROR, BUF_DEPTH, BUF_DEPTH - 2*IMG_WIDTH);
  constant LAST_ADDR : integer := OUT_BASE + N_OUT - 1;

  type state_t is (IDLE, RUN, DRAIN);
  signal state     : state_t;
  signal rd_cnt    : integer range 0 to BUF_DEPTH-1;
  signal rd_en_i, last_p1, last_p2, rd_valid, dummy, v_chain, fin_pend, shift_en : std_logic;
  signal dummy_cnt : integer range 0 to N_DUMMY;
  signal sh_cnt    : integer range 0 to BUF_DEPTH + N_DUMMY;
  signal col_cnt   : integer range 0 to IMG_WIDTH-1;
  signal out_row   : integer range 0 to NROWS-1;
  signal out_addr  : integer range 0 to BUF_DEPTH-1;

begin
  ibuf_rd_en   <= rd_en_i;
  shift_en     <= rd_valid or dummy;
  lb_shift_en  <= shift_en;
  lb_flush     <= dummy;
  alu_en       <= v_chain;
  lb_first_w   <= '1' when EDGE_MIRROR and col_cnt = 0           else '0';
  lb_last_w    <= '1' when EDGE_MIRROR and col_cnt = IMG_WIDTH-1 else '0';
  lb_first_row <= '1' when EDGE_MIRROR and out_row = 0           else '0';
  lb_last_row  <= '1' when EDGE_MIRROR and out_row = NROWS-1     else '0';

  ctrl : process (clk, rst_n)
  begin
    if rst_n = '0' then
      state <= IDLE; 
      rd_cnt <= 0; 
      rd_en_i <= '0'; 
      ibuf_rd_addr <= (others => '0');
      last_p1 <= '0'; 
      last_p2 <= '0'; 
      rd_valid <= '0'; 
      dummy <= '0'; 
      dummy_cnt <= 0;
      sh_cnt <= 0; 
      v_chain <= '0'; 
      col_cnt <= 0; 
      out_row <= 0; 
      out_addr <= OUT_BASE;
      obuf_wr_en <= '0'; 
      obuf_wr_addr <= (others => '0'); 
      fin_pend <= '0'; 
      finish <= '0';
    elsif rising_edge(clk) then
      rd_en_i <= '0'; 
      last_p1 <= '0'; 
      finish <= '0'; 
      fin_pend <= '0';
      rd_valid <= rd_en_i; 
      last_p2 <= last_p1;
      v_chain <= '0'; 
      obuf_wr_en <= v_chain;

      if last_p2 = '1' then
        dummy <= '1'; 
        dummy_cnt <= N_DUMMY - 1;
      elsif dummy = '1' then
        if dummy_cnt = 0 then 
          dummy <= '0'; 
        else 
          dummy_cnt <= dummy_cnt - 1; 
        end if;
      end if;

      case state is
        when IDLE =>
          if start = '1' then
            rd_cnt <= 0; sh_cnt <= 0; col_cnt <= 0; out_row <= 0; out_addr <= OUT_BASE;
            state <= RUN;
          end if;
        when RUN =>
          rd_en_i      <= '1';
          ibuf_rd_addr <= std_logic_vector(to_unsigned(rd_cnt, BUF_AW));
          if rd_cnt = BUF_DEPTH-1 then 
            last_p1 <= '1'; 
            state <= DRAIN;
          else 
            rd_cnt <= rd_cnt + 1; 
          end if;
        when DRAIN => null;
      end case;

      if shift_en = '1' then
        sh_cnt <= sh_cnt + 1;
        if sh_cnt >= FIRST_K then 
          v_chain <= '1'; 
        end if;
      end if;

      if v_chain = '1' then
        if col_cnt = IMG_WIDTH-1 then
          col_cnt <= 0;
          if out_row = NROWS-1 then 
            out_row <= 0; 
          else 
            out_row <= out_row + 1; 
          end if;
        else
          col_cnt <= col_cnt + 1;
        end if;
        obuf_wr_addr <= std_logic_vector(to_unsigned(out_addr, BUF_AW));
        if out_addr = LAST_ADDR then 
          fin_pend <= '1'; 
        else 
          out_addr <= out_addr + 1; 
        end if;
      end if;

      if fin_pend = '1' then 
        finish <= '1'; 
        state <= IDLE; 
      end if;
    end if;
  end process ctrl;
end architecture;