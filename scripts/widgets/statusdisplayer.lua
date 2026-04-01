local Widget = require("widgets/widget")
local Image = require("widgets/image")
local Text = require("widgets/text")

local StatusDisplayer = Class(Widget, function(self, owner)
    Widget._ctor(self, "StatusDisplayer")

    self.owner = owner

    self.root = self:AddChild(Widget())
    self.height = 2.5

    self.icon = self.root:AddChild(Image())
    self.icon:SetScale(1)
    self.icon:SetPosition(-100, 25)

    self.text = self.root:AddChild(Text(NUMBERFONT, 44, STRINGS.AUTOFARM.FARMING))
    self.text:SetPosition(40, 25)

    self:Hide()
end)

function StatusDisplayer:SetData(atlas, tex, str, height)
    self.icon:SetTexture(atlas, tex)
    self.text:SetString(str)
    self.height = height or 2.5
end

function StatusDisplayer:ShowUI()
    self:OnUpdate()
    self:Show()
    self:StartUpdating()
end

function StatusDisplayer:HideUI()
    self:Hide()
    self:StopUpdating()
end

function StatusDisplayer:OnUpdate(dt)
    local x, y, z = self.owner.Transform:GetWorldPosition()
    local sx, sy = TheSim:GetScreenPos(x, y + self.height, z)

    self:SetPosition(sx, sy)
end


return StatusDisplayer