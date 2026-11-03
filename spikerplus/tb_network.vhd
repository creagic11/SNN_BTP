-- A4: testbench for a Spiker+ generated "network" (interface = False). Reads stim.txt (one line per timestep,
-- M characters, leftmost = input M-1), runs one inference, and writes out.txt: one line per start_all pulse with
-- the out_spikes vector seen at that moment, then "END <cycles>".
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all; use std.textio.all;
entity tb_network is generic (M : integer := 12; O : integer := 4; T : integer := 10; CW : integer := 5); end entity;
architecture sim of tb_network is
  signal clk : std_logic := '0'; signal rst_n, start, sample_ready : std_logic := '0';
  signal ready, sample : std_logic; signal in_spikes : std_logic_vector(M-1 downto 0) := (others => '0');
  signal out_spikes : std_logic_vector(O-1 downto 0);
  type stim_t is array (0 to T) of std_logic_vector(M-1 downto 0); signal stim : stim_t := (others => (others => '0'));
  signal done : boolean := false;
begin
  clk <= not clk after 5 ns when not done;
  dut : entity work.network generic map (n_cycles => T, cycles_cnt_bitwidth => CW)
    port map (clk => clk, rst_n => rst_n, start => start, sample_ready => sample_ready, ready => ready,
              sample => sample, in_spikes => in_spikes, out_spikes => out_spikes);
  process
    file fi : text open read_mode is "stim.txt"; file fo : text open write_mode is "out.txt";
    variable li, lo : line; variable s : string(1 to M); variable k : integer := 0; variable cyc : integer := 0;
    variable st : stim_t;
  begin
    for tt in 0 to T-1 loop readline(fi, li); read(li, s);
      for i in 0 to M-1 loop if s(M-i) = '1' then st(tt)(i) := '1'; else st(tt)(i) := '0'; end if; end loop; end loop;
    in_spikes <= st(0); sample_ready <= '1';
    wait for 52 ns; rst_n <= '1'; wait until rising_edge(clk) and ready = '1';
    wait until rising_edge(clk); start <= '1'; wait until rising_edge(clk); start <= '0';
    loop
      wait until rising_edge(clk); cyc := cyc + 1;
      if sample = '1' then
        write(lo, to_string(out_spikes)); writeline(fo, lo);
        wait until rising_edge(clk); wait until rising_edge(clk); cyc := cyc + 2;   -- sampled by now
        k := k + 1; if k < T then in_spikes <= st(k); else in_spikes <= (others => '0'); end if;
      end if;
      exit when k >= T and ready = '1';
      exit when cyc > 10000000;
    end loop;
    write(lo, to_string(out_spikes)); writeline(fo, lo);
    write(lo, string'("END ") & integer'image(cyc)); writeline(fo, lo);
    done <= true; wait;
  end process;
end architecture;
