jrParty = jrParty or {}

local font_get = jrParty.font_get

net.Receive("jrParty.Notify", function(len)
    local text = net.ReadString()
    notification.AddLegacy("[Party] " .. text, 0, 5)
end)

local function DrawShadowText(text, font, x, y, color, x_a, y_a, color_shadow)
    color_shadow = color_shadow or Color(0, 0, 0,255)
    draw.SimpleText(text, font, x + 1, y + 1, color_shadow, x_a, y_a)
    local w,h = draw.SimpleText(text, font, x, y, color, x_a, y_a)
    return w,h
end

local function DrawShadowTexturedRect(sx,sy,ex,ey,mat,clr,clrs)
    surface.SetDrawColor(clrs)
    surface.SetMaterial(mat)
    surface.DrawTexturedRect(sx+1,sy+1,ex+1,ey+1)

    surface.SetDrawColor(clr)
    surface.SetMaterial(mat)
    surface.DrawTexturedRect(sx,sy,ex,ey)
end


local function DrawShadowTexturedRectRotated(sx,sy,ex,ey,mat,clr,clrs,rot)
    surface.SetDrawColor(clrs)
    surface.SetMaterial(mat)
    surface.DrawTexturedRectRotated(sx+1,sy+1,ex+1,ey+1,rot)

    surface.SetDrawColor(clr)
    surface.SetMaterial(mat)
    surface.DrawTexturedRectRotated(sx,sy,ex,ey,rot)
end


--PrecacheParticleSystem("materials/party/headset.png")
local mat_headset, _                = Material("materials/party/headphones_on.png", "noclamp smooth")
local mat_headset_off, _            = Material("materials/party/headphones_off.png", "noclamp smooth")
local mat_microphone, _             = Material("materials/party/mic_on.png", "noclamp smooth")
local mat_microphone_off, _         = Material("materials/party/mic_off.png", "noclamp smooth")
local mat_gear, _                   = Material("materials/party/gear.png", "noclamp smooth")
local mat_esp, _                    = Material("materials/party/esp.png", "noclamp smooth")
local mat_add, _                    = Material("materials/party/plus.png", "noclamp smooth")
local mat_cross, _                  = Material("materials/party/cross.png", "noclamp smooth")
local mat_mark, _                   = Material("materials/party/mark.png", "noclamp smooth")
local mat_circle, _                 = Material("materials/party/avatar.png", "noclamp smooth")

local mat_user, _                   = Material("materials/party/user.png", "noclamp smooth")
local mat_user_holo, _              = Material("materials/party/user_holo.png", "noclamp smooth")

local mat_ping, _                   = Material("materials/party/ping.png", "noclamp smooth")
local mat_ping_circle, _              = Material("materials/party/ping_circle.png", "noclamp smooth")

util.PrecacheSound("sound/party/ping.wav")

jrParty.esp_enabled = jrParty.esp_enabled or false

local c_base = Color(17,148,240)
party_info = party_info or {}
local PARTY_MODE_BASE = 1
local PARTY_MODE_NIL = 2
-- if jrParty.Frame then jrParty.Frame:Remove() end


function jrParty.OpenMenu()
    local lsx,lsy = cookie.GetNumber("party_lastx", 0),cookie.GetNumber("party_lasty", 0)
    local w, h = ScrW(), ScrH()
    local x1, x2, x3 = w*0.1, w*0.01, w*0.001
    local y1, y2, y3 = h*0.1, h*0.01, h*0.001

    if jrParty.Frame then jrParty.Frame:Remove() end
    local fr = vgui.Create("srP_Main")
    jrParty.Frame = fr
    fr:SetSize(x1*2, y1 * 6)

    local ps,py = lsx, lsy
    fr:SetPos(ps,py)
    fr:FixPosition()
    cookie.Set("party_lastx", ps)
    cookie.Set("party_lasty", py)

    fr.OnStopDragging = function(self)
        local ps,py = self:GetPos()
        cookie.Set("party_lastx", ps)
        cookie.Set("party_lasty", py)
        -- print("fsa")
    end


    fr:DockPadding(0,10,10,0)

    --fr:InvalidateParent(true)
    
    local main = vgui.Create("DPanel",fr)
    --main:SetSize(0,y2*30)
    main:Dock(FILL)
    main:InvalidateParent(true)
    -- main:InvalidateChildren(true)
    --main:DockPadding(0,10,10,0)
    main.Paint = nil
    local mode = ( table.Count(party_info) < 1 ) and PARTY_MODE_NIL or PARTY_MODE_BASE

    function fr:ActivateInviteMenu()
        if IsValid(jrParty.InviteMenu) then jrParty.InviteMenu:Remove() end
        local iFrame = vgui.Create("DPanel",main)
        iFrame:SetSize(0,y2*20)
        iFrame:Dock(BOTTOM)
        iFrame:DockPadding(x3,25,x3,x3)
        iFrame.Paint = nil
        -- iFrame:MakePopup()
        jrParty.InviteMenu = iFrame

       

        local pList = vgui.Create("DScrollPanel", iFrame)
        pList:Dock(FILL)
        pList:DockMargin(x3,x3,x3,x3)
        pList.VBar:SetWide(4)
        --pList:SetColor(Color(0,125,255))

        local iTextPnl = vgui.Create("DPanel", iFrame)
        iTextPnl:Dock(TOP)
        iTextPnl:SetSize(1,y2 * 3)
        iTextPnl.Paint = nil

        local iClose = vgui.Create("DButton",iTextPnl)
        iClose:SetSize(iTextPnl:GetTall(),iTextPnl:GetTall())
        iClose:Dock(RIGHT)
        iClose:SetText("")
        iClose.Paint = function(self,x,y)
            draw.RoundedBox(5, 0, 0, x, y, c_base)
            DrawShadowText("❌",font_get(8),x*0.5,y*0.5,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
        end
        iClose.OnMousePressed = function(self)
            iFrame:Remove()
        end
        -- fStr:DockPadding(0,0,iClose:GetWide(),0)


        local hiden = {}
        local fStr = vgui.Create("JF_Party_DTextEntry", iTextPnl)
        fStr:Dock(FILL)
        fStr.OnChange = function(self)
            local text = string.PatternSafe(self:GetText())
            if text ~= "" then
                local tbl = pList.pnlCanvas:GetChildren()
                for k, v in pairs(tbl) do
                    if not v.findstr then continue end
                    if string.find( v.findstr:upper(), text:upper() ) then
                        v:Show()
                    else
                        v:Hide()
                        hiden[#hiden + 1] = v
                    end
                end
                pList:InvalidateChildren(true)
            else
                for k,v in pairs(hiden) do
                    v:Show()
                end
                hiden = {}
                        
            end
        end

        for k, ply in SortedPairs( player.GetAll() ) do
            local pPnl = vgui.Create("srP_AvatarPnl", pList)
            if IsValid( ply ) then pPnl:SetPlayer(ply) else pPnl:SetSteamID(k) end
            pPnl:SetSize(pList:GetWide(),x2*2)
            pPnl.findstr = ply:Nick()
            pPnl:Dock(TOP)
            pPnl:SetStrokeColor(c_base)
            pPnl:DockMargin(0,x3*2,0,0)
            pPnl:UpdateAvatar()
            pPnl:SetHoverColor(Color(255,0,0))

            
            pPnl.av.DoClick = function(self)
                chat.PlaySound()
                net.Start("jrParty.Invite")
                    net.WriteEntity(ply)
                net.SendToServer()
            end

        end
    end



    function fr:LoadParty(mode)
        main:Clear()
        main:InvalidateChildren(true)
        if mode == PARTY_MODE_BASE then
            local av_size = x2*3
            local meisleader = party_info.leader == LocalPlayer()
            local mesteamid64 = LocalPlayer():SteamID64()
            local UpPnl = vgui.Create("DPanel",main)
            UpPnl:SetSize(0,x2*3)
            UpPnl:Dock(TOP)
            UpPnl:InvalidateParent(true)
            UpPnl.BClk = {
                head = function(self)
                    net.Start("jrParty.VoiceChange")
                        net.WriteBool(not party_info.MicroMutes[mesteamid64])
                        net.WriteBool(party_info.HeadMutes[mesteamid64])
                    net.SendToServer()
                end,
                micro = function(self)
                    net.Start("jrParty.VoiceChange")
                        net.WriteBool(party_info.MicroMutes[mesteamid64])
                        net.WriteBool(not party_info.HeadMutes[mesteamid64])
                    net.SendToServer()
                end,
                esp = function(self)
                    jrParty.esp_enabled = not jrParty.esp_enabled
                    jrParty.ESP(jrParty.esp_enabled)
                end
            }
            UpPnl.Paint = function(self, x, y)
                local head_server = party_info.MicroMutes[mesteamid64]
                local micro_server = party_info.HeadMutes[mesteamid64]

                local nextpos = x-av_size-x3*3
                self:SetCursor("arrow")
                self.clksel = nil
                local my = self:GetTall()*0.4
                if self:IsHovered() then
                    local cx,cy = self:LocalCursorPos()
                    nextpos = nextpos - x3*2
                    DrawShadowText("|",font_get(13),nextpos-1,y*0.5-1,Color(255,0,0),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
                    nextpos = nextpos - x3*2

                    nextpos = nextpos - x2 - x3*3
                    if cx >= nextpos and cx < (nextpos + my) then
                        self:SetCursor("hand")
                        DrawShadowTexturedRectRotated(nextpos+my*0.5,y*0.5,my,my,mat_esp,c_base,Color(0,0,0),0)
                        self.clksel = "esp"
                        nextpos = nextpos - x3
                    else
                        DrawShadowTexturedRectRotated(nextpos+my*0.5,y*0.5,my,my,mat_esp,Color(255,255,255),Color(0,0,0),0)
                        nextpos = nextpos - x3
                    end

                    nextpos = nextpos - x2 - x3*3
                    if cx >= nextpos and cx < (nextpos + my) then
                        self:SetCursor("hand")
                        DrawShadowTexturedRectRotated(nextpos+my*0.5,y*0.5,my,my,mat_headset,c_base,Color(0,0,0),0)
                        self.clksel = "head"
                    else
                        DrawShadowTexturedRectRotated(nextpos+my*0.5,y*0.5,my,my,mat_headset,Color(255,255,255),Color(0,0,0),0)
                    end

                    
                    nextpos = nextpos - x2 - x3*3
                    if cx >= nextpos and cx < (nextpos + my) then
                        self:SetCursor("hand")
                        DrawShadowTexturedRectRotated(nextpos+my*0.5,y*0.5,my,my,mat_microphone,c_base,Color(0,0,0),0)
                        self.clksel = "micro"
                    else
                        DrawShadowTexturedRectRotated(nextpos+my*0.5,y*0.5,my,my,mat_microphone,Color(255,255,255),Color(0,0,0),0)
                    end

                    nextpos = nextpos - x3
                    DrawShadowText("|",font_get(13),nextpos-1,y*0.5-1,Color(255,0,0),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
                    nextpos = nextpos - x3*5
                end

                if jrParty.esp_enabled then
                    nextpos = nextpos - x2 - x3*3
                    DrawShadowTexturedRectRotated(nextpos+my*0.5,y*0.5,my,my,mat_esp,c_base,Color(0,0,0),0)
                end

                nextpos = nextpos - x3*2

                DrawShadowText(LocalPlayer():Nick(), font_get(9), nextpos, self:GetTall()*0.5, Color(255,255,255), TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER)

            end
            UpPnl.OnMousePressed = function(self,key)
                if key != MOUSE_LEFT then return end
                if self.clksel and self.BClk[self.clksel] then
                    self.BClk[self.clksel](self)
                end
            end
            

            local av = vgui.Create("srP_Avatar",UpPnl)
            av:SetSize(av_size,av_size)
            av:SetPos(UpPnl:GetWide()-av:GetWide(),0)
            av:SetPlayer(LocalPlayer(),184)
            av:SetStrokeColor(c_base)

            if meisleader then
                local nx,ny = av:GetPos()
                local add_but = vgui.Create("srP_ButIcon",UpPnl)
                add_but:SetSize(x2*1,x2*1)
                add_but:SetPos(nx+x2*2,ny+x2*2)
                add_but:SetMaterial1(mat_circle)
                add_but:SetColor1(c_base)
                add_but:SetMaterial2(mat_add)
                add_but:SetColor2(Color(255,255,255))
                add_but.DoClick = function(self)
                    fr:ActivateInviteMenu()
                end
            end
        

            local nx,ny = av:GetPos()
            local del_but = vgui.Create("srP_ButIcon",UpPnl)
            del_but:SetSize(x2*1,x2*1)
            del_but:SetPos(nx,ny)
            del_but:SetMaterial1(mat_circle)
            del_but:SetColor1(c_base)
            del_but:SetMaterial2(mat_cross)
            del_but:SetColor2(Color(255,255,255))
            del_but:SetBorder2(0,0,-2,-2)
            del_but.DoClick = function(self)
                net.Start("jrParty.Leave")
                net.SendToServer()
            end
        

            local pList = vgui.Create("DScrollPanel",main)
            pList:Dock(FILL)
            pList:DockMargin(0,5,5,0)
            pList.VBar:SetWide(x3*3)
            pList:InvalidateParent(true)
            
            for k,ply in pairs(party_info.members) do
                -- if ply == LocalPlayer() then continue end
                local nick = IsValid( ply ) and ply:Nick() or ("-" .. k  .. "-")
                local pPnl
                local pMain = vgui.Create("DPanel",pList)
                local isme = ply == LocalPlayer()
                
                pMain:SetSize(0,x2*2)
                pMain:Dock(TOP)
                pMain:DockMargin(0,x3*2,0,0)
                pMain:InvalidateParent(true)
                pMain.BClk = {
                    kick = function(self)
                        net.Start("jrParty.Kick")
                            net.WriteEntity(ply)
                        net.SendToServer()
                    end,
                    microphone = function(self)
                        local ply_muted = (party_info.CMute[k] and party_info.CMute[k][mesteamid64]) and true or false
                        net.Start("jrParty.PlyMute")
                            net.WriteEntity(ply)
                            net.WriteBool(not ply_muted)
                        net.SendToServer()
                    end,
                }
                pMain.Paint = function(self,x,y)
                    local ply_muted = (party_info.CMute[k] and party_info.CMute[k][mesteamid64]) and true or false
                    local me_muted = (party_info.CMute[mesteamid64] and party_info.CMute[mesteamid64][k]) and true or false
                    local head_server = party_info.MicroMutes[k]
                    local micro_server = party_info.HeadMutes[k]
                    local nextpos = x-pPnl:GetWide()-x3*3
                    self:SetCursor("arrow")
                    self.clksel = nil
                    local my = self:GetTall()*0.6
                    pPnl.dead = (ply.Alive and not ply:Alive()) and true or false
                    if self:IsHovered() and not isme then
                        local cx,cy = self:LocalCursorPos()

                        nextpos = nextpos - x3*2
                        DrawShadowText("|",font_get(13),nextpos-1,y*0.5-1,Color(255,0,0),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
                        -- nextpos = nextpos - x3*2

                        if meisleader then
                            nextpos = nextpos - x3*2
                            nextpos = nextpos - x2 - x3*3
                            if cx >= nextpos and cx < (nextpos + my) then
                                self:SetCursor("hand")
                                DrawShadowTexturedRectRotated(nextpos+my*0.5,y*0.5,my,my,mat_cross,c_base,Color(0,0,0),0)
                                self.clksel = "kick"
                            else
                                DrawShadowTexturedRectRotated(nextpos+my*0.5,y*0.5,my,my,mat_cross,Color(255,255,255),Color(0,0,0),0)
                            end
                        end

                        
                        nextpos = nextpos - x2 - x3*3
                        if cx >= nextpos and cx < (nextpos + my) then
                            self:SetCursor("hand")
                            DrawShadowTexturedRectRotated(nextpos+my*0.5,y*0.5,my,my,mat_microphone,c_base,Color(0,0,0),0)
                            self.clksel = "microphone"
                        else 
                            -- if ply_muted then
                            --     DrawShadowTexturedRectRotated(nextpos+my*0.5,y*0.5,my,my,mat_microphone,Color(255,255,0),Color(0,0,0),0)
                            -- else
                                DrawShadowTexturedRectRotated(nextpos+my*0.5,y*0.5,my,my,mat_microphone,Color(255,255,255),Color(0,0,0),0)
                            -- end
                        end

                        nextpos = nextpos - x3
                        DrawShadowText("|",font_get(13),nextpos-1,y*0.5-1,Color(255,0,0),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
                    end
                    
                    if ply_muted then
                        nextpos = nextpos - x2 - x3*3
                        DrawShadowTexturedRectRotated(nextpos+my*0.5,y*0.5,my,my,mat_microphone_off,Color(255,255,0),Color(0,0,0),0)
                    elseif micro_server then
                        nextpos = nextpos - x2 - x3*3
                        DrawShadowTexturedRectRotated(nextpos+my*0.5,y*0.5,my,my,mat_microphone_off,Color(255,255,255),Color(0,0,0),0)
                    end
                    if me_muted then
                        nextpos = nextpos - x2 - x3*3
                        DrawShadowTexturedRectRotated(nextpos+my*0.5,y*0.5,my,my,mat_headset_off,Color(255,255,0),Color(0,0,0),0)
                    elseif head_server then
                        nextpos = nextpos - x2 - x3*3
                        DrawShadowTexturedRectRotated(nextpos+my*0.5,y*0.5,my,my,mat_headset_off,Color(255,255,255),Color(0,0,0),0)
                    end
                    nextpos = nextpos - x3*3
                    DrawShadowText(nick, font_get(7), nextpos, self:GetTall()*0.5, Color(255,255,255), TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER)
                end
                pMain.OnMousePressed = function(self,key)
                    if key != MOUSE_LEFT then return end
                    if self.clksel and self.BClk[self.clksel] then
                        self.BClk[self.clksel](self)
                    end
                end


                pPnl = vgui.Create("srP_Avatar", pMain)
                if IsValid( ply ) then pPnl:SetPlayer(ply) else pPnl:SetSteamID(k) end
                pPnl:SetSize(pMain:GetTall(),0)
                pPnl:Dock(RIGHT)
                pPnl:InvalidateParent(true)
                if ply == party_info.leader then
                    pPnl:SetStrokeColor(Color(255,255,100))
                else
                    pPnl:SetStrokeColor(c_base)
                end
                pPnl:InvalidateParent(true)
                
            end
        elseif mode == PARTY_MODE_NIL then
            local cPnl = vgui.Create("DPanel",main)
            cPnl.avzsize = y2*6
            cPnl:SetSize(0,cPnl.avzsize)
            cPnl:Dock(TOP)
            cPnl:DockMargin(0,0,0,x2)
            cPnl:SetMouseInputEnabled(true)
            cPnl:SetCursor("hand")
            cPnl.Paint = function(self,x,y)
                surface.SetDrawColor(c_base)
                surface.SetMaterial(mat_circle)
                surface.DrawTexturedRect(x-self.avzsize+2,2,self.avzsize-4,self.avzsize-4)

                surface.SetDrawColor(255,255,255)
                surface.SetMaterial(mat_add)
                surface.DrawTexturedRect(x-self.avzsize,0,self.avzsize,self.avzsize)    
                DrawShadowText("Create Party",font_get(10),x-self.avzsize-x3*3,self.avzsize*0.5-1,Color(255,255,255),TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER)
            end
            cPnl.OnMousePressed = function(self,key)
                if key != MOUSE_LEFT then return end
                net.Start("jrParty.Create") net.SendToServer()
            end
            cPnl:InvalidateParent(true)

            local closePnl = vgui.Create("DPanel",cPnl)
            closePnl.avzsize = y2*2
            closePnl:SetSize(closePnl.avzsize,closePnl.avzsize)
            closePnl:SetPos(cPnl:GetWide()-closePnl.avzsize,0)
            closePnl:SetMouseInputEnabled(true)
            closePnl:SetCursor("hand")
            closePnl:SetZPos(-1)
            closePnl.Paint = function(self,x,y)
                surface.SetDrawColor(Color(255,255,255))
                surface.SetMaterial(mat_circle)
                surface.DrawTexturedRect(0,0,self.avzsize,self.avzsize,45)   
                if self:IsHovered() then
                    surface.SetDrawColor(Color(255,0,0))
                else
                    surface.SetDrawColor(Color(255,0,0,150))
                end
                surface.SetMaterial(mat_circle)
                surface.DrawTexturedRect(2,2,self.avzsize-4,self.avzsize-4,45)   
            end
            closePnl.OnMousePressed = function(self,key)
                if key != MOUSE_LEFT then return end
                fr:Remove()
            end
            closePnl:InvalidateParent(true)

            local inv_count = 0
            local imain = vgui.Create("DPanel",main)
            imain.fy = x2*7
            imain:SetSize(0,imain.fy)
            imain:Dock(TOP)
            imain.avzsize = x2*2.5
            imain:DockPadding(x3,imain.avzsize + y3*2,x3,x3)
            imain:InvalidateParent(true)
            imain:InvalidateChildren(true)
            imain:SetMouseInputEnabled(true)
            imain:SetCursor("hand")
            imain.alp = 255
            imain.StartSize = 0
            imain.Paint = function(self,x,y)
                if (self.StartSize + 1) > CurTime() then
                    self.alp = math.Clamp(self.alp + self.SizeAdd,30,255)
                end
                surface.SetDrawColor(255,255,255,self.alp)
                surface.SetMaterial(mat_circle)
                surface.DrawTexturedRect(x-self.avzsize,0,self.avzsize,self.avzsize)

                surface.SetDrawColor(ColorAlpha(c_base,self.alp))
                surface.SetMaterial(mat_circle)
                surface.DrawTexturedRect(x-self.avzsize+2,2,self.avzsize-4,self.avzsize-4)

                DrawShadowText("Invites",font_get(10),x-self.avzsize-x3*3,self.avzsize*0.5-1,Color(255,255,255,self.alp),TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER,Color(0,0,0,self.alp))

                DrawShadowText(inv_count,font_get(10),x-self.avzsize*0.5-x3,self.avzsize*0.5-y3,Color(255,255,255,self.alp),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,Color(0,0,0,self.alp))
            end
            imain.OnMousePressed = function(self,key)
                if key != MOUSE_LEFT then return end
                self.sized = not self.sized
                if self.sized then
                    self:SizeTo(-1,self.avzsize,1) 
                    self.StartSize = CurTime()
                    self.SizeAdd = -5
                else
                    self:SizeTo(-1,self.fy,1)
                    self.StartSize = CurTime()
                    self.SizeAdd = 5
                end
            end
            

            local ilist = vgui.Create("DScrollPanel",imain)
            ilist:Dock(FILL)
            ilist.VBar:SetWide(x3*3)

            local invites = {}

            function fr:InviteAdd(id,ply)
                if invites[id] then return end
                invites[id] = true
                inv_count = inv_count + 1
                
                local pPnl
                local iPnl = vgui.Create("DPanel",ilist)
                iPnl.avsize = x2*2
                iPnl:SetSize(0,iPnl.avsize)
                iPnl:Dock(TOP)
                iPnl.Paint = nil
                iPnl:InvalidateParent(true)
                iPnl.OnRemove = function(self)
                    invites[id] = nil
                end
                iPnl.BClk = {
                    accept = function(self)
                        net.Start("jrParty.Accept")
                            net.WriteString(id)
                        net.SendToServer()
                    end,
                    cancel = function(self)
                        self:Remove()
                    end,
                }
                iPnl.nick = IsValid( ply ) and ply:Nick() or ("-" .. id  .. "-")
                iPnl.Paint = function(self,x,y)
                    local nextpos = x-pPnl:GetWide()-x3*3
                    self:SetCursor("arrow")
                    self.clksel = nil
                    local my = self:GetTall()*0.6
                    local cx,cy = self:LocalCursorPos()

                    nextpos = nextpos - x2 - x3*3
                    if cx >= nextpos and cx < (nextpos + my) and (cy > 0) and (cy < my) then
                        self:SetCursor("hand")
                        DrawShadowTexturedRectRotated(nextpos+my*0.5+1,y*0.5,my-2,my-2,mat_circle,Color(0,200,0),Color(0,0,0,100),0)
                        self.clksel = "accept"
                    else
                        DrawShadowTexturedRectRotated(nextpos+my*0.5+1,y*0.5,my-2,my-2,mat_circle,Color(255,255,255),Color(0,0,0,100),0)
                    end

                    
                    nextpos = nextpos - x2 - x3*3
                    if cx >= nextpos and cx < (nextpos + my) and (cy > 0) and (cy < my) then
                        self:SetCursor("hand")
                        DrawShadowTexturedRectRotated(nextpos+my*0.5,y*0.5,my,my,mat_cross,Color(200,0,0),Color(0,0,0,100),0)
                        self.clksel = "cancel"
                    else
                        DrawShadowTexturedRectRotated(nextpos+my*0.5,y*0.5,my,my,mat_cross,Color(255,255,255),Color(0,0,0,100),0)
                    end

                    nextpos = nextpos - x3*3
                    DrawShadowText(self.nick, font_get(7), nextpos, self:GetTall()*0.5, Color(255,255,255), TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER)
                end
                iPnl.OnMousePressed = function(self,key)
                    if key != MOUSE_LEFT then return end
                    if self.clksel and self.BClk[self.clksel] then
                        self.BClk[self.clksel](self)
                    end
                end

                pPnl = vgui.Create("srP_Avatar", iPnl)
                if IsValid( ply ) then pPnl:SetPlayer(ply,184) else pPnl:SetSteamID(id,184) end
                pPnl:SetSize(iPnl.avsize,iPnl.avsize)
                pPnl:Dock(RIGHT)
                pPnl:SetStrokeColor(c_base)


            end
        end
    end
    fr:LoadParty(mode)
end

list.Set(
    "DesktopWindows", 
    "jfParty",
    {
        title = "Party Menu",
        icon = "materials/party/icon.png",
        width = 300,
        height = 170,
        --onewindow = true,
        init = function(icn, pnl)
            jrParty.OpenMenu()
            pnl:Remove()
        end
    }
)


net.Receive("jrParty.NetUpdate", function(len)
    party_info = net.ReadTable()
    jrParty.OpenMenu()
end)


concommand.Add("party_open", function()
    jrParty.OpenMenu()
end)

-- concommand.Add("party_mark",function()
--     if not jrParty.MarkEnabled then notification.AddLegacy("[Party] Mark Disabled", 0, 3) return end
--     local eye = LocalPlayer():GetEyeTrace()
--     net.Start("jrParty.Mark")
--         net.WriteVector(eye.HitPos)
--     net.SendToServer()
-- end)


hook.Add("PlayerButtonDown","Party.Mark",function(ply,key)
    if not jrParty.MarkEnabled then return end
    if ply != LocalPlayer() then return end
    if key != MOUSE_RIGHT then return end
    if not party_info or not party_info.members then  return end
    if not input.IsKeyDown(KEY_LALT) and not input.IsKeyDown(KEY_RALT) then return end

    local eye = ply:GetEyeTrace()
    net.Start("jrParty.Mark")
        net.WriteTable(eye)
    net.SendToServer()
end)

net.Receive("jrParty.Invite",function(len)
    local id, ply = net.ReadString(), net.ReadEntity()
    if not IsValid( jrParty.Frame ) then 
        jrParty.OpenMenu()
    end
    if jrParty.Frame and jrParty.Frame.InviteAdd then 
        jrParty.Frame:InviteAdd(id, ply)
    end
    
end)

jrParty.Marks = jrParty.Marks or {}
function jrParty.Mark(ply,pos)
    local pid = ply:SteamID64()
    local me_pos = LocalPlayer():GetPos()
    if me_pos:Distance(ply:GetPos()) > 1500 then return end


    jrParty.Marks[#jrParty.Marks + 1] = {ply = ply, pos = pos, endtime = CurTime() + jrParty.MarkTime}
    if not jrParty.MarkEnabled then notification.AddLegacy("[Party] Mark Disabled", 0, 5) return end
    -- EmitSound("party/ping.wav", pos, 1, CHAN_AUTO, 1, 75, 0, 100 )
    chat.PlaySound()
    hook.Add("HUDPaint","jrParty.Mark",function()
        if not party_info or not party_info.members then hook.Remove("HUDPaint","jrParty.Mark") return end
        local me_pos = LocalPlayer():GetPos()
        for k,tbl in pairs(jrParty.Marks) do
            if tbl.endtime > CurTime() then
                local mark_pos = tbl.pos
                local sc = mark_pos:ToScreen()
                local v, sx, sy = sc.visible, sc.x, sc.y
                local sadd = ( jrParty.MarkTime - (tbl.endtime - CurTime())  )*100
                local a = 255 - sadd * 3
                if a <= 0 then jrParty.Marks[k] = nil  continue end
                if v then
                    local d = math.Round(mark_pos:Distance(me_pos)/100)


                    -- DrawShadowTexturedRectRotated(sx,sy,40,40,mat_ping,c_base,Color(255,255,255,0),0)
                    -- DrawShadowTexturedRectRotated(sx,sy,40+sadd,40+sadd,mat_ping_circle,Color(255,255,255,a),Color(255,255,255,0),0)
                    if tbl.ply == party_info.leader then
                        surface.SetDrawColor(Color(255,255,0,a))
                    else
                        surface.SetDrawColor(ColorAlpha(c_base,a))
                    end
                    surface.SetMaterial(mat_ping)
                    surface.DrawTexturedRectRotated(sx,sy,40,40,0)

                    surface.SetMaterial(mat_ping_circle)
                    surface.DrawTexturedRectRotated(sx,sy,40+sadd,40+sadd,0)
                    
    
                    DrawShadowText(tbl.ply:Nick(), font_get(7), sx, sy-35, Color(255, 255, 255), TEXT_ALIGN_CENTER)
                    -- DrawShadowText(d .. "m", font_get(5), sx, sy, Color(255, 255, 255), TEXT_ALIGN_CENTER)
                end
            else
                jrParty.Marks[k] = nil
            end
        end
    end)
end

function jrParty.ESP(status)
    if not status then hook.Remove("HUDPaint","jrParty.ESP") jrParty.esp_enabled = false return end
    local mx,my = ScrW()*0.02,ScrH()*0.03
    hook.Add("HUDPaint","jrParty.ESP",function(self)
        if not party_info.members then hook.Remove("HUDPaint","jrParty.ESP") jrParty.esp_enabled = false return end
        jrParty.esp_enabled = true
        local me_pos = EyePos()
        local for_halo = {}
        for k,ply in pairs(party_info.members) do
            if ply == LocalPlayer() then continue end
            if not IsValid(ply) then continue end
            local ply_pos = ply:GetPos()
            local tbl = ply_pos:ToScreen()
            local sx,sy,v = tbl.x,tbl.y,tbl.visible
            if not v then continue end
            local d = math.Round(ply_pos:Distance(me_pos))
            if d < 1500 then
                if ply:Alive() then
                    for_halo[#for_halo + 1] = ply
                end
                DrawShadowText(ply:Nick(),font_get(8),sx,sy,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
            else
                -- DrawShadowTexturedRectRotated(sx,sy-my*0.2,mx,my,mat_user,Color(255,255,255),c_base,0)
                if ply:Alive() then
                    surface.SetDrawColor(Color(50,200,255))
                else
                    surface.SetDrawColor(Color(255,0,0))
                end
                surface.SetMaterial(mat_user)
                surface.DrawTexturedRectRotated(sx,sy-my*0.2,mx,my,0)
                -- DrawShadowTexturedRectRotated(sx,sy-my*0.2,mx,my,mat_user,Color(255,255,255),c_base,0)
                
                surface.SetDrawColor(Color(0,0,0))
                surface.SetMaterial(mat_user_holo)
                surface.DrawTexturedRectRotated(sx,sy-my*0.2,mx,my,0)
                
            end
        end
        halo.Add(for_halo, c_base,2,2,5,true,true)
    end)
end

net.Receive("jrParty.Mark",function(len)
    local ply, pos = net.ReadEntity(), net.ReadVector()
    if not ply or not pos then return end
    jrParty.Mark(ply, pos)
end)

net.Receive("jrParty.VoiceChange",function(len)
    local MicroMutes,HeadMutes = net.ReadTable(), net.ReadTable()
    party_info.MicroMutes = MicroMutes
    party_info.HeadMutes = HeadMutes
end)

net.Receive("jrParty.Leave",function(len)
    party_info = {}
    if jrParty.Frame then 
        jrParty.OpenMenu() 
    end
end)

net.Receive("jrParty.PlyMute", function(len)
    local CMutes = net.ReadTable()
    party_info.CMute = CMutes
end)


