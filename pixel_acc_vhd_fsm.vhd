library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pixel_fsm is
  generic (
    BUF_AW      : integer := 15;
    BUF_DEPTH   : integer := 25344;
    IMG_WIDTH   : integer := 88;
    EDGE_MIRROR : boolean := true;
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
  -- output row index (rows already completed) at which the last output row ends
  constant END_ROW   : integer := sel(EDGE_MIRROR, NROWS - 2, NROWS - 3);

  type state_t is (IDLE, LOAD_ROW0, FILL_ROW1, FIRST_W, MID_W, LAST_W, LAST_ROW, FIN);
  signal state : state_t;

  signal rd_cnt    : integer range 0 to BUF_DEPTH-1;
  signal rd_run, rd_en_i, rd_valid, last_p1, last_p2 : std_logic;
  signal ld0_a, ld0_b : std_logic;
  signal dummy     : std_logic;
  signal dummy_cnt : integer range 0 to N_DUMMY;
  signal sh_cnt    : integer range 0 to BUF_DEPTH + N_DUMMY;
  signal shift_en, first_tap, v_chain : std_logic;
  signal col_cnt   : integer range 0 to IMG_WIDTH-1;
  signal out_row   : integer range 0 to NROWS-1;
  signal out_addr  : integer range 0 to BUF_DEPTH-1;
begin
  assert not (EDGE_MIRROR and OUT_BASE /= 0)
    report "EDGE_MIRROR requires OUT_BASE = 0" severity failure;
  assert IMG_WIDTH >= 3 report "IMG_WIDTH must be >= 3" severity failure;

  ibuf_rd_en  <= rd_en_i;
  shift_en    <= rd_valid or dummy;
  first_tap   <= '1' when shift_en = '1' and sh_cnt >= FIRST_K else '0';
  lb_shift_en <= shift_en;
  lb_flush    <= dummy;
  alu_en      <= v_chain;

  lb_first_row <= ld0_b when EDGE_MIRROR else '0';
  lb_last_row  <= dummy when EDGE_MIRROR else '0';
  lb_first_w   <= '1' when EDGE_MIRROR and
                  (state = FIRST_W or (state = LAST_ROW and col_cnt = 0)) else '0';
  lb_last_w    <= '1' when EDGE_MIRROR and
                  (state = LAST_W or (state = LAST_ROW and col_cnt = IMG_WIDTH-1)) else '0';

  ctrl : process (clk, rst_n)
  begin
    if rst_n = '0' then
      state <= IDLE; rd_cnt <= 0; rd_run <= '0'; rd_en_i <= '0'; rd_valid <= '0';
      ibuf_rd_addr <= (others => '0'); last_p1 <= '0'; last_p2 <= '0';
      ld0_a <= '0'; ld0_b <= '0'; dummy <= '0'; dummy_cnt <= 0; sh_cnt <= 0;
      v_chain <= '0'; col_cnt <= 0; out_row <= 0; out_addr <= OUT_BASE;
      obuf_wr_en <= '0'; obuf_wr_addr <= (others => '0'); finish <= '0';
    elsif rising_edge(clk) then
      rd_en_i <= '0'; last_p1 <= '0'; finish <= '0'; ld0_a <= '0'; v_chain <= '0';
      rd_valid <= rd_en_i; last_p2 <= last_p1; ld0_b <= ld0_a;
      obuf_wr_en <= v_chain;

      if last_p2 = '1' then
        dummy <= '1'; dummy_cnt <= N_DUMMY - 1;
      elsif dummy = '1' then
        if dummy_cnt = 0 then dummy <= '0'; else dummy_cnt <= dummy_cnt - 1; end if;
      end if;

      if rd_run = '1' then
        rd_en_i      <= '1';
        ibuf_rd_addr <= std_logic_vector(to_unsigned(rd_cnt, BUF_AW));
        if rd_cnt = BUF_DEPTH-1 then
          last_p1 <= '1'; rd_run <= '0';
        else
          rd_cnt <= rd_cnt + 1;
        end if;
      end if;

      if shift_en = '1' then sh_cnt <= sh_cnt + 1; end if;
      if first_tap = '1' then v_chain <= '1'; end if;

      if v_chain = '1' then
        obuf_wr_addr <= std_logic_vector(to_unsigned(out_addr, BUF_AW));
        if out_addr /= LAST_ADDR then out_addr <= out_addr + 1; end if;
      end if;

      case state is
        when IDLE =>
          if start = '1' then
            rd_cnt <= 0; sh_cnt <= 0; col_cnt <= 0; out_row <= 0; out_addr <= OUT_BASE;
            rd_run <= '1';
            state  <= LOAD_ROW0;
          end if;

        when LOAD_ROW0 =>
          if EDGE_MIRROR then ld0_a <= '1'; end if;   -- row-0 copy only when mirroring
          if rd_cnt = IMG_WIDTH-1 then state <= FILL_ROW1; end if;

        when FILL_ROW1 =>
          if first_tap = '1' then state <= FIRST_W; end if;

        when FIRST_W =>
          col_cnt <= 1;
          state   <= MID_W;

        when MID_W =>
          col_cnt <= col_cnt + 1;
          if col_cnt = IMG_WIDTH-2 then state <= LAST_W; end if;

        when LAST_W =>
          col_cnt <= 0;
          if out_row = END_ROW then
            if EDGE_MIRROR then state <= LAST_ROW; else state <= FIN; end if;
          else
            out_row <= out_row + 1;
            state   <= FIRST_W;
          end if;

        when LAST_ROW =>                      -- reached only when EDGE_MIRROR
          if col_cnt = IMG_WIDTH-1 then
            state <= FIN;
          else
            col_cnt <= col_cnt + 1;
          end if;

        when FIN =>
          finish <= '1';
          state  <= IDLE;
      end case;
    end if;
  end process ctrl;
end architecture;