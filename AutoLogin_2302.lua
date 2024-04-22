-- ��������� ��������� QUIK 

local WM_COMMAND = 0x0111; -- ��������� �� windows.h

--QUIK_WNDN = "Information and trading system QUIK (version 7.12.1.10)" ;
timeout = 60000;  -- ������� ����� ��������� ������ ���� ������
IS_RUN = true;

 T_DP = { -- waiting periods table start-stop 
	["00:00:01"]="08:05:10", -- 
	["13:59:55"]="14:01:00", -- morning clearing time - � �����
	["18:49:59"]="19:01:00", -- evening clearing time  - � �����
	["23:50:00"]="23:59:59", -- 
};
NWCalendar={ -- non-working days calendar
	["02/01/2023"]=true,
	["23/02/2023"]=true,
	["08/03/2023"]=true,
	["01/05/2023"]=true,
	["09/05/2023"]=true,
	["12/06/2023"]=true,
};

function OnInit()
-- w32 library should by installed
	local luadir="x32"
	if(_VERSION=="Lua 5.1")then luadir="x64-Lua51" end
	if(_VERSION=="Lua 5.3")then luadir="x64-Lua53" end
	if(_VERSION=="Lua 5.4")then luadir="x64-Lua54" end
	package.cpath=package.cpath..";"..getWorkingFolder().."\\w32\\"..luadir.."\\?.dll";
	w32 = require("w32")

-- reading of account details	
	ACC_FILE = "\\".."_account.txt"; -- ���� � ������� �����
	ACC_DATA = io.open(getScriptPath()..ACC_FILE,"r");
	if ACC_DATA == nil then 
		message(R_NAME.." account details file not found")
	end;
	ACC_T={};
	for LINE in ACC_DATA:lines() do
		local POS = string.find(LINE,";");
		if POS ~= nil then
			j = LINE:len();
			i = POS;
			NAME = LINE:sub(1,i-1);
			VALUE = LINE:sub(i+1,j);
			ACC_T[NAME] = VALUE;
		end;
	end; 
	ACC_DATA:close();
	-- ����� � ������ ��� ���������
	QUIK_LOGIN = tostring(ACC_T["F_ACCOUNT"]);;
	QUIK_PASSW = tostring(ACC_T["F_ACCOUNT"]);;
	--ACCOUNT = tostring(ACC_T["F_ACCOUNT"]);
	--CLIENT_CODE = tostring(ACC_T["F_CLIENT_CODE"]);
end

function main()
	while IS_RUN do
		if isConnected() == 0 then
			ServDate=DayMonthChange(os.time(os.date("*t"))); -- �������� ���� ������� � ������� ��/��/����
			ServTimeSec = os.time(os.date("*t")); -- ������������ ������� ����� ������� �� ������� � �������
			local waiting = false;
			isNWday=false;
			local curDate=DayMonthChange(os.time(os.date("*t")));
			for k,v in pairs (NWCalendar) do
				if tostring(k)==curDate then isNWday=v end;
			end;
			local weekday=os.date("*t").wday; -- ���� ������ (����������� =1)
			if weekday==1 then 
				waiting = true;
				--message("Sunday is non-working week day "..weekday);
				sleep(6*10^5);
				if not IS_RUN then return; end; -- ���� ������ ���������������, �� ���������� �������
			elseif weekday==7 then
				waiting = true;
				-- message("Saturday is non-working week day "..weekday);
				sleep(6*10^5);
				if not IS_RUN then return; end; -- ���� ������ ���������������, �� ���������� �������
			elseif isNWday then
				waiting = true;
				--message("Calendar non-working day "..curDate);
				sleep(6*10^5);
				if not IS_RUN then return; end; -- ���� ������ ���������������, �� ���������� �������
			else
				for k,v in pairs(T_DP) do -- ��������� ������ � ������ �������� � ������� ��������/�������� ����� ��� ������� ���������
					if k~=nil then
						StartSec = os.time(TimeConvertion(ServDate,tostring(k))); -- ������������ ����� ������ ����� � �������
						StopSec = os.time(TimeConvertion(ServDate,tostring(v))); -- ������������ ����� ����� ����� � �������
						if StopSec>ServTimeSec and  ServTimeSec> StartSec  then 
							waiting = true;
						end;
					end;
				end;			
			end;
			if not waiting then
				hWnd = w32.FindWindow("InfoClass",""); --QUIK_WNDN); -- ����� �������� ���� ���������
				-- �������� ������
				w32.PostMessage(hWnd,WM_COMMAND,100,0); -- ������ �� ������ "���������� ����� �..."
				-- w32.PostMessage(hWnd,WM_COMMAND,101,0) -- ������ �� ������ "��������� ����� �..."
				sleep(1000);
				local netConWnd = w32.FindWindow("", "��������� ����������");
				--message("netConWnd 1 - "..tostring(netConWnd));
				if netConWnd == 0 then
					netConWnd = w32.FindWindow("", "Network connection setting");
					--message("netConWnd 2 - "..tostring(netConWnd)); 
				end;
				if netConWnd ~= 0 then
					local hChldWnd=0;
					local nBtnEnter = 0;
					for 	i=0,5 do
						hChldWnd = w32.FindWindowEx(netConWnd, hChldWnd, "", ""); -- 1� ������� �������� ����
						local wndt1 = w32.GetWindowText(hChldWnd,wndt1,256);
						for 	k=0,1 do
							wndt = w32.GetWindowText(hChldWnd,wndt,256);
							--message("hChldWnd - "..tostring(hChldWnd).." wndt1 - "..tostring(wndt1)..": wndt - "..tostring(wndt) ); 
							if wndt=="&Enter" or wndt=="&����" then 
								nBtnEnter=hChldWnd;
								--message("hChldWnd - "..tostring(hChldWnd).." wndt1 - "..tostring(wndt1)..": wndt - "..tostring(wndt) ); 
								break;
							end;
						end;
					end;
					w32.SetFocus(nBtnEnter);
					w32.PostMessage(nBtnEnter, w32.BM_CLICK, 0, 0);
					sleep(1000);
				end;
				local hLoginWnd = FindLoginWindow();
				--message("1: "..tostring(hLoginWnd))
				if hLoginWnd ~= 0 then
					
					--local n1 = w32.FindWindowEx(hLoginWnd, 0, "", "");
					local hServ = w32.FindWindowEx(hLoginWnd, 0, "", ""); --n1
					local hLogin = w32.FindWindowEx(hLoginWnd, hServ, "", "");
					local nPassw = w32.FindWindowEx(hLoginWnd, hLogin, "", "");
					local nBtnRem = w32.FindWindowEx(hLoginWnd, nPassw, "", "");
					local nBtnOk = w32.FindWindowEx(hLoginWnd, nBtnRem, "", "");

					w32.SetWindowText(hLogin, QUIK_LOGIN);
					w32.SetWindowText(nPassw, QUIK_PASSW);

					w32.SetFocus(nBtnOk);
					w32.PostMessage(nBtnOk, w32.BM_CLICK, 0, 0);
						
					while not isConnected() do sleep(1000); end;
				end;
			end;
		end;
		sleep(timeout);
	end;
end;

function OnStop()
	timeout = 1;
	IS_RUN = false;
end;

function FindLoginWindow()
	hLoginWnd = w32.FindWindow("", "������������� ������������");
	--message("hLoginWnd 1 - "..tostring(hLoginWnd));
	if hLoginWnd == 0 then
		hLoginWnd = w32.FindWindow("", "User identification");
		--message("hLoginWnd 2 - "..tostring(hLoginWnd));
	end;
	return hLoginWnd;
end

function TimeConvertion(CDate, CTime) -- ������������ ��������� ������ ���� � ������� � ������� datetime
	if CDate == nil or CDate == 0 then -- ���� ��� ������ ������� ���� �� ������� - �� ����� �������
		--[[ ������� os.date("%x") ���������� ���� � ������� ��/��/��, ��� �� ������������ 
			 ������� getInfoParam('TRADEDATE') ��/��/����, ������� ����������� �������
		]]	 
		CDate = getInfoParam('TRADEDATE'); 
		if CDate == 0 then 
			local day = (os.date("%d")); 
			local month = (os.date("%m"));
			local year = (os.date("%Y"));
			CDate = day.."/"..month.."/"..year; 
		end;
	end;
	if CTime == nil or CTime == 0 then 
		CTime = getInfoParam('SERVERTIME'); -- ���� ��� ������ ������� ����� �� ������� - �� ����� ������� 
		if CTime == 0 then
			CTime = os.date("%X");
		end;
	end;
-- ����������� ����/����� � ������� ���� datetime
	local dt = {};
	dt.day,dt.month,dt.year,dt.hour,dt.min,dt.sec = string.match(CDate..' '..CTime,"(%d*).(%d*).(%d*) (%d*):(%d*):(%d*)");
	for key,VALUE in pairs(dt) do dt[key] = tonumber(VALUE) end;
	return dt; -- ������� ���� datetime
end;

function DayMonthChange(t) -- ������ ������ ���� � ��������� �������� �� (��/��/��) � (��/��/����)
	local day = (os.date("%d",t)); 
	local month = (os.date("%m",t));
	local year = (os.date("%Y",t));
	ConvertedDate = day.."/"..month.."/"..year; --year..month..day;
	return ConvertedDate; -- ��������� ������ 
end;
