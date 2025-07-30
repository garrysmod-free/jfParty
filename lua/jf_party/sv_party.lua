jrParty = jrParty or {}
util.AddNetworkString("jrParty.Create")
util.AddNetworkString("jrParty.Accept")
util.AddNetworkString("jrParty.Invite")
util.AddNetworkString("jrParty.Leave")
util.AddNetworkString("jrParty.VoiceChange")
util.AddNetworkString("jrParty.EspChange")
util.AddNetworkString("jrParty.Kick")
util.AddNetworkString("jrParty.Notify")
util.AddNetworkString("jrParty.NetUpdate")
util.AddNetworkString("jrParty.Mark")
util.AddNetworkString("jrParty.PlyMute")

resource.AddWorkshop("3276706719")

local function Party_Notify(plys, text)
    if not plys then return end
    net.Start("jrParty.Notify")
    net.WriteString(text)
    net.Send(plys)
end


-- Server convar for bot automatic accept invites
jrParty.CVAR_AcceptBots = CreateConVar("jr_party_accept_bots", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Automatically accept party invites for bots")


jrParty.InviteLife = 60 -- 60 sec

jrParty.Parties = jrParty.Parties or {}
jrParty.Players = jrParty.Players or {}
jrParty.NetInfo = jrParty.NetInfo or {}
jrParty.Invites = {}

function jrParty.ClearData(who)
    local id = isstring(who) and who or who:SteamID64()
    local lid = jrParty.Players[id]
    if jrParty.Parties[lid] then
        if id == lid then
            for k, v in pairs(jrParty.Parties[lid].members) do
                jrParty.Players[k] = nil
            end
            jrParty.Parties[lid] = nil
            jrParty.NetInfo[lid] = nil
        else
            jrParty.Parties[lid].members[id] = nil
            jrParty.Parties[lid].CMute[id] = nil
            jrParty.Parties[lid].HeadMutes[id] = nil
            jrParty.Parties[lid].MicroMutes[id] = nil
            jrParty.NetInfo[lid] = table.ClearKeys(jrParty.Parties[lid].members)
        end
    end

    jrParty.Players[id] = nil
    jrParty.NetInfo[id] = nil
    jrParty.Invites[id] = nil
    jrParty.Parties[id] = nil
end

function jrParty.NetUpdate(who)
    local _tp = type(who)
    if _tp == "Player" then
        if not IsValid(who) then return end
        local id = who:SteamID64()
        local lid = jrParty.Players[id]
        if lid then
            if jrParty.Parties[id] then
                local partyData = jrParty.Parties[id]
                net.Start("jrParty.NetUpdate")
                net.WriteTable(partyData)
                net.Send(jrParty.NetInfo[id])
            elseif jrParty.Parties[lid] then
                local partyData = jrParty.Parties[lid]
                net.Start("jrParty.NetUpdate")
                net.WriteTable(partyData)
                net.Send(who)
            end
        else
            net.Start("jrParty.NetUpdate")
            net.WriteTable({})
            net.Send(who)
        end
    elseif _tp == "string" then
        local partyData = jrParty.Parties[who]
        if partyData then
            net.Start("jrParty.NetUpdate")
            net.WriteTable(partyData)
            net.Send(jrParty.NetInfo[who])
        end
    end
end

function jrParty.Create(leader)
    local id = leader:SteamID64()
    jrParty.Parties[id] = {
        leader = leader,
        members = { [id] = leader },
    }
    jrParty.NetInfo[id] = table.ClearKeys(jrParty.Parties[id].members)
    jrParty.Parties[id].limit = jrParty.Limites[leader:GetUserGroup()] or jrParty.Limites.default
    jrParty.Parties[id].MicroMutes = {}
    jrParty.Parties[id].HeadMutes = {}
    jrParty.Parties[id].CMute = {}
    jrParty.Players[id] = id
    jrParty.NetUpdate(leader)
    Party_Notify(leader, "You created a party!")
end

net.Receive("jrParty.Create", function(len, ply)
    local id = ply:SteamID64()
    if jrParty.Parties[id] then
        Party_Notify(ply, "You have already created a party!")
        return
    end
    if jrParty.Players[id] then
        Party_Notify(ply, "You are already in the party!")
        return
    end
    jrParty.Create(ply)
end)

function jrParty.Leave(ply)
    local pid = ply:SteamID64()
    if not jrParty.Players[pid] then
        Party_Notify(ply, "You are not a party member")
        return
    end

    if jrParty.Parties[pid] then -- Если вы владелец пати
        Party_Notify(jrParty.NetInfo[pid], "Your party has been disbanded by the leader")
        net.Start("jrParty.NetUpdate")
        net.WriteTable({})
        net.Send(jrParty.NetInfo[pid])
        jrParty.ClearData(ply)
        jrParty.NetUpdate(ply)
    else
        local id = jrParty.Players[pid]
        Party_Notify(ply, "You left party")
        if jrParty.Parties[id] then -- Лобби в котором был игрок существует
            local leader = jrParty.Parties[id].leader
            jrParty.ClearData(ply)
            Party_Notify(jrParty.NetInfo[id], ply:Nick() .. " left the party")
            jrParty.NetUpdate(id)
        end
        jrParty.ClearData(ply)
        jrParty.NetUpdate(ply)
    end
end

net.Receive("jrParty.Leave", function(len, ply)
    jrParty.Leave(ply)
end)

function jrParty.Kick(leader, ply)
    local lid = leader:SteamID64()
    local pid = ply:SteamID64()

    if not jrParty.Players[pid] then
        Party_Notify(leader, "This player are not a party member")
        return
    end
    if not jrParty.Players[lid] then
        Party_Notify(leader, "You are not a party member")
        return
    end
    if not jrParty.Parties[lid] then
        Party_Notify(leader, "Only a party leader can kick")
        return
    end
    if pid == lid then
        Party_Notify(leader, "You can't kick yourself")
        return
    end

    jrParty.ClearData(pid)
    Party_Notify(jrParty.NetInfo[lid], ply:Nick() .. " was kicked out of party")
    jrParty.NetUpdate(leader)

    Party_Notify(ply, "You was kicked out of party by leader")
    jrParty.NetUpdate(ply)
end

net.Receive("jrParty.Kick", function(len, leader)
    local ply = net.ReadEntity()
    if not IsValid(ply) then return end
    jrParty.Kick(leader, ply)
end)


function jrParty.Invite(leader, ply)
    local lid = leader:SteamID64()
    local pid = ply:SteamID64()
    if not jrParty.Parties[lid] then
        Party_Notify(leader, "You are not a party leader")
        return
    end
    if jrParty.Players[pid] then
        if jrParty.Players[pid] == lid then
            Party_Notify(leader, "This player is already in your party")
            return
        else
            Party_Notify(leader, "This player is in another party")
            return
        end
    end


    if jrParty.Parties[lid].limit >= table.Count(jrParty.Parties[lid].members) then
        Party_Notify(leader, "You invited " .. ply:Nick() .. " to your party")

        jrParty.Invites[lid] = jrParty.Invites[lid] or {}
        jrParty.Invites[lid][pid] = CurTime() + jrParty.InviteLife
        if not ply:IsBot() then
            net.Start("jrParty.Invite")
            net.WriteString(lid)
            net.WriteEntity(leader)
            net.Send(ply)
        else
            if jrParty.CVAR_AcceptBots:GetBool() then
                jrParty.Accept(ply, lid)
            else
                Party_Notify(leader, "You invited a bot to your party, but it will not accept the invite automatically")
                if jrParty.Invites[lid][pid] then
                    jrParty.Invites[lid][pid] = nil -- Remove invite for bot
                end
            end
        end
    else
        Party_Notify(leader, "In your party the limit of participants")
    end
end

net.Receive("jrParty.Invite", function(len, leader)
    local ply = net.ReadEntity()
    if not ply or not IsValid(ply) or not ply:IsPlayer() then
        Party_Notify(leader, "Player does not exist")
        return
    end
    jrParty.Invite(leader, ply)
end)


function jrParty.Accept(ply, lid)
    local pid = ply:SteamID64()
    if jrParty.Players[pid] then
        Party_Notify(ply, "You are already a party member")
        return
    end
    if not jrParty.Parties[lid] then
        Party_Notify(ply, "Party does not exist")
        return
    end

    if jrParty.Invites[lid] and jrParty.Invites[lid][pid] then
        if (CurTime() + jrParty.InviteLife) >= jrParty.Invites[lid][pid] then
            if table.Count(jrParty.Parties[lid].members) < jrParty.Parties[lid].limit then
                jrParty.Parties[lid].members[pid] = ply
                jrParty.Players[pid] = lid
                jrParty.NetInfo[lid] = table.ClearKeys(jrParty.Parties[lid].members)
                jrParty.NetUpdate(lid)
                Party_Notify(ply, "You have successfully accepted the request!")
                Party_Notify(jrParty.NetInfo[lid], ply:Nick() .. " joined your party")
            else
                Party_Notify(ply, "At party limit participants!")
            end
        else
            Party_Notify(ply, "You did not have time to accept the request")
        end
    else
        Party_Notify(ply, "Invitation not found!")
    end
end

net.Receive("jrParty.Accept", function(len, ply)
    local partyid = net.ReadString()
    if partyid == "" then
        Party_Notify(ply, "Party does not exists")
        return
    end
    jrParty.Accept(ply, partyid)
end)

-- function jrParty.Promote(leader,newleader)
--     local id = leader:SteamID64()
--     local pid = ply:SteamID64()
--     if not jrParty.Players[id] then Party_Notify(leader,"You are not a party member") return end
--     if not jrParty.Parties[id] then Party_Notify(leader,"Only a party leader can promote") return end
--     if jrParty.Players[pid] != id then Party_Notify(leader,"This player is not in your party.") return end

--     local partyInfo = table.Copy(jrParty.Parties[pid])
--     local lid = newleader:SteamID64()
--     jrParty.Parties[pid] = nil
--     jrParty.NetInfo[pid] = nil

--     jrParty.Parties[lid] = partyInfo
--     jrParty.NetInfo[lid] = table.ClearKeys(jrParty.Parties[lid].members)
--     for k, _member in pairs(jrParty.Parties[lid].members) do
--         jrParty.Players[_member:SteamID64()] = lid
--     end
--     jrParty.Parties[lid].leader = newleader
--     Party_Notify(jrParty.NetInfo[lid],ply:Nick() .. " became the party leader")
--     jrParty.NetUpdate(newleader)
-- end

-- net.Receive("jrParty.Promote",function(len,leader)
--     local ply = net.ReadEntity()
--     if not ply or not IsValid(ply) or not ply:IsPlayer() then Party_Notify(leader,"Player does not exist") return end
--     jrParty.Promote(leader,ply)
-- end)

function jrParty.VoiceChange(ply, micro, head)
    local pid = ply:SteamID64()
    local id = jrParty.Players[pid]
    if not id then
        Party_Notify(ply, "You are not a party member")
        return
    end
    if not jrParty.Parties[id] then
        Party_Notify(ply, "You are not a party member")
        return
    end
    local leader = jrParty.Parties[id].leader
    jrParty.Parties[id].HeadMutes[pid] = head
    jrParty.Parties[id].MicroMutes[pid] = micro
    if head == false then jrParty.Parties[id].HeadMutes[pid] = nil end
    if micro == false then jrParty.Parties[id].MicroMutes[pid] = nil end
    net.Start("jrParty.VoiceChange")
    net.WriteTable(jrParty.Parties[id].MicroMutes)
    net.WriteTable(jrParty.Parties[id].HeadMutes)
    net.Send(jrParty.NetInfo[id])
end

net.Receive("jrParty.VoiceChange", function(len, ply)
    local micro, head = net.ReadBool(), net.ReadBool()
    jrParty.VoiceChange(ply, micro, head)
end)

function jrParty.Mute(ply, who, mute)
    local pid = ply:SteamID64()
    local who_id = who:SteamID64()
    local id = jrParty.Players[pid]
    if not id then
        Party_Notify(ply, "You are not a party member")
        return
    end
    if not jrParty.Parties[id] then
        Party_Notify(ply, "You are not a party member")
        return
    end
    if jrParty.Players[who_id] != id then
        Party_Notify(ply, "This player is not in your party")
        return
    end
    local leader = jrParty.Parties[id].leader
    jrParty.Parties[id].CMute = jrParty.Parties[id].CMute or {}
    if mute then
        jrParty.Parties[id].CMute[who_id] = jrParty.Parties[id].CMute[who_id] or {}
        jrParty.Parties[id].CMute[who_id][pid] = true
    else
        jrParty.Parties[id].CMute[who_id][pid] = nil
    end
    net.Start("jrParty.PlyMute")
    net.WriteTable(jrParty.Parties[id].CMute)
    net.Send(jrParty.NetInfo[id])
end

net.Receive("jrParty.PlyMute", function(len, ply)
    local who = net.ReadEntity()
    local mute = net.ReadBool()
    if not IsValid(who) and who != ply then return end
    jrParty.Mute(ply, who, mute)
end)


function jrParty.Disconnect(ply)
    local pid = ply:SteamID64()
    local lid = jrParty.Players[pid]
    if jrParty.Parties[pid] then -- Если вы лидер
        if jrParty.D_WhatDoAfterLeave == 0 then
            jrParty.NetInfo[pid] = table.ClearKeys(jrParty.Parties[pid].members)
            Party_Notify(jrParty.NetInfo[pid], "Your party was disbanded when the leader left the game")
            jrParty.Parties[pid] = nil
            jrParty.NetUpdate(pid)
            jrParty.ClearData(pid)
        else
            if table.Count(jrParty.Parties[pid].members) > 1 then
                jrParty.Parties[pid].members[pid] = nil
                local newleader = table.Random(jrParty.Parties[pid].members)
                local partyInfo = table.Copy(jrParty.Parties[pid])
                local lid = newleader:SteamID64()
                jrParty.Parties[lid] = partyInfo
                jrParty.NetInfo[lid] = table.ClearKeys(jrParty.Parties[lid].members)
                for k, _member in pairs(jrParty.Parties[lid].members) do
                    jrParty.Players[_member:SteamID64()] = lid
                end
                jrParty.Parties[lid].leader = newleader
                Party_Notify(jrParty.NetInfo[lid], newleader:Nick() .. " became the party leader")
                jrParty.NetUpdate(newleader)
                jrParty.ClearData(ply)
            end
        end
    else
        jrParty.ClearData(ply)
        if lid then jrParty.NetUpdate(lid) end
    end
    jrParty.ClearData(pid)
end

hook.Add("PlayerDisconnected", "jrParty", function(ply)
    jrParty.Disconnect(ply)
end)

concommand.Add("party_fix", function(ply, cmd, argS, argT)
    jrParty.NetUpdate(ply)
end)


function jrParty.CanListen(lis, talk)
    local talk_id = talk:SteamID64()
    if jrParty.Players[talk_id] then
        local party_tbl = jrParty.Parties[jrParty.Players[talk_id]]
        local lis_id = lis:SteamID64()
        if party_tbl and party_tbl.members[lis_id] then
            if party_tbl.HeadMutes[talk_id] or party_tbl.HeadMutes[lis_id] or party_tbl.MicroMutes[talk_id] then return end
            return true
        end
        return
    end
    return
end

hook.Add("PlayerCanHearPlayersVoice", "jrParty", function(lis, talk)
    return jrParty.CanListen(lis, talk)
end)

function jrParty.PlayerInitialize(ply)
    jrParty.NetUpdate(ply)
end

hook.Add("PlayerInitialize", "jrParty", function(ply)
    jrParty.PlayerInitialize(ply)
end)

function jrParty.Mark(ply, eye)
    local pid = ply:SteamID64()
    local lid = jrParty.Players[pid]
    if not lid then
        Party_Notify(ply, "You are not a party member")
        return
    end
    net.Start("jrParty.Mark")
    net.WriteEntity(ply)
    net.WriteVector(eye.HitPos)
    net.WriteVector(eye.HitNormal)
    net.Send(jrParty.NetInfo[lid])
end

net.Receive("jrParty.Mark", function(len, ply)
    local eye = net.ReadTable()
    if not eye.HitPos or eye.HitPos == Vector(0, 0, 0) then
        Party_Notify(ply, "Position not found")
        return
    end
    jrParty.Mark(ply, eye)
end)
