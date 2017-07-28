--[[
-- Kui_SpellList_Config
-- By Kesava at curse.com
-- All rights reserved
]]
local folder,ns = ...
local category = 'Kui |cff9966ffSpell List|r'
local KSL = LibStub('KuiSpellList-2.0')
local pcdd = LibStub('PhanxConfig-Dropdown')

local addon = CreateFrame('Frame', 'KuiSpellListConfig', InterfaceOptionsFramePanelContainer)
addon:Hide()
addon.name = category

addon:SetScript('OnEvent',function(self,event,...)
    self[event](self,...)
end)
addon:RegisterEvent('ADDON_LOADED')

-- local functions #############################################################
local function SlashCommand(msg)
    if msg == 'dump' then
        -- dump list of auras on target
        if not UnitExists('target') then
            print('KSLC: run this command with a target to list the auras active on it (debuffs on hostiles, buffs on friends).')
            return
        end

        local filter = UnitCanAttack('player','target') and 'HARMFUL' or 'HELPFUL'
        for i=1,40 do
            local aura = { UnitAura('target',i,filter) }
            if aura[1] and aura[11] then
                print(string.format(
                    'KSLC: [%s] %s',
                    aura[11], aura[1]
                ))
            end
        end
    else
        InterfaceOptionsFrame_OpenToCategory(category)
        InterfaceOptionsFrame_OpenToCategory(category)
    end
end

local function CreateList(parent,name)
    local l = CreateFrame('Frame',nil,parent)
    l:SetSize(1,1)

    local scroll = CreateFrame('ScrollFrame',nil,parent,'UIPanelScrollFrameTemplate')
    scroll:SetScrollChild(l)

    local bg = CreateFrame('Frame',nil,parent)
    bg:SetBackdrop({
        bgFile = 'interface/chatframe/ChatFrameBackground',
        edgeFile = 'interface/tooltips/ui-tooltip-border',
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    bg:SetBackdropColor(.1,.1,.1,.3)
    bg:SetBackdropBorderColor(.5,.5,.5)
    bg:SetPoint('TOPLEFT',scroll,-10,4)
    bg:SetPoint('BOTTOMRIGHT',scroll,26,-5)

    local title = parent:CreateFontString(nil,'ARTWORK','GameFontNormalLarge')
    title:SetText(name)
    title:SetPoint('BOTTOM',bg,'TOP',0,3)

    l.scroll = scroll
    l.bg = bg
    l.title = title

    return l
end
-- scripts #####################################################################
local function whitelist_Update(self)
    local all = KSL:Export(true,true)
    local own = KSL:Export(true)

    local list = {}
    for id,_ in pairs(all) do
        local n = GetSpellInfo(id)
        tinsert(list, {
            text = n or id,
            value = id
        })
    end

    for id,_ in pairs(own) do
        local n = GetSpellInfo(id)
        tinsert(list, {
            text = n or id,
            value = id
        })
    end

    self:SetList(list)
end
local function blacklist_Update(self)
    local exclude = KSL:Export()
end
function addon:OnShow()
    if addon.shown then return end
    addon.shown = true

    local input = CreateFrame('EditBox',nil,self,'InputBoxTemplate')
    input:SetMultiLine(false)
    input:SetAutoFocus(false)
    input:EnableMouse(true)
    input:SetFontObject('ChatFontNormal')
    input:SetSize(173,30)
    input:SetPoint('CENTER',0,-90)

    local b_own = CreateFrame('Button',nil,self,'UIPanelButtonTemplate')
    b_own:SetText('Own')
    b_own:SetSize(60,22)
    b_own:SetPoint('TOPLEFT',input,'BOTTOMLEFT',-7,0)

    local b_all = CreateFrame('Button',nil,self,'UIPanelButtonTemplate')
    b_all:SetText('All')
    b_all:SetSize(60,22)
    b_all:SetPoint('LEFT',b_own,'RIGHT')

    local b_exc = CreateFrame('Button',nil,self,'UIPanelButtonTemplate')
    b_exc:SetText('None')
    b_exc:SetSize(60,22)
    b_exc:SetPoint('LEFT',b_all,'RIGHT')

    local whitelist = CreateList(self,'Whitelist')
    whitelist.scroll:SetSize(250,300)
    whitelist.scroll:SetPoint('TOPLEFT',30,-44)

    local blacklist = CreateList(self,'Blacklist')
    blacklist.scroll:SetSize(250,300)
    blacklist.scroll:SetPoint('TOPRIGHT',-44,-44)
end
-- events ######################################################################
function addon:ADDON_LOADED(loaded)
    if loaded ~= folder then return end
    self:UnregisterEvent('ADDON_LOADED')

    self:SetScript('OnShow',self.OnShow)

    InterfaceOptions_AddCategory(self)

    SLASH_KUISPELLLIST1 = '/kuislc'
    SLASH_KUISPELLLIST2 = '/kslc'
    SlashCmdList.KUISPELLLIST = SlashCommand
end
