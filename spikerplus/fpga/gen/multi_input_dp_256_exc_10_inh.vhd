---------------------------------------------------------------------------------
-- This is free and unencumbered software released into the public domain.
--
-- Anyone is free to copy, modify, publish, use, compile, sell, or
-- distribute this software, either in source code form or as a compiled
-- binary, for any purpose, commercial or non-commercial, and by any
-- means.
--
-- In jurisdictions that recognize copyright laws, the author or authors
-- of this software dedicate any and all copyright interest in the
-- software to the public domain. We make this dedication for the benefit
-- of the public at large and to the detriment of our heirs and
-- successors. We intend this dedication to be an overt act of
-- relinquishment in perpetuity of all present and future rights to this
-- software under copyright law.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
-- OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
-- ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
-- OTHER DEALINGS IN THE SOFTWARE.
--
-- For more information, please refer to <http://unlicense.org/>
---------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity multi_input_dp_256_exc_10_inh is
    generic (
        n_exc_inputs : integer := 256;
        n_inh_inputs : integer := 10;
        exc_cnt_bitwidth : integer := 8;
        inh_cnt_bitwidth : integer := 4
    );
    port (
        clk : in std_logic;
        exc_spikes : in std_logic_vector(n_exc_inputs-1 downto 0);
        inh_spikes : in std_logic_vector(n_inh_inputs-1 downto 0);
        exc_sample : in std_logic;
        exc_rst_n : in std_logic;
        exc_cnt_en : in std_logic;
        exc_cnt_rst_n : in std_logic;
        inh_sample : in std_logic;
        inh_rst_n : in std_logic;
        inh_cnt_en : in std_logic;
        inh_cnt_rst_n : in std_logic;
        exc_yes : out std_logic;
        exc_spike : out std_logic;
        exc_stop : out std_logic;
        exc_cnt : out std_logic_vector(exc_cnt_bitwidth - 1 downto 0);
        inh_yes : out std_logic;
        inh_spike : out std_logic;
        inh_stop : out std_logic;
        inh_cnt : out std_logic_vector(inh_cnt_bitwidth - 1 downto 0)
    );
end entity multi_input_dp_256_exc_10_inh;

architecture behavior of multi_input_dp_256_exc_10_inh is


    component generic_or is
        generic (
            N : integer := 256
        );
        port (
            or_in : in std_logic_vector(N-1 downto 0);
            or_out : out std_logic
        );
    end component;

    component reg_sync_rst is
        generic (
            N : integer := 256
        );
        port (
            clk : in std_logic;
            en : in std_logic;
            rst_n : in std_logic;
            reg_in : in std_logic_vector(N-1 downto 0);
            reg_out : out std_logic_vector(N-1 downto 0)
        );
    end component;

    component cnt is
        generic (
            N : integer := 8;
            rst_value : integer := 0
        );
        port (
            clk : in std_logic;
            cnt_en : in std_logic;
            cnt_rst_n : in std_logic;
            cnt_out : out std_logic_vector(N-1 downto 0)
        );
    end component;

    component cmp_eq is
        generic (
            N : integer := 8
        );
        port (
            in0 : in std_logic_vector(N-1 downto 0);
            in1 : in std_logic_vector(N-1 downto 0);
            cmp_out : out std_logic
        );
    end component;

    component mux_256to1 is
        port (
            mux_sel : in std_logic_vector(7 downto 0);
            in0 : in std_logic;
            in1 : in std_logic;
            in2 : in std_logic;
            in3 : in std_logic;
            in4 : in std_logic;
            in5 : in std_logic;
            in6 : in std_logic;
            in7 : in std_logic;
            in8 : in std_logic;
            in9 : in std_logic;
            in10 : in std_logic;
            in11 : in std_logic;
            in12 : in std_logic;
            in13 : in std_logic;
            in14 : in std_logic;
            in15 : in std_logic;
            in16 : in std_logic;
            in17 : in std_logic;
            in18 : in std_logic;
            in19 : in std_logic;
            in20 : in std_logic;
            in21 : in std_logic;
            in22 : in std_logic;
            in23 : in std_logic;
            in24 : in std_logic;
            in25 : in std_logic;
            in26 : in std_logic;
            in27 : in std_logic;
            in28 : in std_logic;
            in29 : in std_logic;
            in30 : in std_logic;
            in31 : in std_logic;
            in32 : in std_logic;
            in33 : in std_logic;
            in34 : in std_logic;
            in35 : in std_logic;
            in36 : in std_logic;
            in37 : in std_logic;
            in38 : in std_logic;
            in39 : in std_logic;
            in40 : in std_logic;
            in41 : in std_logic;
            in42 : in std_logic;
            in43 : in std_logic;
            in44 : in std_logic;
            in45 : in std_logic;
            in46 : in std_logic;
            in47 : in std_logic;
            in48 : in std_logic;
            in49 : in std_logic;
            in50 : in std_logic;
            in51 : in std_logic;
            in52 : in std_logic;
            in53 : in std_logic;
            in54 : in std_logic;
            in55 : in std_logic;
            in56 : in std_logic;
            in57 : in std_logic;
            in58 : in std_logic;
            in59 : in std_logic;
            in60 : in std_logic;
            in61 : in std_logic;
            in62 : in std_logic;
            in63 : in std_logic;
            in64 : in std_logic;
            in65 : in std_logic;
            in66 : in std_logic;
            in67 : in std_logic;
            in68 : in std_logic;
            in69 : in std_logic;
            in70 : in std_logic;
            in71 : in std_logic;
            in72 : in std_logic;
            in73 : in std_logic;
            in74 : in std_logic;
            in75 : in std_logic;
            in76 : in std_logic;
            in77 : in std_logic;
            in78 : in std_logic;
            in79 : in std_logic;
            in80 : in std_logic;
            in81 : in std_logic;
            in82 : in std_logic;
            in83 : in std_logic;
            in84 : in std_logic;
            in85 : in std_logic;
            in86 : in std_logic;
            in87 : in std_logic;
            in88 : in std_logic;
            in89 : in std_logic;
            in90 : in std_logic;
            in91 : in std_logic;
            in92 : in std_logic;
            in93 : in std_logic;
            in94 : in std_logic;
            in95 : in std_logic;
            in96 : in std_logic;
            in97 : in std_logic;
            in98 : in std_logic;
            in99 : in std_logic;
            in100 : in std_logic;
            in101 : in std_logic;
            in102 : in std_logic;
            in103 : in std_logic;
            in104 : in std_logic;
            in105 : in std_logic;
            in106 : in std_logic;
            in107 : in std_logic;
            in108 : in std_logic;
            in109 : in std_logic;
            in110 : in std_logic;
            in111 : in std_logic;
            in112 : in std_logic;
            in113 : in std_logic;
            in114 : in std_logic;
            in115 : in std_logic;
            in116 : in std_logic;
            in117 : in std_logic;
            in118 : in std_logic;
            in119 : in std_logic;
            in120 : in std_logic;
            in121 : in std_logic;
            in122 : in std_logic;
            in123 : in std_logic;
            in124 : in std_logic;
            in125 : in std_logic;
            in126 : in std_logic;
            in127 : in std_logic;
            in128 : in std_logic;
            in129 : in std_logic;
            in130 : in std_logic;
            in131 : in std_logic;
            in132 : in std_logic;
            in133 : in std_logic;
            in134 : in std_logic;
            in135 : in std_logic;
            in136 : in std_logic;
            in137 : in std_logic;
            in138 : in std_logic;
            in139 : in std_logic;
            in140 : in std_logic;
            in141 : in std_logic;
            in142 : in std_logic;
            in143 : in std_logic;
            in144 : in std_logic;
            in145 : in std_logic;
            in146 : in std_logic;
            in147 : in std_logic;
            in148 : in std_logic;
            in149 : in std_logic;
            in150 : in std_logic;
            in151 : in std_logic;
            in152 : in std_logic;
            in153 : in std_logic;
            in154 : in std_logic;
            in155 : in std_logic;
            in156 : in std_logic;
            in157 : in std_logic;
            in158 : in std_logic;
            in159 : in std_logic;
            in160 : in std_logic;
            in161 : in std_logic;
            in162 : in std_logic;
            in163 : in std_logic;
            in164 : in std_logic;
            in165 : in std_logic;
            in166 : in std_logic;
            in167 : in std_logic;
            in168 : in std_logic;
            in169 : in std_logic;
            in170 : in std_logic;
            in171 : in std_logic;
            in172 : in std_logic;
            in173 : in std_logic;
            in174 : in std_logic;
            in175 : in std_logic;
            in176 : in std_logic;
            in177 : in std_logic;
            in178 : in std_logic;
            in179 : in std_logic;
            in180 : in std_logic;
            in181 : in std_logic;
            in182 : in std_logic;
            in183 : in std_logic;
            in184 : in std_logic;
            in185 : in std_logic;
            in186 : in std_logic;
            in187 : in std_logic;
            in188 : in std_logic;
            in189 : in std_logic;
            in190 : in std_logic;
            in191 : in std_logic;
            in192 : in std_logic;
            in193 : in std_logic;
            in194 : in std_logic;
            in195 : in std_logic;
            in196 : in std_logic;
            in197 : in std_logic;
            in198 : in std_logic;
            in199 : in std_logic;
            in200 : in std_logic;
            in201 : in std_logic;
            in202 : in std_logic;
            in203 : in std_logic;
            in204 : in std_logic;
            in205 : in std_logic;
            in206 : in std_logic;
            in207 : in std_logic;
            in208 : in std_logic;
            in209 : in std_logic;
            in210 : in std_logic;
            in211 : in std_logic;
            in212 : in std_logic;
            in213 : in std_logic;
            in214 : in std_logic;
            in215 : in std_logic;
            in216 : in std_logic;
            in217 : in std_logic;
            in218 : in std_logic;
            in219 : in std_logic;
            in220 : in std_logic;
            in221 : in std_logic;
            in222 : in std_logic;
            in223 : in std_logic;
            in224 : in std_logic;
            in225 : in std_logic;
            in226 : in std_logic;
            in227 : in std_logic;
            in228 : in std_logic;
            in229 : in std_logic;
            in230 : in std_logic;
            in231 : in std_logic;
            in232 : in std_logic;
            in233 : in std_logic;
            in234 : in std_logic;
            in235 : in std_logic;
            in236 : in std_logic;
            in237 : in std_logic;
            in238 : in std_logic;
            in239 : in std_logic;
            in240 : in std_logic;
            in241 : in std_logic;
            in242 : in std_logic;
            in243 : in std_logic;
            in244 : in std_logic;
            in245 : in std_logic;
            in246 : in std_logic;
            in247 : in std_logic;
            in248 : in std_logic;
            in249 : in std_logic;
            in250 : in std_logic;
            in251 : in std_logic;
            in252 : in std_logic;
            in253 : in std_logic;
            in254 : in std_logic;
            in255 : in std_logic;
            mux_out : out std_logic
        );
    end component;

    component mux_16to1 is
        port (
            mux_sel : in std_logic_vector(3 downto 0);
            in0 : in std_logic;
            in1 : in std_logic;
            in2 : in std_logic;
            in3 : in std_logic;
            in4 : in std_logic;
            in5 : in std_logic;
            in6 : in std_logic;
            in7 : in std_logic;
            in8 : in std_logic;
            in9 : in std_logic;
            in10 : in std_logic;
            in11 : in std_logic;
            in12 : in std_logic;
            in13 : in std_logic;
            in14 : in std_logic;
            in15 : in std_logic;
            mux_out : out std_logic
        );
    end component;


    signal exc_spikes_sampled : std_logic_vector(n_exc_inputs-1 downto 0);
    signal inh_spikes_sampled : std_logic_vector(n_inh_inputs-1 downto 0);
    signal exc_cnt_sig : std_logic_vector(exc_cnt_bitwidth-1 downto 0);
    signal inh_cnt_sig : std_logic_vector(inh_cnt_bitwidth-1 downto 0);

begin

    exc_cnt <= exc_cnt_sig;
    inh_cnt <= inh_cnt_sig;


    exc_or : generic_or
        generic map(
            N => n_exc_inputs
        )
        port map(
            or_in => exc_spikes,
            or_out => exc_yes
        );

    inh_or : generic_or
        generic map(
            N => n_inh_inputs
        )
        port map(
            or_in => inh_spikes,
            or_out => inh_yes
        );

    exc_reg : reg_sync_rst
        generic map(
            N => n_exc_inputs
        )
        port map(
            clk => clk,
            en => exc_sample,
            rst_n => exc_rst_n,
            reg_in => exc_spikes,
            reg_out => exc_spikes_sampled
        );

    inh_reg : reg_sync_rst
        generic map(
            N => n_inh_inputs
        )
        port map(
            clk => clk,
            en => inh_sample,
            rst_n => inh_rst_n,
            reg_in => inh_spikes,
            reg_out => inh_spikes_sampled
        );

    exc_mux : mux_256to1
        port map(
            mux_sel => exc_cnt_sig,
            in0 => exc_spikes_sampled(0),
            in1 => exc_spikes_sampled(1),
            in2 => exc_spikes_sampled(2),
            in3 => exc_spikes_sampled(3),
            in4 => exc_spikes_sampled(4),
            in5 => exc_spikes_sampled(5),
            in6 => exc_spikes_sampled(6),
            in7 => exc_spikes_sampled(7),
            in8 => exc_spikes_sampled(8),
            in9 => exc_spikes_sampled(9),
            in10 => exc_spikes_sampled(10),
            in11 => exc_spikes_sampled(11),
            in12 => exc_spikes_sampled(12),
            in13 => exc_spikes_sampled(13),
            in14 => exc_spikes_sampled(14),
            in15 => exc_spikes_sampled(15),
            in16 => exc_spikes_sampled(16),
            in17 => exc_spikes_sampled(17),
            in18 => exc_spikes_sampled(18),
            in19 => exc_spikes_sampled(19),
            in20 => exc_spikes_sampled(20),
            in21 => exc_spikes_sampled(21),
            in22 => exc_spikes_sampled(22),
            in23 => exc_spikes_sampled(23),
            in24 => exc_spikes_sampled(24),
            in25 => exc_spikes_sampled(25),
            in26 => exc_spikes_sampled(26),
            in27 => exc_spikes_sampled(27),
            in28 => exc_spikes_sampled(28),
            in29 => exc_spikes_sampled(29),
            in30 => exc_spikes_sampled(30),
            in31 => exc_spikes_sampled(31),
            in32 => exc_spikes_sampled(32),
            in33 => exc_spikes_sampled(33),
            in34 => exc_spikes_sampled(34),
            in35 => exc_spikes_sampled(35),
            in36 => exc_spikes_sampled(36),
            in37 => exc_spikes_sampled(37),
            in38 => exc_spikes_sampled(38),
            in39 => exc_spikes_sampled(39),
            in40 => exc_spikes_sampled(40),
            in41 => exc_spikes_sampled(41),
            in42 => exc_spikes_sampled(42),
            in43 => exc_spikes_sampled(43),
            in44 => exc_spikes_sampled(44),
            in45 => exc_spikes_sampled(45),
            in46 => exc_spikes_sampled(46),
            in47 => exc_spikes_sampled(47),
            in48 => exc_spikes_sampled(48),
            in49 => exc_spikes_sampled(49),
            in50 => exc_spikes_sampled(50),
            in51 => exc_spikes_sampled(51),
            in52 => exc_spikes_sampled(52),
            in53 => exc_spikes_sampled(53),
            in54 => exc_spikes_sampled(54),
            in55 => exc_spikes_sampled(55),
            in56 => exc_spikes_sampled(56),
            in57 => exc_spikes_sampled(57),
            in58 => exc_spikes_sampled(58),
            in59 => exc_spikes_sampled(59),
            in60 => exc_spikes_sampled(60),
            in61 => exc_spikes_sampled(61),
            in62 => exc_spikes_sampled(62),
            in63 => exc_spikes_sampled(63),
            in64 => exc_spikes_sampled(64),
            in65 => exc_spikes_sampled(65),
            in66 => exc_spikes_sampled(66),
            in67 => exc_spikes_sampled(67),
            in68 => exc_spikes_sampled(68),
            in69 => exc_spikes_sampled(69),
            in70 => exc_spikes_sampled(70),
            in71 => exc_spikes_sampled(71),
            in72 => exc_spikes_sampled(72),
            in73 => exc_spikes_sampled(73),
            in74 => exc_spikes_sampled(74),
            in75 => exc_spikes_sampled(75),
            in76 => exc_spikes_sampled(76),
            in77 => exc_spikes_sampled(77),
            in78 => exc_spikes_sampled(78),
            in79 => exc_spikes_sampled(79),
            in80 => exc_spikes_sampled(80),
            in81 => exc_spikes_sampled(81),
            in82 => exc_spikes_sampled(82),
            in83 => exc_spikes_sampled(83),
            in84 => exc_spikes_sampled(84),
            in85 => exc_spikes_sampled(85),
            in86 => exc_spikes_sampled(86),
            in87 => exc_spikes_sampled(87),
            in88 => exc_spikes_sampled(88),
            in89 => exc_spikes_sampled(89),
            in90 => exc_spikes_sampled(90),
            in91 => exc_spikes_sampled(91),
            in92 => exc_spikes_sampled(92),
            in93 => exc_spikes_sampled(93),
            in94 => exc_spikes_sampled(94),
            in95 => exc_spikes_sampled(95),
            in96 => exc_spikes_sampled(96),
            in97 => exc_spikes_sampled(97),
            in98 => exc_spikes_sampled(98),
            in99 => exc_spikes_sampled(99),
            in100 => exc_spikes_sampled(100),
            in101 => exc_spikes_sampled(101),
            in102 => exc_spikes_sampled(102),
            in103 => exc_spikes_sampled(103),
            in104 => exc_spikes_sampled(104),
            in105 => exc_spikes_sampled(105),
            in106 => exc_spikes_sampled(106),
            in107 => exc_spikes_sampled(107),
            in108 => exc_spikes_sampled(108),
            in109 => exc_spikes_sampled(109),
            in110 => exc_spikes_sampled(110),
            in111 => exc_spikes_sampled(111),
            in112 => exc_spikes_sampled(112),
            in113 => exc_spikes_sampled(113),
            in114 => exc_spikes_sampled(114),
            in115 => exc_spikes_sampled(115),
            in116 => exc_spikes_sampled(116),
            in117 => exc_spikes_sampled(117),
            in118 => exc_spikes_sampled(118),
            in119 => exc_spikes_sampled(119),
            in120 => exc_spikes_sampled(120),
            in121 => exc_spikes_sampled(121),
            in122 => exc_spikes_sampled(122),
            in123 => exc_spikes_sampled(123),
            in124 => exc_spikes_sampled(124),
            in125 => exc_spikes_sampled(125),
            in126 => exc_spikes_sampled(126),
            in127 => exc_spikes_sampled(127),
            in128 => exc_spikes_sampled(128),
            in129 => exc_spikes_sampled(129),
            in130 => exc_spikes_sampled(130),
            in131 => exc_spikes_sampled(131),
            in132 => exc_spikes_sampled(132),
            in133 => exc_spikes_sampled(133),
            in134 => exc_spikes_sampled(134),
            in135 => exc_spikes_sampled(135),
            in136 => exc_spikes_sampled(136),
            in137 => exc_spikes_sampled(137),
            in138 => exc_spikes_sampled(138),
            in139 => exc_spikes_sampled(139),
            in140 => exc_spikes_sampled(140),
            in141 => exc_spikes_sampled(141),
            in142 => exc_spikes_sampled(142),
            in143 => exc_spikes_sampled(143),
            in144 => exc_spikes_sampled(144),
            in145 => exc_spikes_sampled(145),
            in146 => exc_spikes_sampled(146),
            in147 => exc_spikes_sampled(147),
            in148 => exc_spikes_sampled(148),
            in149 => exc_spikes_sampled(149),
            in150 => exc_spikes_sampled(150),
            in151 => exc_spikes_sampled(151),
            in152 => exc_spikes_sampled(152),
            in153 => exc_spikes_sampled(153),
            in154 => exc_spikes_sampled(154),
            in155 => exc_spikes_sampled(155),
            in156 => exc_spikes_sampled(156),
            in157 => exc_spikes_sampled(157),
            in158 => exc_spikes_sampled(158),
            in159 => exc_spikes_sampled(159),
            in160 => exc_spikes_sampled(160),
            in161 => exc_spikes_sampled(161),
            in162 => exc_spikes_sampled(162),
            in163 => exc_spikes_sampled(163),
            in164 => exc_spikes_sampled(164),
            in165 => exc_spikes_sampled(165),
            in166 => exc_spikes_sampled(166),
            in167 => exc_spikes_sampled(167),
            in168 => exc_spikes_sampled(168),
            in169 => exc_spikes_sampled(169),
            in170 => exc_spikes_sampled(170),
            in171 => exc_spikes_sampled(171),
            in172 => exc_spikes_sampled(172),
            in173 => exc_spikes_sampled(173),
            in174 => exc_spikes_sampled(174),
            in175 => exc_spikes_sampled(175),
            in176 => exc_spikes_sampled(176),
            in177 => exc_spikes_sampled(177),
            in178 => exc_spikes_sampled(178),
            in179 => exc_spikes_sampled(179),
            in180 => exc_spikes_sampled(180),
            in181 => exc_spikes_sampled(181),
            in182 => exc_spikes_sampled(182),
            in183 => exc_spikes_sampled(183),
            in184 => exc_spikes_sampled(184),
            in185 => exc_spikes_sampled(185),
            in186 => exc_spikes_sampled(186),
            in187 => exc_spikes_sampled(187),
            in188 => exc_spikes_sampled(188),
            in189 => exc_spikes_sampled(189),
            in190 => exc_spikes_sampled(190),
            in191 => exc_spikes_sampled(191),
            in192 => exc_spikes_sampled(192),
            in193 => exc_spikes_sampled(193),
            in194 => exc_spikes_sampled(194),
            in195 => exc_spikes_sampled(195),
            in196 => exc_spikes_sampled(196),
            in197 => exc_spikes_sampled(197),
            in198 => exc_spikes_sampled(198),
            in199 => exc_spikes_sampled(199),
            in200 => exc_spikes_sampled(200),
            in201 => exc_spikes_sampled(201),
            in202 => exc_spikes_sampled(202),
            in203 => exc_spikes_sampled(203),
            in204 => exc_spikes_sampled(204),
            in205 => exc_spikes_sampled(205),
            in206 => exc_spikes_sampled(206),
            in207 => exc_spikes_sampled(207),
            in208 => exc_spikes_sampled(208),
            in209 => exc_spikes_sampled(209),
            in210 => exc_spikes_sampled(210),
            in211 => exc_spikes_sampled(211),
            in212 => exc_spikes_sampled(212),
            in213 => exc_spikes_sampled(213),
            in214 => exc_spikes_sampled(214),
            in215 => exc_spikes_sampled(215),
            in216 => exc_spikes_sampled(216),
            in217 => exc_spikes_sampled(217),
            in218 => exc_spikes_sampled(218),
            in219 => exc_spikes_sampled(219),
            in220 => exc_spikes_sampled(220),
            in221 => exc_spikes_sampled(221),
            in222 => exc_spikes_sampled(222),
            in223 => exc_spikes_sampled(223),
            in224 => exc_spikes_sampled(224),
            in225 => exc_spikes_sampled(225),
            in226 => exc_spikes_sampled(226),
            in227 => exc_spikes_sampled(227),
            in228 => exc_spikes_sampled(228),
            in229 => exc_spikes_sampled(229),
            in230 => exc_spikes_sampled(230),
            in231 => exc_spikes_sampled(231),
            in232 => exc_spikes_sampled(232),
            in233 => exc_spikes_sampled(233),
            in234 => exc_spikes_sampled(234),
            in235 => exc_spikes_sampled(235),
            in236 => exc_spikes_sampled(236),
            in237 => exc_spikes_sampled(237),
            in238 => exc_spikes_sampled(238),
            in239 => exc_spikes_sampled(239),
            in240 => exc_spikes_sampled(240),
            in241 => exc_spikes_sampled(241),
            in242 => exc_spikes_sampled(242),
            in243 => exc_spikes_sampled(243),
            in244 => exc_spikes_sampled(244),
            in245 => exc_spikes_sampled(245),
            in246 => exc_spikes_sampled(246),
            in247 => exc_spikes_sampled(247),
            in248 => exc_spikes_sampled(248),
            in249 => exc_spikes_sampled(249),
            in250 => exc_spikes_sampled(250),
            in251 => exc_spikes_sampled(251),
            in252 => exc_spikes_sampled(252),
            in253 => exc_spikes_sampled(253),
            in254 => exc_spikes_sampled(254),
            in255 => exc_spikes_sampled(255),
            mux_out => exc_spike
        );

    inh_mux : mux_16to1
        port map(
            mux_sel => inh_cnt_sig,
            in0 => inh_spikes_sampled(0),
            in1 => inh_spikes_sampled(1),
            in2 => inh_spikes_sampled(2),
            in3 => inh_spikes_sampled(3),
            in4 => inh_spikes_sampled(4),
            in5 => inh_spikes_sampled(5),
            in6 => inh_spikes_sampled(6),
            in7 => inh_spikes_sampled(7),
            in8 => inh_spikes_sampled(8),
            in9 => inh_spikes_sampled(9),
            in10 => '0',
            in11 => '0',
            in12 => '0',
            in13 => '0',
            in14 => '0',
            in15 => '0',
            mux_out => inh_spike
        );

    exc_counter : cnt
        generic map(
            N => exc_cnt_bitwidth,
            rst_value => 255
        )
        port map(
            clk => clk,
            cnt_en => exc_cnt_en,
            cnt_rst_n => exc_cnt_rst_n,
            cnt_out => exc_cnt_sig
        );

    inh_counter : cnt
        generic map(
            N => inh_cnt_bitwidth,
            rst_value => 15
        )
        port map(
            clk => clk,
            cnt_en => inh_cnt_en,
            cnt_rst_n => inh_cnt_rst_n,
            cnt_out => inh_cnt_sig
        );

    exc_cmp : cmp_eq
        generic map(
            N => exc_cnt_bitwidth
        )
        port map(
            in0 => exc_cnt_sig,
            in1 => std_logic_vector(to_unsigned(n_exc_inputs-2, exc_cnt_bitwidth)),
            cmp_out => exc_stop
        );

    inh_cmp : cmp_eq
        generic map(
            N => inh_cnt_bitwidth
        )
        port map(
            in0 => inh_cnt_sig,
            in1 => std_logic_vector(to_unsigned(n_inh_inputs-2, inh_cnt_bitwidth)),
            cmp_out => inh_stop
        );


end architecture behavior;

