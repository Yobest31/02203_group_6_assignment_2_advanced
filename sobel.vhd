library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sobel_pkg.all;

entity sobel is
  port (
    clk : in std_logic;
    rst_n : in std_logic;
    pixels_in : in quad_kernel_t;
    pixels_out : out std_logic_vector(31 downto 0)
  );
end entity sobel;

architecture sobel_rtl of sobel is 
  function to_s12(v : std_logic_vector(7 downto 0)) return signed is
  begin
    return signed(resize(unsigned(v), 12));
  end function;

  function sobel_fn(kernels: quad_kernel_t; offset: integer range 0 to 3) return std_logic_vector is
    variable tl, tm, tr, ml, mr, bl, bm, br : signed(11 downto 0);
    variable gx, gy : signed(11 downto 0);
    variable mag : unsigned(11 downto 0);
  begin
    bl := to_s12(kernels(offset));
    bm := to_s12(kernels(offset + 1));
    br := to_s12(kernels(offset + 2));
    ml := to_s12(kernels(offset + 6));
    mr := to_s12(kernels(offset + 8));
    tl := to_s12(kernels(offset + 12));
    tm := to_s12(kernels(offset + 13));
    tr := to_s12(kernels(offset + 14));
    
    gx := (tr + shift_left(mr, 1) + br) - (tl + shift_left(ml, 1) + bl);
    gy := (bl + shift_left(bm, 1) + br) - (tl + shift_left(tm, 1) + tr);

    mag := unsigned(abs(gx)) + unsigned(abs(gy)); -- max 2040, fits 12 bits

    if mag > 255 then
      return std_logic_vector(to_unsigned(255, 8));
    else
      return std_logic_vector(mag(7 downto 0));
    end if;
  end function;
begin

  proc : process (clk, rst_n)
  begin
    if rst_n = '0' then
      pixels_out <= (others => '0');
    elsif rising_edge(clk) then
      pixels_out <= sobel_fn(pixels_in, 3) & sobel_fn(pixels_in, 2) & sobel_fn(pixels_in, 1) & sobel_fn(pixels_in, 0);
    end if;
  end process;
  
end architecture sobel_rtl;