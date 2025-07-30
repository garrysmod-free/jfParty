AddCSLuaFile()
local function _print(...)
    MsgC(Color(0,255,0),"[JfParty] ",Color(255,255,255),...,'\n')
end

local function inc_cl(fl)
    _print("Loading cl:" .. fl)
    AddCSLuaFile(fl)
    if CLIENT then include(fl) end
end

local function inc_sv(fl)
    _print("Loading sv: " .. fl)
    include(fl)
end

local function inc_sh(fl)
    _print("Loading sh: " .. fl)
    AddCSLuaFile(fl)
    include(fl)
end

-- File Include
local sh_files,_ = file.Find("jf_party/sh_*.lua","LUA")
for k, fl in SortedPairs(sh_files) do inc_sh("jf_party/" .. fl) end

local sv_files,_ = file.Find("jf_party/sv_*.lua","LUA")
for k, fl in SortedPairs(sv_files) do inc_sv("jf_party/" .. fl) end

local cl_files,_ = file.Find("jf_party/cl_*.lua","LUA")
for k, fl in SortedPairs(cl_files) do inc_cl("jf_party/" .. fl) end
