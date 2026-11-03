-- A4.4 check: runs top_spiker over NINF samples; logs every out_spikes vector at each start_all ('sample') pulse and
-- the cycles of each inference (led(1) rising edges), via VHDL-2008 external names.
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all; use std.textio.all;
entity tb_top_spiker is generic (NINF : integer := 2; NSMP : integer := 2); end entity;
architecture sim of tb_top_spiker is
  signal clk : std_logic := '0'; signal rn : std_logic := '0'; signal led : std_logic_vector(7 downto 0);
  signal fin : boolean := false;
begin
  clk <= not clk after 5 ns when not fin;
  u : entity work.top_spiker generic map (NSMP => NSMP) port map (clk100 => clk, cpu_resetn => rn, led => led);
  process
    alias smp is <<signal .tb_top_spiker.u.sample : std_logic>>;
    alias osp is <<signal .tb_top_spiker.u.out_spikes : std_logic_vector(9 downto 0)>>;
    file fo : text open write_mode is "top_out.txt"; variable l : line; variable cyc, c0, inf : integer := 0;
    variable dq : std_logic := '1';
  begin
    wait for 100 ns; rn <= '1';
    loop
      wait until rising_edge(clk); cyc := cyc + 1;
      if smp = '1' then write(l, string'("S ") & to_string(osp)); writeline(fo, l); end if;
      if led(1) = '1' and dq = '0' then
        write(l, string'("I ") & integer'image(inf) & " " & integer'image(cyc - c0)); writeline(fo, l);
        write(l, string'("F ") & to_string(osp)); writeline(fo, l);
        c0 := cyc; inf := inf + 1; exit when inf = NINF; end if;
      dq := led(1);
      exit when cyc > 5000000;
    end loop;
    fin <= true; wait;
  end process;
end architecture;
