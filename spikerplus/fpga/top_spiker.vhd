-- A4.4: board/power top for the Spiker+ generated network on the XC7A100T (Nexys A7-100T pins as top_hush).
-- Same harness as our top_hush: NSMP N-MNIST samples stored on chip (one 578-bit spike word per timestep, file
-- spk.mem, line s*T + t), autorun over the samples back to back, and every output spike folded into the LEDs so
-- nothing can be optimised away. LEDs: [0] heartbeat, [1] done (high between inferences), [7:2] XOR-fold of
-- every out_spikes vector seen.
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all; use std.textio.all;
entity top_spiker is
  generic (M : integer := 578; O : integer := 10; T : integer := 100; NSMP : integer := 20; CW : integer := 8;
           SPK_FILE : string := "spk.mem");
  port (clk100 : in std_logic; cpu_resetn : in std_logic; led : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of top_spiker is
  type mem_t is array (0 to NSMP*T - 1) of std_logic_vector(M-1 downto 0);
  impure function load(fname : string) return mem_t is
    file f : text open read_mode is fname; variable l : line; variable s : string(1 to M); variable r : mem_t;
  begin
    for a in 0 to NSMP*T - 1 loop readline(f, l); read(l, s);
      for i in 0 to M-1 loop if s(M-i) = '1' then r(a)(i) := '1'; else r(a)(i) := '0'; end if; end loop; end loop;
    return r;
  end function;
  signal mem : mem_t := load(SPK_FILE);
  attribute ram_style : string; attribute ram_style of mem : signal is "block";
  signal rst_sync : std_logic_vector(3 downto 0) := (others => '1'); signal rst_n : std_logic;
  signal start, ready, sample, ready_q : std_logic := '0';
  signal in_spikes : std_logic_vector(M-1 downto 0) := (others => '0');
  signal out_spikes : std_logic_vector(O-1 downto 0);
  signal addr : integer range 0 to NSMP*T - 1 := 0;
  signal base : integer range 0 to NSMP*T - 1 := 0;
  signal k : integer range 0 to T := 0;
  signal adv : std_logic_vector(1 downto 0) := "00";
  signal running : std_logic := '0';
  signal n_inf : unsigned(23 downto 0) := (others => '0');
  signal fold : std_logic_vector(5 downto 0) := (others => '0');
  function fold6(x : std_logic_vector) return std_logic_vector is
    variable f : std_logic_vector(5 downto 0) := (others => '0');
  begin for i in x'range loop f(i mod 6) := f(i mod 6) xor x(i); end loop; return f; end function;
begin
  process (clk100) begin if rising_edge(clk100) then rst_sync <= rst_sync(2 downto 0) & (not cpu_resetn); end if; end process;
  rst_n <= not rst_sync(3);
  dut : entity work.network generic map (n_cycles => T, cycles_cnt_bitwidth => CW)
    port map (clk => clk100, rst_n => rst_n, start => start, sample_ready => '1', ready => ready, sample => sample,
              in_spikes => in_spikes, out_spikes => out_spikes);
  -- spike store: synchronous read (block RAM), address = base + k
  process (clk100) begin if rising_edge(clk100) then in_spikes <= mem(addr); end if; end process;
  addr <= base + k when k < T else base;
  process (clk100) begin
    if rising_edge(clk100) then
      if rst_n = '0' then start <= '0'; running <= '0'; k <= 0; base <= 0; adv <= "00"; n_inf <= (others => '0');
        fold <= (others => '0'); ready_q <= '0';
      else
        start <= '0'; ready_q <= ready;
        -- the layers sample in_spikes in the cycle after start_all ('sample'); step k+1's word is fetched afterwards
        adv <= adv(0) & sample;
        if adv(1) = '1' and k < T then k <= k + 1; end if;
        if sample = '1' then fold <= fold xor fold6(out_spikes); end if;
        if running = '0' and ready = '1' and start = '0' then start <= '1'; running <= '1';
        elsif running = '1' and ready = '1' and ready_q = '0' and k = T then     -- inference finished
          running <= '0'; k <= 0; n_inf <= n_inf + 1;
          if base = (NSMP - 1) * T then base <= 0; else base <= base + T; end if;
        end if;
      end if;
    end if;
  end process;
  led <= fold & (not running) & n_inf(12);
end architecture;
