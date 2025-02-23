local StrToNumber = tonumber;
local Byte = string.byte;
local Char = string.char;
local Sub = string.sub;
local Subg = string.gsub;
local Rep = string.rep;
local Concat = table.concat;
local Insert = table.insert;
local LDExp = math.ldexp;
local GetFEnv = getfenv or function()
	return _ENV;
end;
local Setmetatable = setmetatable;
local PCall = pcall;
local Select = select;
local Unpack = unpack or table.unpack;
local ToNumber = tonumber;
local function VMCall(ByteString, vmenv, ...)
	local DIP = 1;
	local repeatNext;
	ByteString = Subg(Sub(ByteString, 5), "..", function(byte)
		if (Byte(byte, 2) == 81) then
			repeatNext = StrToNumber(Sub(byte, 1, 1));
			return "";
		else
			local a = Char(StrToNumber(byte, 16));
			if repeatNext then
				local b = Rep(a, repeatNext);
				repeatNext = nil;
				return b;
			else
				return a;
			end
		end
	end);
	local function gBit(Bit, Start, End)
		if End then
			local Res = (Bit / (2 ^ (Start - 1))) % (2 ^ (((End - 1) - (Start - 1)) + 1));
			return Res - (Res % 1);
		else
			local Plc = 2 ^ (Start - 1);
			return (((Bit % (Plc + Plc)) >= Plc) and 1) or 0;
		end
	end
	local function gBits8()
		local a = Byte(ByteString, DIP, DIP);
		DIP = DIP + 1;
		return a;
	end
	local function gBits16()
		local a, b = Byte(ByteString, DIP, DIP + 2);
		DIP = DIP + 2;
		return (b * 256) + a;
	end
	local function gBits32()
		local a, b, c, d = Byte(ByteString, DIP, DIP + 3);
		DIP = DIP + 4;
		return (d * 16777216) + (c * 65536) + (b * 256) + a;
	end
	local function gFloat()
		local Left = gBits32();
		local Right = gBits32();
		local IsNormal = 1;
		local Mantissa = (gBit(Right, 1, 20) * (2 ^ 32)) + Left;
		local Exponent = gBit(Right, 21, 31);
		local Sign = ((gBit(Right, 32) == 1) and -1) or 1;
		if (Exponent == 0) then
			if (Mantissa == 0) then
				return Sign * 0;
			else
				Exponent = 1;
				IsNormal = 0;
			end
		elseif (Exponent == 2047) then
			return ((Mantissa == 0) and (Sign * (1 / 0))) or (Sign * NaN);
		end
		return LDExp(Sign, Exponent - 1023) * (IsNormal + (Mantissa / (2 ^ 52)));
	end
	local function gString(Len)
		local Str;
		if not Len then
			Len = gBits32();
			if (Len == 0) then
				return "";
			end
		end
		Str = Sub(ByteString, DIP, (DIP + Len) - 1);
		DIP = DIP + Len;
		local FStr = {};
		for Idx = 1, #Str do
			FStr[Idx] = Char(Byte(Sub(Str, Idx, Idx)));
		end
		return Concat(FStr);
	end
	local gInt = gBits32;
	local function _R(...)
		return {...}, Select("#", ...);
	end
	local function Deserialize()
		local Instrs = {};
		local Functions = {};
		local Lines = {};
		local Chunk = {Instrs,Functions,nil,Lines};
		local ConstCount = gBits32();
		local Consts = {};
		for Idx = 1, ConstCount do
			local Type = gBits8();
			local Cons;
			if (Type == 1) then
				Cons = gBits8() ~= 0;
			elseif (Type == 2) then
				Cons = gFloat();
			elseif (Type == 3) then
				Cons = gString();
			end
			Consts[Idx] = Cons;
		end
		Chunk[3] = gBits8();
		for Idx = 1, gBits32() do
			local Descriptor = gBits8();
			if (gBit(Descriptor, 1, 1) == 0) then
				local Type = gBit(Descriptor, 2, 3);
				local Mask = gBit(Descriptor, 4, 6);
				local Inst = {gBits16(),gBits16(),nil,nil};
				if (Type == 0) then
					Inst[3] = gBits16();
					Inst[4] = gBits16();
				elseif (Type == 1) then
					Inst[3] = gBits32();
				elseif (Type == 2) then
					Inst[3] = gBits32() - (2 ^ 16);
				elseif (Type == 3) then
					Inst[3] = gBits32() - (2 ^ 16);
					Inst[4] = gBits16();
				end
				if (gBit(Mask, 1, 1) == 1) then
					Inst[2] = Consts[Inst[2]];
				end
				if (gBit(Mask, 2, 2) == 1) then
					Inst[3] = Consts[Inst[3]];
				end
				if (gBit(Mask, 3, 3) == 1) then
					Inst[4] = Consts[Inst[4]];
				end
				Instrs[Idx] = Inst;
			end
		end
		for Idx = 1, gBits32() do
			Functions[Idx - 1] = Deserialize();
		end
		return Chunk;
	end
	local function Wrap(Chunk, Upvalues, Env)
		local Instr = Chunk[1];
		local Proto = Chunk[2];
		local Params = Chunk[3];
		return function(...)
			local Instr = Instr;
			local Proto = Proto;
			local Params = Params;
			local _R = _R;
			local VIP = 1;
			local Top = -1;
			local Vararg = {};
			local Args = {...};
			local PCount = Select("#", ...) - 1;
			local Lupvals = {};
			local Stk = {};
			for Idx = 0, PCount do
				if (Idx >= Params) then
					Vararg[Idx - Params] = Args[Idx + 1];
				else
					Stk[Idx] = Args[Idx + 1];
				end
			end
			local Varargsz = (PCount - Params) + 1;
			local Inst;
			local Enum;
			while true do
				Inst = Instr[VIP];
				Enum = Inst[1];
				if (Enum <= 23) then
					if (Enum <= 11) then
						if (Enum <= 5) then
							if (Enum <= 2) then
								if (Enum <= 0) then
									Stk[Inst[2]] = Stk[Inst[3]];
								elseif (Enum > 1) then
									local A = Inst[2];
									local Step = Stk[A + 2];
									local Index = Stk[A] + Step;
									Stk[A] = Index;
									if (Step > 0) then
										if (Index <= Stk[A + 1]) then
											VIP = Inst[3];
											Stk[A + 3] = Index;
										end
									elseif (Index >= Stk[A + 1]) then
										VIP = Inst[3];
										Stk[A + 3] = Index;
									end
								else
									Stk[Inst[2]] = Wrap(Proto[Inst[3]], nil, Env);
								end
							elseif (Enum <= 3) then
								local A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
							elseif (Enum == 4) then
								if Stk[Inst[2]] then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							else
								local A = Inst[2];
								local Results, Limit = _R(Stk[A](Stk[A + 1]));
								Top = (Limit + A) - 1;
								local Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
							end
						elseif (Enum <= 8) then
							if (Enum <= 6) then
								Stk[Inst[2]] = {};
							elseif (Enum > 7) then
								local A = Inst[2];
								local Index = Stk[A];
								local Step = Stk[A + 2];
								if (Step > 0) then
									if (Index > Stk[A + 1]) then
										VIP = Inst[3];
									else
										Stk[A + 3] = Index;
									end
								elseif (Index < Stk[A + 1]) then
									VIP = Inst[3];
								else
									Stk[A + 3] = Index;
								end
							else
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
							end
						elseif (Enum <= 9) then
							Stk[Inst[2]][Inst[3]] = Inst[4];
						elseif (Enum > 10) then
							Stk[Inst[2]] = {};
						else
							local A = Inst[2];
							Stk[A](Stk[A + 1]);
						end
					elseif (Enum <= 17) then
						if (Enum <= 14) then
							if (Enum <= 12) then
								local A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
							elseif (Enum == 13) then
								Stk[Inst[2]] = Stk[Inst[3]];
							else
								local A = Inst[2];
								local Results, Limit = _R(Stk[A](Stk[A + 1]));
								Top = (Limit + A) - 1;
								local Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
							end
						elseif (Enum <= 15) then
							VIP = Inst[3];
						elseif (Enum > 16) then
							Stk[Inst[2]] = Inst[3] ~= 0;
						else
							Stk[Inst[2]] = Env[Inst[3]];
						end
					elseif (Enum <= 20) then
						if (Enum <= 18) then
							local A = Inst[2];
							Stk[A] = Stk[A](Stk[A + 1]);
						elseif (Enum > 19) then
							do
								return;
							end
						else
							Stk[Inst[2]] = Env[Inst[3]];
						end
					elseif (Enum <= 21) then
						Env[Inst[3]] = Stk[Inst[2]];
					elseif (Enum > 22) then
						Stk[Inst[2]] = Inst[3];
					else
						local A = Inst[2];
						Stk[A](Unpack(Stk, A + 1, Top));
					end
				elseif (Enum <= 35) then
					if (Enum <= 29) then
						if (Enum <= 26) then
							if (Enum <= 24) then
								local A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Top));
							elseif (Enum > 25) then
								local A = Inst[2];
								local B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
							else
								VIP = Inst[3];
							end
						elseif (Enum <= 27) then
							if Stk[Inst[2]] then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						elseif (Enum > 28) then
							local A = Inst[2];
							local Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
							Top = (Limit + A) - 1;
							local Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
						else
							Stk[Inst[2]] = Inst[3];
						end
					elseif (Enum <= 32) then
						if (Enum <= 30) then
							Stk[Inst[2]] = Inst[3] ~= 0;
						elseif (Enum == 31) then
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						else
							Stk[Inst[2]] = not Stk[Inst[3]];
						end
					elseif (Enum <= 33) then
						local A = Inst[2];
						local Step = Stk[A + 2];
						local Index = Stk[A] + Step;
						Stk[A] = Index;
						if (Step > 0) then
							if (Index <= Stk[A + 1]) then
								VIP = Inst[3];
								Stk[A + 3] = Index;
							end
						elseif (Index >= Stk[A + 1]) then
							VIP = Inst[3];
							Stk[A + 3] = Index;
						end
					elseif (Enum > 34) then
						local A = Inst[2];
						local B = Stk[Inst[3]];
						Stk[A + 1] = B;
						Stk[A] = B[Inst[4]];
					else
						do
							return;
						end
					end
				elseif (Enum <= 41) then
					if (Enum <= 38) then
						if (Enum <= 36) then
							local A = Inst[2];
							Stk[A](Stk[A + 1]);
						elseif (Enum == 37) then
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						else
							Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
						end
					elseif (Enum <= 39) then
						local A = Inst[2];
						Stk[A](Unpack(Stk, A + 1, Inst[3]));
					elseif (Enum == 40) then
						local A = Inst[2];
						local Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
						Top = (Limit + A) - 1;
						local Edx = 0;
						for Idx = A, Top do
							Edx = Edx + 1;
							Stk[Idx] = Results[Edx];
						end
					else
						Stk[Inst[2]][Inst[3]] = Inst[4];
					end
				elseif (Enum <= 44) then
					if (Enum <= 42) then
						local A = Inst[2];
						Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
					elseif (Enum == 43) then
						local A = Inst[2];
						local Index = Stk[A];
						local Step = Stk[A + 2];
						if (Step > 0) then
							if (Index > Stk[A + 1]) then
								VIP = Inst[3];
							else
								Stk[A + 3] = Index;
							end
						elseif (Index < Stk[A + 1]) then
							VIP = Inst[3];
						else
							Stk[A + 3] = Index;
						end
					else
						Env[Inst[3]] = Stk[Inst[2]];
					end
				elseif (Enum <= 45) then
					Stk[Inst[2]] = Wrap(Proto[Inst[3]], nil, Env);
				elseif (Enum > 46) then
					Stk[Inst[2]] = not Stk[Inst[3]];
				else
					local A = Inst[2];
					Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
				end
				VIP = VIP + 1;
			end
		end;
	end
	return Wrap(Deserialize(), {}, vmenv)(...);
end
return VMCall("LOL!323Q00026Q00F03F2Q0103093Q00776F726B7370616365030C3Q00526566726573684C6F636B73030A3Q004669726553657276657203063Q00756E7061636B03063Q006E6F636C697003043Q0067616D65030A3Q0047657453657276696365030A3Q0052756E5365727669636503073Q005374652Q70656403073Q00636F2Q6E65637403073Q00506C6179657273030B3Q004C6F63616C506C6179657203093Q0043686172616374657203083Q0048756D616E6F6964030B3Q004368616E67655374617465026Q00264003043Q0077616974026Q00084003063Q00434672616D652Q033Q006E65770293FFC9DFBDE444C002EC4328009049534002271422E0ACF1C040026Q002440030C3Q0054772Q656E5365727669636503063Q0043726561746503103Q0048756D616E6F6964522Q6F745061727403093Q0054772Q656E496E666F03043Q00506C617903093Q00436F6D706C6574656403043Q005761697403063Q004D6F7665546F03073Q00566563746F723302142928A0E49E4FC00247E6913F985576C002062AE3DF8B39C140026Q00E03F02A30ADA3FAAF04BC00221E7FD7FDC9176C002545227A01188C240028Q00030E3Q00436861726163746572412Q64656403073Q00436F2Q6E65637403043Q006D61746803043Q0068756765026Q00694003043Q004865616403073Q0044657374726F7900884Q00065Q00010030093Q00010002001210000100033Q002025000100010004002023000100010005001210000300064Q000D00046Q0005000300044Q001600013Q00012Q001E00015Q001215000100073Q001210000100083Q00202300010001000900121C0003000A4Q002E00010003000200202500010001000B00202300010001000C00020100036Q0027000100030001001210000100074Q0020000100013Q001215000100073Q001210000100083Q00202500010001000D00202500010001000E00202500010001000F00202500010001001000202300010001001100121C000300124Q0027000100030001001210000100083Q00202300010001000900121C0003000D4Q002E00010003000200202500010001000E00202500010001000F001210000200133Q00121C000300144Q000A000200020001001210000200153Q00202500020002001600121C000300173Q00121C000400183Q00121C000500194Q002E00020005000200121C0003001A3Q001210000400083Q00202300040004000900121C0006001B4Q002E00040006000200202300040004001C001210000600083Q00202500060006000D00202500060006000E00202500060006000F00202500060006001D0012100007001E3Q0020250007000700162Q000D000800034Q00030007000200022Q000600083Q00010010260008001500022Q002E00040008000200202300050004001F2Q000A0005000200010020250005000400200020230005000500212Q000A000500020001001210000500083Q00202500050005000D00202500050005000E00202500050005000F002023000500050022001210000700233Q00202500070007001600121C000800243Q00121C000900253Q00121C000A00264Q001D0007000A4Q001600053Q0001001210000500133Q00121C000600274Q000A000500020001001210000500153Q00202500050005001600121C000600283Q00121C000700293Q00121C0008002A4Q002E00050008000200121C0006002B3Q001210000700083Q00202300070007000900121C0009001B4Q002E00070009000200202300070007001C001210000900083Q00202500090009000D00202500090009000E00202500090009000F00202500090009001D001210000A001E3Q002025000A000A00162Q000D000B00064Q0003000A000200022Q0006000B3Q0001001026000B001500052Q002E0007000B000200202300080007001F2Q000A0008000200010020250008000700200020230008000800212Q000A000800020001001210000800083Q00202500080008000D00202500080008000E00202500080008002C00202300080008002D000201000A00014Q00270008000A000100121C000800013Q0012100009002E3Q00202500090009002F00121C000A00013Q000408000800870001001210000C00133Q00121C000D00304Q000A000C00020001001210000C00083Q002025000C000C000D002025000C000C000E002025000C000C000F002025000C000C0031002023000C000C00322Q000A000C000200010004020008007C00012Q00143Q00013Q00023Q00083Q0003063Q006E6F636C697003043Q0067616D6503073Q00506C6179657273030B3Q004C6F63616C506C6179657203093Q0043686172616374657203083Q0048756D616E6F6964030B3Q004368616E67655374617465026Q002640000C3Q0012103Q00013Q00061B3Q000B00013Q0004193Q000B00010012103Q00023Q0020255Q00030020255Q00040020255Q00050020255Q00060020235Q000700121C000200084Q00273Q000200012Q00143Q00017Q00223Q0003043Q0077616974026Q00084003043Q0067616D6503073Q00506C6179657273030B3Q004C6F63616C506C6179657203093Q0043686172616374657203063Q004D6F7665546F03073Q00566563746F72332Q033Q006E6577025DF525C0554151C0020D51853FC3135B4002CD94D6DF72238440026Q00F03F03063Q00434672616D650293FFC9DFBDE444C002EC4328009049534002271422E0ACF1C040026Q002440030A3Q0047657453657276696365030C3Q0054772Q656E5365727669636503063Q0043726561746503103Q0048756D616E6F6964522Q6F745061727403093Q0054772Q656E496E666F03043Q00506C617903093Q00436F6D706C6574656403043Q005761697402142928A0E49E4FC00247E6913F985576C002062AE3DF8B39C140026Q00E03F02A30ADA3FAAF04BC00221E7FD7FDC9176C002545227A01188C240029Q005C3Q0012103Q00013Q00121C000100024Q000A3Q000200010012103Q00033Q0020255Q00040020255Q00050020255Q00060020235Q0007001210000200083Q00202500020002000900121C0003000A3Q00121C0004000B3Q00121C0005000C4Q001D000200054Q00165Q00010012103Q00013Q00121C0001000D4Q000A3Q000200010012103Q000E3Q0020255Q000900121C0001000F3Q00121C000200103Q00121C000300114Q002E3Q0003000200121C000100123Q001210000200033Q00202300020002001300121C000400144Q002E000200040002002023000200020015001210000400033Q002025000400040004002025000400040005002025000400040006002025000400040016001210000500173Q0020250005000500092Q000D000600014Q00030005000200022Q000600063Q00010010260006000E4Q002E0002000600020020230003000200182Q000A00030002000100202500030002001900202300030003001A2Q000A000300020001001210000300033Q002025000300030004002025000300030005002025000300030006002023000300030007001210000500083Q00202500050005000900121C0006001B3Q00121C0007001C3Q00121C0008001D4Q001D000500084Q001600033Q0001001210000300013Q00121C0004001E4Q000A0003000200010012100003000E3Q00202500030003000900121C0004001F3Q00121C000500203Q00121C000600214Q002E00030006000200121C000400223Q001210000500033Q00202300050005001300121C000700144Q002E000500070002002023000500050015001210000700033Q002025000700070004002025000700070005002025000700070006002025000700070016001210000800173Q0020250008000800092Q000D000900044Q00030008000200022Q000600093Q00010010260009000E00032Q002E0005000900020020230006000500182Q000A00060002000100202500060005001900202300060006001A2Q000A0006000200012Q00143Q00017Q00", GetFEnv(), ...);
