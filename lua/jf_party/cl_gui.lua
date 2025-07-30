jrParty.fonts = jrParty.fonts or {}
function jrParty.font_get(size)
    if jrParty.fonts[size] then return jrParty.fonts[size] end
    jrParty.fonts[size] = "jrParty.Size." .. size
    surface.CreateFont(jrParty.fonts[size], {
        font = "Roboto",
        extended = false,
        size = ScreenScale(size),
        weight = 500,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false,
    })
    return jrParty.fonts[size]
end

local function utf8charbytes(s, i)
    -- argument defaults
    i = i or 1

    -- argument checking
    if type(s) ~= "string" then
        error("bad argument #1 to 'utf8charbytes' (string expected, got " .. type(s) .. ")")
    end
    if type(i) ~= "number" then
        error("bad argument #2 to 'utf8charbytes' (number expected, got " .. type(i) .. ")")
    end

    local c = s:byte(i)

    -- determine bytes needed for character, based on RFC 3629
    -- validate byte 1
    if c > 0 and c <= 127 then
        -- UTF8-1
        return 1
    elseif c >= 194 and c <= 223 then
        -- UTF8-2
        local c2 = s:byte(i + 1)

        if not c2 then
            error("UTF-8 string terminated early")
        end

        -- validate byte 2
        if c2 < 128 or c2 > 191 then
            error("Invalid UTF-8 character")
        end

        return 2
    elseif c >= 224 and c <= 239 then
        -- UTF8-3
        local c2 = s:byte(i + 1)
        local c3 = s:byte(i + 2)

        if not c2 or not c3 then
            error("UTF-8 string terminated early")
        end

        -- validate byte 2
        if c == 224 and (c2 < 160 or c2 > 191) then
            error("Invalid UTF-8 character")
        elseif c == 237 and (c2 < 128 or c2 > 159) then
            error("Invalid UTF-8 character")
        elseif c2 < 128 or c2 > 191 then
            error("Invalid UTF-8 character")
        end

        -- validate byte 3
        if c3 < 128 or c3 > 191 then
            error("Invalid UTF-8 character")
        end

        return 3
    elseif c >= 240 and c <= 244 then
        -- UTF8-4
        local c2 = s:byte(i + 1)
        local c3 = s:byte(i + 2)
        local c4 = s:byte(i + 3)

        if not c2 or not c3 or not c4 then
            error("UTF-8 string terminated early")
        end

        -- validate byte 2
        if c == 240 and (c2 < 144 or c2 > 191) then
            error("Invalid UTF-8 character")
        elseif c == 244 and (c2 < 128 or c2 > 143) then
            error("Invalid UTF-8 character")
        elseif c2 < 128 or c2 > 191 then
            error("Invalid UTF-8 character")
        end

        -- validate byte 3
        if c3 < 128 or c3 > 191 then
            error("Invalid UTF-8 character")
        end

        -- validate byte 4
        if c4 < 128 or c4 > 191 then
            error("Invalid UTF-8 character")
        end

        return 4
    else
        error("Invalid UTF-8 character")
    end
end


-- returns the number of characters in a UTF-8 string
local function utf8len(s)
    -- argument checking
    if type(s) ~= "string" then
        error("bad argument #1 to 'utf8len' (string expected, got " .. type(s) .. ")")
    end

    local pos = 1
    local bytes = s:len()
    local len = 0

    while pos <= bytes do
        len = len + 1
        pos = pos + utf8charbytes(s, pos)
    end

    return len
end

local font_get = jrParty.font_get

local w, h = ScrW(), ScrH()
local x1, x2, x3 = w * 0.1, w * 0.01, w * 0.001
local y1, y2, y3 = h * 0.1, h * 0.01, h * 0.001

local function DrawShadowText(text, font, x, y, color, x_a, y_a, color_shadow)
    color_shadow = color_shadow or Color(0, 0, 0, 255)
    draw.SimpleText(text, font, x + 1, y + 1, color_shadow, x_a, y_a)
    local w, h = draw.SimpleText(text, font, x, y, color, x_a, y_a)
    return w, h
end

local c_base = Color(17, 148, 240)

local PANEL = {}
function PANEL:Init()
    self:InvalidateParent(true)
    self:InvalidateChildren(true)
    self:SetTitle("")
    self.btext = ""
    self.btsize = 9
    self.btcolor = Color(0, 125, 255)
    --self.btcolor2 = Color(255,255,255)

    self.lx = ScrW() * 0.01
    self.ly = ScrH() * 0.01
    self.lx2 = ScrW() * 0.001
    self.ly2 = ScrH() * 0.001
end

function PANEL:InitCloseButton()
    self:ShowCloseButton(false)
    self.c_but = vgui.Create("DButton", self)
    self.c_but:SetSize(self.lx * 2, self.ly * 2.7)
    self.c_but:SetPos(self:GetWide() - self.c_but:GetWide() - self.lx2, self.lx2 * 1.5)
    self.c_but:SetText("")
    self.c_but.Paint = function(but, x, y)
        DrawShadowText("❌", font_get(10), x * 0.5, y * 0.5 - self.lx2 * 2, Color(255, 255, 255), TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER)
    end
    self.c_but.DoClick = function(but) self:Close() end
end

function PANEL:SetBTitle(text)
    self.btext = text
end

function PANEL:SetBTSize(size)
    self.btsize = size
end

function PANEL:Paint(x, y)
    surface.SetDrawColor(Color(75, 75, 75))
    surface.DrawRect(0, 0, x, y)

    surface.SetDrawColor(Color(50, 50, 50))
    surface.DrawRect(0, 0, x, self.ly * 3)

    surface.SetDrawColor(Color(0, 0, 0, 255))
    surface.DrawOutlinedRect(0, 0, x, y)

    DrawShadowText(self.btext, font_get(self.btsize), x * 0.5, self.ly * 1.5, self.btcolor, TEXT_ALIGN_CENTER,
        TEXT_ALIGN_CENTER, self.btcolor2)
end

vgui.Register("JF_Party_Frame", PANEL, "DFrame")


/*
    DTextEntry Custom Panel

*/


local PANEL = {}
PANEL.strAllowedNumericCharacters = "1234567890.-"

function PANEL:Init()
    self:SetCursor("beam")

    self.text = ""
end

function PANEL:RequestPress()
    input.StartKeyTrapping()
    self.Trapping = true
end

function PANEL:StopPress()
    --input.StartKeyTrapping()
    self.Trapping = false
end

function PANEL:OnMousePressed(key)
    if key != MOUSE_LEFT then return end

    self:RequestPress()
end

function PANEL:OnKeyCodePressed(key)
    print("key pressed", key)
end

PANEL.ExitCode = {
    [KEY_ESCAPE] = true,
    [KEY_ENTER] = true,
}
function PANEL:Think()
    if (input.IsKeyTrapping() && self.Trapping) then
        local code = input.CheckKeyTrapping()
        if (code) then
            if PANEL.ExitCode[code] then
                -- self:NextKey( code )
                self:StopPress()
            else
                self:NextKey(code)
                self:RequestPress()
            end
        end
    end

    --self:ConVarNumberThink()
end

PANEL.CodeReplace = {
    [KEY_SPACE] = " "
}

function PANEL:OnChange() end

function PANEL:NextKey(key)
    if key == KEY_BACKSPACE then
        local tc = utf8len(self.text)

        if tc > 1 then
            self.text = utf8.sub(self.text, 1, tc - 1)
        else
            self.text = ""
        end
        self:OnChange()
        return
    end
    local keyStr = self.CodeReplace[key] or input.GetKeyName(key)
    if utf8len(keyStr) == 1 then
        self.text = self.text .. keyStr
        if (self.text:StartWith("#")) then self.text = utf8.sub(self.text, 2) end
        self.text = language.GetPhrase(self.text)
        self:OnChange()
    end
end

function PANEL:GetText()
    return self.text
end

function PANEL:Paint(x, y)
    surface.SetFont(font_get(8))
    local _text = self.text
    if self.Trapping then
        _text = self.text .. "⬅"
    else
        if self.text == "" then
            _text = "Write name.. Click to search"
        end
    end

    local tx, _ = surface.GetTextSize(_text)
    draw.RoundedBox(0, x - tx - x3 * 6 + 2, 2, x - 4, y - 4, Color(50, 50, 50))
    draw.RoundedBox(5, x - tx - x3 * 6, 0, x, y, c_base)
    DrawShadowText(_text, font_get(8), x - x3 * 3, y * 0.5, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

vgui.Register("JF_Party_DTextEntry", PANEL, "EditablePanel")


local PANEL = {}
function PANEL:Init()
    --self:SetCursor( "sizeall" )
    self:SetFocusTopLevel(true)
end

function PANEL:Paint(x, y)
    if self.Dragging then
        surface.SetDrawColor(Color(255, 255, 255, 255))
        surface.DrawOutlinedRect(0, 0, x, y)
    end


    if self.CanDrag or self.Dragging then
        surface.SetDrawColor(Color(100, 100, 100, 200))
        surface.DrawRect(x - 10, 0, x, y)
    end
end

function PANEL:OnCursorExited()
    self.CanDrag = nil
    self.CanSize = nil

    self:SetCursor("arrow")
end

function PANEL:OnCursorMoved(x, y)
    self:SetCursor("arrow")

    local sx, sy = self:GetSize()

    if (sx - x) < 10 then
        self.CanDrag = true
        self:SetCursor("hand")
        --return
    else
        self.CanDrag = false
    end
end

function PANEL:OnMousePressed(key)
    if self.CanDrag then
        self.Dragging = { gui.MouseX() - self.x, gui.MouseY() - self.y }
        return
    end

    if self.CanSize then
        self.Sizing = { gui.MouseX() - self:GetWide(), gui.MouseY() - self:GetTall() }
        self:MouseCapture(true)
        return
    end
end

PANEL.OnStopDragging = function() end
function PANEL:OnMouseReleased(key)
    self.Dragging = nil
    self.Sizing = nil
    self:OnStopDragging(self)
    self:FixPosition()
end

function PANEL:FixPosition()
    local x, y = self:GetPos()
    local w, h = self:GetSize()
    local sw, sh = ScrW(), ScrH()
    local failed = false
    if w > sw then
        failed = true
        w = sw
    end
    if h > sh then
        failed = true
        h = sh
    end
    if x > sw then
        failed = true
        x = 0
    end
    if y > sh then
        failed = true
        y = 0
    end
    if x + w > sw then
        failed = true
        x = sw - w
    end
    if y + h > sh then
        failed = true
        y = sh - h
    end

    if failed then
        self:SetPos(x, y)
        self:SetSize(w, h)
        --self.RichText:AppendText"GUI: Recovered position after invalid values\n"
    end
end

function PANEL:Think()
    local mx = gui.MouseX()
    local my = gui.MouseY()

    -- if ( self.Sizing ) then

    -- 	local x = mx - self.Sizing[1]
    -- 	local y = my - self.Sizing[2]

    -- 	if ( x < 100 ) then x = 100 end
    -- 	if ( y < 18 ) then y = 18 end

    --     if ( x > ScrW() ) then x = ScrW() end
    -- 	if ( y > ScrH() ) then y = ScrH() end

    -- 	self:SetSize( x, y )
    -- 	self:SetCursor( "sizenwse" )
    -- 	return

    -- end

    if (self.Dragging) then
        if not vgui.CursorVisible() then
            self.Dragging = nil
            return
        end

        local x = mx - self.Dragging[1]
        local y = my - self.Dragging[2]

        --if ( self:GetScreenLock() ) then

        x = math.Clamp(x, 0, ScrW() - self:GetWide())
        y = math.Clamp(y, 0, ScrH() - self:GetTall())

        --end

        self:SetPos(x, y)
    end
end

vgui.Register("srP_Main", PANEL, "EditablePanel")




/*


-----------------------------------



*/



local PANEL = {}

AccessorFunc(PANEL, "vertices", "Vertices", FORCE_NUMBER) -- so you can call panel:SetVertices and panel:GetRotation
AccessorFunc(PANEL, "rotation", "Rotation", FORCE_NUMBER) -- so you can call panel:SetRotation and panel:GetRotation
local mat_avatar, _ = Material("materials/party/avatar.png", "smooth noclamp nocull mips")
local mat_dead, _   = Material("materials/party/dead.png", "smooth noclamp nocull mips")
function PANEL:Init()
    self.strokeColor = Color(255, 255, 255)
    self.hovercolor = Color(0, 125, 255)
    self.rotation = 0
    self.vertices = 100
    self:SetMouseInputEnabled(false)
    -- if self:GetParent() then self:GetParent():InvalidateParent(true) end
    self.avatar = vgui.Create("AvatarImage", self)
    self.avatar:Dock(FILL)
    self.avatar:SetPaintedManually(true)
    self.avatar:SetSize(184, 184)
    self.avatar:SetMouseInputEnabled(false)
    self.avatar:InvalidateParent(true)
    self.avatar:InvalidateChildren(true)
    self:InvalidateParent(true)
    self:InvalidateChildren(true)
    /*  DELETE!   */

    --self.avatar:DockMargin(5,5,5,5)
end

function PANEL:SetPlayer(ply, arg)
    self.avatar:SetPlayer(LocalPlayer(), arg or 184)
end

function PANEL:SetStrokeColor(clr)
    self.strokeColor = clr
end

function PANEL:SetHoverColor(clr)
    self.hovercolor = clr
end

function PANEL:CalculatePoly(w, h)
    local poly = {}

    local x = w / 2
    local y = h / 2
    local radius = h / 2.3

    table.insert(poly, { x = x, y = y })

    for i = 0, self.vertices do
        local a = math.rad((i / self.vertices) * -360) + self.rotation
        table.insert(poly, { x = x + math.sin(a) * radius, y = y + math.cos(a) * radius })
    end

    local a = math.rad(0)
    table.insert(poly, { x = x + math.sin(a) * radius, y = y + math.cos(a) * radius })
    self.data = poly
end

function PANEL:PerformLayout()
    self.avatar:SetSize(self:GetWide(), self:GetTall())
    self:CalculatePoly(self:GetWide(), self:GetTall())
end

function PANEL:SetPlayer(ply, size)
    self.avatar:SetPlayer(ply, size)
end

function PANEL:DrawPoly(w, h)
    if (! self.data) then
        self:CalculatePoly(w, h)
    end

    surface.DrawPoly(self.data)
end

function PANEL.DoClick() end

function PANEL:OnMousePressed(key)
    if key == MOUSE_LEFT then
        self:DoClick()
    end
end

function PANEL:Paint(x, y)
    if self.strokeColor then
        surface.SetDrawColor(self.strokeColor)
        surface.SetMaterial(mat_avatar)
        surface.DrawTexturedRect(0, 0, x, y)
    end

    if self.hovercolor and self:IsHovered() then
        surface.SetDrawColor(self.hovercolor)
        surface.SetMaterial(mat_avatar)
        surface.DrawTexturedRect(0, 0, x, y)
    end



    render.ClearStencil()
    render.SetStencilEnable(true)

    render.SetStencilWriteMask(1)
    render.SetStencilTestMask(1)

    render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
    render.SetStencilPassOperation(STENCILOPERATION_ZERO)
    render.SetStencilZFailOperation(STENCILOPERATION_ZERO)
    render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NEVER)
    render.SetStencilReferenceValue(1)

    draw.NoTexture()
    surface.SetDrawColor(color_white)
    self:DrawPoly(x, y)



    render.SetStencilFailOperation(STENCILOPERATION_ZERO)
    render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
    render.SetStencilZFailOperation(STENCILOPERATION_ZERO)
    render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
    render.SetStencilReferenceValue(1)

    self.avatar:PaintManual()

    if self.dead then
        surface.SetDrawColor(Color(255, 0, 0, 200))
        surface.DrawRect(0, 0, x, y)
    end

    render.SetStencilEnable(false)
    render.ClearStencil()


    if self.dead then
        surface.SetDrawColor(Color(255, 255, 255))
        surface.SetMaterial(mat_dead)
        surface.DrawTexturedRect(0, 0, x, y)
    end
end

-- function PANEL.OnCursorEntered(self)
--     self.hovered = true
--     if self.StartHover then self:StartHover(self) end
-- end

-- function PANEL.OnCursorExited(self)
--     self.hovered = false
--     if self.EndHover then self:EndHover(self) end
-- end





vgui.Register("srP_Avatar", PANEL, "EditablePanel")


/*




----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------



*/



local PANEL = {}
function PANEL:Init()
    self.clr1 = Color(255, 255, 255)
    self.clr2 = Color(255, 255, 255)
    self.size1 = { 0, 0, 0, 0 }
    self.size2 = { 0, 0, 0, 0 }
    self:SetCursor("hand")
end

function PANEL:SetMaterial1(mat) self.material1 = mat end

function PANEL:SetColor1(clr) self.clr1 = clr end

function PANEL:SetBorder1(n1, n2, n3, n4) self.size1 = { n1 or 0, n2 or 0, n3 or 0, n4 or 0 } end

function PANEL:SetMaterial2(mat) self.material2 = mat end

function PANEL:SetColor2(clr) self.clr2 = clr end

function PANEL:SetBorder2(n1, n2, n3, n4) self.size2 = { n1 or 0, n2 or 0, n3 or 0, n4 or 0 } end

function PANEL.DoClick() end

function PANEL:OnMousePressed(key)
    if key == MOUSE_LEFT then
        self:DoClick()
    end
end

function PANEL:Paint(x, y)
    if self.material1 then
        local s1, s2, s3, s4 = self.size1[1], self.size1[2], self.size1[3], self.size1[4]
        surface.SetDrawColor(self.clr1)
        surface.SetMaterial(self.material1)
        surface.DrawTexturedRectRotated(x * 0.5 + s1, y * 0.5 + s2, x + s3, y + s4, 0)
    end

    if self.material2 then
        local s1, s2, s3, s4 = self.size2[1], self.size2[2], self.size2[3], self.size2[4]
        surface.SetDrawColor(self.clr2)
        surface.SetMaterial(self.material2)
        surface.DrawTexturedRectRotated(x * 0.5 + s1, y * 0.5 + s2, x + s3, y + s4, 0)
    end
end

vgui.Register("srP_ButIcon", PANEL, "EditablePanel")



local PANEL = {}

function PANEL:UpdateAvatar()
    self.av = (self.av or vgui.Create("srP_Avatar", self))
    self.av:SetSize(self:GetTall(), self:GetTall())
    --self.av:SetPos( self:GetWide() - self.av:GetWide(), 0 )
    --self.av:AlignRight()
    self.av:Dock(RIGHT)
    self.av:SetMouseInputEnabled(true)
    self.avs2 = self.av:GetWide() * 0.5
    -- self.avp = self.av:GetPos() - self.avs2
    -- self.avfl = self:GetWide()
    -- self.avflY = self:GetTall()
    self:SetStrokeColor(self.strokecolor)
    self:SetHoverColor(self.hovercolor)
    self.av.DoClick = function(selfpnl)
        self:ToggleActive()
        print("ToCliec")
    end
end

function PANEL:Init()
    self.hovercolor = Color(0, 125, 255)
    self.strokecolor = Color(100, 0, 125)
    self.insidecolor = Color(125, 0, 255)
    self.active = true
    self:UpdateAvatar()
end

function PANEL:SetPlayer(ply, q)
    self.av.avatar:SetPlayer(ply, q)
    self.text = ply:Nick()
end

function PANEL:SetSteamID(id, q)
    self.av.avatar:SetSteamID(id, q or 184)
    self.text = id
end

function PANEL:SetStrokeColor(clr)
    self.av:SetStrokeColor(clr)
    self.strokecolor = clr
end

function PANEL:SetHoverColor(clr)
    self.av:SetHoverColor(clr)
    self.hovercolor = clr
end

function PANEL:SetInsideColor(clr)
    self.insidecolor = clr
end

function PANEL:Paint(x, y)
    -- if self.av:IsHovered() then
    --     draw.RoundedBox(5, 0, 0, x-self.avs2, y, self.hovercolor)
    -- else
    --     draw.RoundedBox(5, 0, 0, x-self.avs2, y, self.strokecolor)
    -- end

    -- draw.RoundedBox(5, 1, 1, x-2-self.avs2, y-2, self.insidecolor)
    DrawShadowText(self.text, font_get(7), self:GetWide() - self.avs2 * 2.5, self:GetTall() / 2, Color(255, 255, 255),
        TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

function PANEL:ToggleActive()
    self.active = not self.active
    -- if self.active then
    --     self:MoveTo(self.avp,-1,1)
    --     self:SizeTo(0,-1,1)
    -- else
    --     self:MoveTo(0,-1,1)
    --     self:SizeTo(self.avfl,-1,1)
    -- end
end

vgui.Register("srP_AvatarPnl", PANEL, "EditablePanel")
