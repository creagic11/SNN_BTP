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


entity mux_256to1 is
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
end entity mux_256to1;

architecture behavior of mux_256to1 is


begin

    selection : process(mux_sel, in0, in1, in2, in3, in4, in5, in6, in7, in8, in9, in10, in11, in12, in13, in14, in15, in16, in17, in18, in19, in20, in21, in22, in23, in24, in25, in26, in27, in28, in29, in30, in31, in32, in33, in34, in35, in36, in37, in38, in39, in40, in41, in42, in43, in44, in45, in46, in47, in48, in49, in50, in51, in52, in53, in54, in55, in56, in57, in58, in59, in60, in61, in62, in63, in64, in65, in66, in67, in68, in69, in70, in71, in72, in73, in74, in75, in76, in77, in78, in79, in80, in81, in82, in83, in84, in85, in86, in87, in88, in89, in90, in91, in92, in93, in94, in95, in96, in97, in98, in99, in100, in101, in102, in103, in104, in105, in106, in107, in108, in109, in110, in111, in112, in113, in114, in115, in116, in117, in118, in119, in120, in121, in122, in123, in124, in125, in126, in127, in128, in129, in130, in131, in132, in133, in134, in135, in136, in137, in138, in139, in140, in141, in142, in143, in144, in145, in146, in147, in148, in149, in150, in151, in152, in153, in154, in155, in156, in157, in158, in159, in160, in161, in162, in163, in164, in165, in166, in167, in168, in169, in170, in171, in172, in173, in174, in175, in176, in177, in178, in179, in180, in181, in182, in183, in184, in185, in186, in187, in188, in189, in190, in191, in192, in193, in194, in195, in196, in197, in198, in199, in200, in201, in202, in203, in204, in205, in206, in207, in208, in209, in210, in211, in212, in213, in214, in215, in216, in217, in218, in219, in220, in221, in222, in223, in224, in225, in226, in227, in228, in229, in230, in231, in232, in233, in234, in235, in236, in237, in238, in239, in240, in241, in242, in243, in244, in245, in246, in247, in248, in249, in250, in251, in252, in253, in254, in255 )
    begin

        case mux_sel is

            when "00000000" =>
                mux_out <= in0;


            when "00000001" =>
                mux_out <= in1;


            when "00000010" =>
                mux_out <= in2;


            when "00000011" =>
                mux_out <= in3;


            when "00000100" =>
                mux_out <= in4;


            when "00000101" =>
                mux_out <= in5;


            when "00000110" =>
                mux_out <= in6;


            when "00000111" =>
                mux_out <= in7;


            when "00001000" =>
                mux_out <= in8;


            when "00001001" =>
                mux_out <= in9;


            when "00001010" =>
                mux_out <= in10;


            when "00001011" =>
                mux_out <= in11;


            when "00001100" =>
                mux_out <= in12;


            when "00001101" =>
                mux_out <= in13;


            when "00001110" =>
                mux_out <= in14;


            when "00001111" =>
                mux_out <= in15;


            when "00010000" =>
                mux_out <= in16;


            when "00010001" =>
                mux_out <= in17;


            when "00010010" =>
                mux_out <= in18;


            when "00010011" =>
                mux_out <= in19;


            when "00010100" =>
                mux_out <= in20;


            when "00010101" =>
                mux_out <= in21;


            when "00010110" =>
                mux_out <= in22;


            when "00010111" =>
                mux_out <= in23;


            when "00011000" =>
                mux_out <= in24;


            when "00011001" =>
                mux_out <= in25;


            when "00011010" =>
                mux_out <= in26;


            when "00011011" =>
                mux_out <= in27;


            when "00011100" =>
                mux_out <= in28;


            when "00011101" =>
                mux_out <= in29;


            when "00011110" =>
                mux_out <= in30;


            when "00011111" =>
                mux_out <= in31;


            when "00100000" =>
                mux_out <= in32;


            when "00100001" =>
                mux_out <= in33;


            when "00100010" =>
                mux_out <= in34;


            when "00100011" =>
                mux_out <= in35;


            when "00100100" =>
                mux_out <= in36;


            when "00100101" =>
                mux_out <= in37;


            when "00100110" =>
                mux_out <= in38;


            when "00100111" =>
                mux_out <= in39;


            when "00101000" =>
                mux_out <= in40;


            when "00101001" =>
                mux_out <= in41;


            when "00101010" =>
                mux_out <= in42;


            when "00101011" =>
                mux_out <= in43;


            when "00101100" =>
                mux_out <= in44;


            when "00101101" =>
                mux_out <= in45;


            when "00101110" =>
                mux_out <= in46;


            when "00101111" =>
                mux_out <= in47;


            when "00110000" =>
                mux_out <= in48;


            when "00110001" =>
                mux_out <= in49;


            when "00110010" =>
                mux_out <= in50;


            when "00110011" =>
                mux_out <= in51;


            when "00110100" =>
                mux_out <= in52;


            when "00110101" =>
                mux_out <= in53;


            when "00110110" =>
                mux_out <= in54;


            when "00110111" =>
                mux_out <= in55;


            when "00111000" =>
                mux_out <= in56;


            when "00111001" =>
                mux_out <= in57;


            when "00111010" =>
                mux_out <= in58;


            when "00111011" =>
                mux_out <= in59;


            when "00111100" =>
                mux_out <= in60;


            when "00111101" =>
                mux_out <= in61;


            when "00111110" =>
                mux_out <= in62;


            when "00111111" =>
                mux_out <= in63;


            when "01000000" =>
                mux_out <= in64;


            when "01000001" =>
                mux_out <= in65;


            when "01000010" =>
                mux_out <= in66;


            when "01000011" =>
                mux_out <= in67;


            when "01000100" =>
                mux_out <= in68;


            when "01000101" =>
                mux_out <= in69;


            when "01000110" =>
                mux_out <= in70;


            when "01000111" =>
                mux_out <= in71;


            when "01001000" =>
                mux_out <= in72;


            when "01001001" =>
                mux_out <= in73;


            when "01001010" =>
                mux_out <= in74;


            when "01001011" =>
                mux_out <= in75;


            when "01001100" =>
                mux_out <= in76;


            when "01001101" =>
                mux_out <= in77;


            when "01001110" =>
                mux_out <= in78;


            when "01001111" =>
                mux_out <= in79;


            when "01010000" =>
                mux_out <= in80;


            when "01010001" =>
                mux_out <= in81;


            when "01010010" =>
                mux_out <= in82;


            when "01010011" =>
                mux_out <= in83;


            when "01010100" =>
                mux_out <= in84;


            when "01010101" =>
                mux_out <= in85;


            when "01010110" =>
                mux_out <= in86;


            when "01010111" =>
                mux_out <= in87;


            when "01011000" =>
                mux_out <= in88;


            when "01011001" =>
                mux_out <= in89;


            when "01011010" =>
                mux_out <= in90;


            when "01011011" =>
                mux_out <= in91;


            when "01011100" =>
                mux_out <= in92;


            when "01011101" =>
                mux_out <= in93;


            when "01011110" =>
                mux_out <= in94;


            when "01011111" =>
                mux_out <= in95;


            when "01100000" =>
                mux_out <= in96;


            when "01100001" =>
                mux_out <= in97;


            when "01100010" =>
                mux_out <= in98;


            when "01100011" =>
                mux_out <= in99;


            when "01100100" =>
                mux_out <= in100;


            when "01100101" =>
                mux_out <= in101;


            when "01100110" =>
                mux_out <= in102;


            when "01100111" =>
                mux_out <= in103;


            when "01101000" =>
                mux_out <= in104;


            when "01101001" =>
                mux_out <= in105;


            when "01101010" =>
                mux_out <= in106;


            when "01101011" =>
                mux_out <= in107;


            when "01101100" =>
                mux_out <= in108;


            when "01101101" =>
                mux_out <= in109;


            when "01101110" =>
                mux_out <= in110;


            when "01101111" =>
                mux_out <= in111;


            when "01110000" =>
                mux_out <= in112;


            when "01110001" =>
                mux_out <= in113;


            when "01110010" =>
                mux_out <= in114;


            when "01110011" =>
                mux_out <= in115;


            when "01110100" =>
                mux_out <= in116;


            when "01110101" =>
                mux_out <= in117;


            when "01110110" =>
                mux_out <= in118;


            when "01110111" =>
                mux_out <= in119;


            when "01111000" =>
                mux_out <= in120;


            when "01111001" =>
                mux_out <= in121;


            when "01111010" =>
                mux_out <= in122;


            when "01111011" =>
                mux_out <= in123;


            when "01111100" =>
                mux_out <= in124;


            when "01111101" =>
                mux_out <= in125;


            when "01111110" =>
                mux_out <= in126;


            when "01111111" =>
                mux_out <= in127;


            when "10000000" =>
                mux_out <= in128;


            when "10000001" =>
                mux_out <= in129;


            when "10000010" =>
                mux_out <= in130;


            when "10000011" =>
                mux_out <= in131;


            when "10000100" =>
                mux_out <= in132;


            when "10000101" =>
                mux_out <= in133;


            when "10000110" =>
                mux_out <= in134;


            when "10000111" =>
                mux_out <= in135;


            when "10001000" =>
                mux_out <= in136;


            when "10001001" =>
                mux_out <= in137;


            when "10001010" =>
                mux_out <= in138;


            when "10001011" =>
                mux_out <= in139;


            when "10001100" =>
                mux_out <= in140;


            when "10001101" =>
                mux_out <= in141;


            when "10001110" =>
                mux_out <= in142;


            when "10001111" =>
                mux_out <= in143;


            when "10010000" =>
                mux_out <= in144;


            when "10010001" =>
                mux_out <= in145;


            when "10010010" =>
                mux_out <= in146;


            when "10010011" =>
                mux_out <= in147;


            when "10010100" =>
                mux_out <= in148;


            when "10010101" =>
                mux_out <= in149;


            when "10010110" =>
                mux_out <= in150;


            when "10010111" =>
                mux_out <= in151;


            when "10011000" =>
                mux_out <= in152;


            when "10011001" =>
                mux_out <= in153;


            when "10011010" =>
                mux_out <= in154;


            when "10011011" =>
                mux_out <= in155;


            when "10011100" =>
                mux_out <= in156;


            when "10011101" =>
                mux_out <= in157;


            when "10011110" =>
                mux_out <= in158;


            when "10011111" =>
                mux_out <= in159;


            when "10100000" =>
                mux_out <= in160;


            when "10100001" =>
                mux_out <= in161;


            when "10100010" =>
                mux_out <= in162;


            when "10100011" =>
                mux_out <= in163;


            when "10100100" =>
                mux_out <= in164;


            when "10100101" =>
                mux_out <= in165;


            when "10100110" =>
                mux_out <= in166;


            when "10100111" =>
                mux_out <= in167;


            when "10101000" =>
                mux_out <= in168;


            when "10101001" =>
                mux_out <= in169;


            when "10101010" =>
                mux_out <= in170;


            when "10101011" =>
                mux_out <= in171;


            when "10101100" =>
                mux_out <= in172;


            when "10101101" =>
                mux_out <= in173;


            when "10101110" =>
                mux_out <= in174;


            when "10101111" =>
                mux_out <= in175;


            when "10110000" =>
                mux_out <= in176;


            when "10110001" =>
                mux_out <= in177;


            when "10110010" =>
                mux_out <= in178;


            when "10110011" =>
                mux_out <= in179;


            when "10110100" =>
                mux_out <= in180;


            when "10110101" =>
                mux_out <= in181;


            when "10110110" =>
                mux_out <= in182;


            when "10110111" =>
                mux_out <= in183;


            when "10111000" =>
                mux_out <= in184;


            when "10111001" =>
                mux_out <= in185;


            when "10111010" =>
                mux_out <= in186;


            when "10111011" =>
                mux_out <= in187;


            when "10111100" =>
                mux_out <= in188;


            when "10111101" =>
                mux_out <= in189;


            when "10111110" =>
                mux_out <= in190;


            when "10111111" =>
                mux_out <= in191;


            when "11000000" =>
                mux_out <= in192;


            when "11000001" =>
                mux_out <= in193;


            when "11000010" =>
                mux_out <= in194;


            when "11000011" =>
                mux_out <= in195;


            when "11000100" =>
                mux_out <= in196;


            when "11000101" =>
                mux_out <= in197;


            when "11000110" =>
                mux_out <= in198;


            when "11000111" =>
                mux_out <= in199;


            when "11001000" =>
                mux_out <= in200;


            when "11001001" =>
                mux_out <= in201;


            when "11001010" =>
                mux_out <= in202;


            when "11001011" =>
                mux_out <= in203;


            when "11001100" =>
                mux_out <= in204;


            when "11001101" =>
                mux_out <= in205;


            when "11001110" =>
                mux_out <= in206;


            when "11001111" =>
                mux_out <= in207;


            when "11010000" =>
                mux_out <= in208;


            when "11010001" =>
                mux_out <= in209;


            when "11010010" =>
                mux_out <= in210;


            when "11010011" =>
                mux_out <= in211;


            when "11010100" =>
                mux_out <= in212;


            when "11010101" =>
                mux_out <= in213;


            when "11010110" =>
                mux_out <= in214;


            when "11010111" =>
                mux_out <= in215;


            when "11011000" =>
                mux_out <= in216;


            when "11011001" =>
                mux_out <= in217;


            when "11011010" =>
                mux_out <= in218;


            when "11011011" =>
                mux_out <= in219;


            when "11011100" =>
                mux_out <= in220;


            when "11011101" =>
                mux_out <= in221;


            when "11011110" =>
                mux_out <= in222;


            when "11011111" =>
                mux_out <= in223;


            when "11100000" =>
                mux_out <= in224;


            when "11100001" =>
                mux_out <= in225;


            when "11100010" =>
                mux_out <= in226;


            when "11100011" =>
                mux_out <= in227;


            when "11100100" =>
                mux_out <= in228;


            when "11100101" =>
                mux_out <= in229;


            when "11100110" =>
                mux_out <= in230;


            when "11100111" =>
                mux_out <= in231;


            when "11101000" =>
                mux_out <= in232;


            when "11101001" =>
                mux_out <= in233;


            when "11101010" =>
                mux_out <= in234;


            when "11101011" =>
                mux_out <= in235;


            when "11101100" =>
                mux_out <= in236;


            when "11101101" =>
                mux_out <= in237;


            when "11101110" =>
                mux_out <= in238;


            when "11101111" =>
                mux_out <= in239;


            when "11110000" =>
                mux_out <= in240;


            when "11110001" =>
                mux_out <= in241;


            when "11110010" =>
                mux_out <= in242;


            when "11110011" =>
                mux_out <= in243;


            when "11110100" =>
                mux_out <= in244;


            when "11110101" =>
                mux_out <= in245;


            when "11110110" =>
                mux_out <= in246;


            when "11110111" =>
                mux_out <= in247;


            when "11111000" =>
                mux_out <= in248;


            when "11111001" =>
                mux_out <= in249;


            when "11111010" =>
                mux_out <= in250;


            when "11111011" =>
                mux_out <= in251;


            when "11111100" =>
                mux_out <= in252;


            when "11111101" =>
                mux_out <= in253;


            when "11111110" =>
                mux_out <= in254;


            when others =>
                mux_out <= in255;


        end case;

    end process selection;


end architecture behavior;

