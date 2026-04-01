local Widget = require("widgets/widget")
local Image = require("widgets/image")
local Text = require("widgets/text")

local StatusDisplayer = Class(Widget, function(self, owner)
    Widget._ctor(self, "StatusDisplayer")

    self.owner = owner

    self.root = self:AddChild(Widget())

    self.icon = self.root:AddChild(Image())
    self.icon:SetScale(0.5)
    self.icon:SetPosition(-50, 25)

    self.text = self.root:AddChild(Text(NUMBERFONT, 22, STRINGS.AUTOFARM.FARMING))
    self.text:SetPosition(20, 25)

    self:Hide()
end)

function StatusDisplayer:SetData(atlas, tex, str)
    self.icon:SetTexture(atlas, tex)
    self.text:SetString(str)
end

function StatusDisplayer:ShowUI()
    self:Show()
    self:StartUpdating()
end

function StatusDisplayer:HideUI()
    self:Hide()
    self:StopUpdating()
end

function StatusDisplayer:OnUpdate(dt)
    local x, y, z = self.owner.Transform:GetWorldPosition()
    local sx, sy = TheSim:GetScreenPos(x, y + 2.5, z)

    self:SetPosition(sx, sy)
end

return StatusDisplayer