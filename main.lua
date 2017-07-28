--[[
-- Kui_SpellList_Config
-- By Kesava at curse.com
-- All rights reserved
]]
local folder,ns = ...
local category = 'Kui |cff9966ffSpell List|r'
local KSL = LibStub('KuiSpellList-2.0')
local pcdd = LibStub('PhanxConfig-Dropdown')

local list_items = {}
local LIST_WHITELIST,LIST_BLACKLIST = 1,2

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

local CreateList
do
    -- list item functions #####################################################
    local function ListItem_ButtonAllOnClick(self)
        if self.parent.parent.list ~= LIST_WHITELIST then return end
        if not self.parent.env then return end

        KSL:RemoveSpell(self.parent.env,true,not self:GetChecked())
        KSL:AddSpell(self.parent.env,true,self:GetChecked())

        self.parent.parent:Update()
    end
    local function ListItem_OnClick(self,button)
        if button == 'LeftButton' and self.parent.list == LIST_WHITELIST then
            self.btn_all:Click()
        elseif button == 'RightButton' then
            -- remove this spell
            if self.parent.list == LIST_WHITELIST then
                KSL:RemoveSpell(self.env,true,self.btn_all:GetChecked())
            else
                KSL:RemoveSpell(self.env)
            end
            self.parent:Update()
        end
    end
    local function ListItem_OnEnter(self)
        self.highlight:Show()
        self:SetBackdropBorderColor(1,1,1)

        if self.spell_link then
            GameTooltip:SetOwner(self,'ANCHOR_NONE')
            GameTooltip:SetPoint('LEFT',self,'RIGHT',0,2)
            GameTooltip:SetHyperlink(self.spell_link)
            GameTooltip:Show()
        end
    end
    local function ListItem_OnLeave(self)
        self.highlight:Hide()
        self:SetBackdropBorderColor(.5,.5,.5)
        GameTooltip:Hide()
    end
    local function CreateListItem(parent)
        local f
        for k,v in ipairs(list_items) do
            if v and not v:IsShown() then
                f = v
                break
            end
        end

        if not f then
            f = CreateFrame('Button',nil,addon)
            f:SetSize(250,40)
            f:EnableMouse(true)
            f:RegisterForClicks('AnyUp')
            f:SetScript('OnClick',ListItem_OnClick)
            f:Hide()

            f:SetBackdrop({
                bgFile = 'interface/chatframe/ChatFrameBackground',
                edgeFile = 'interface/tooltips/ui-tooltip-border',
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            f:SetBackdropColor(.1,.1,.1,.3)
            f:SetBackdropBorderColor(.5,.5,.5)

            local highlight = f:CreateTexture('HIGHLIGHT')
            highlight:SetTexture('interface/buttons/ui-listbox-highlight')
            highlight:SetBlendMode('add')
            highlight:SetAlpha(.5)
            highlight:Hide()
            highlight:SetPoint('TOPLEFT',4,-4)
            highlight:SetPoint('BOTTOMRIGHT',-4,4)

            local icon = f:CreateTexture('ARTWORK')
            icon:SetSize(30,30)
            icon:SetPoint('TOPLEFT',5,-5)

            local name = f:CreateFontString(nil,'ARTWORK')
            name:SetFontObject('GameFontNormal')
            name:SetSize(200,18)
            name:SetPoint('TOPLEFT',icon,'TOPRIGHT',5,1)
            name:SetJustifyH('LEFT')

            local spellid = f:CreateFontString(nil,'ARTWORK')
            spellid:SetFontObject('GameFontNormalSmall')
            spellid:SetTextColor(.5,.5,.5)
            spellid:SetSize(200,18)
            spellid:SetPoint('BOTTOMLEFT',icon,'BOTTOMRIGHT',5,-1)
            spellid:SetJustifyH('LEFT')

            local btn_all = CreateFrame('CheckButton',nil,f,'OptionsBaseCheckButtonTemplate')
            btn_all:SetPoint('RIGHT',-4,0)
            btn_all:SetScript('OnClick',ListItem_ButtonAllOnClick)
            btn_all.parent = f

            local btn_all_label = btn_all:CreateFontString(nil,'ARTWORK','GameFontHighlightSmall')
            btn_all_label:SetAlpha(.7)
            btn_all_label:SetText('All')
            btn_all_label:SetPoint('RIGHT',btn_all,'LEFT')
            btn_all.label = btn_all_label

            f.highlight = highlight
            f.icon = icon
            f.name = name
            f.spellid = spellid
            f.btn_all = btn_all

            f:SetScript('OnEnter',ListItem_OnEnter)
            f:SetScript('OnLeave',ListItem_OnLeave)

            tinsert(list_items,f)
        end

        f:SetParent(parent)
        f.name:SetText('')
        f.spellid:SetText('')
        f.icon:SetTexture('interface/icons/inv_misc_questionmark')
        f.btn_all:SetChecked(nil)
        f.spell_link = nil
        f.parent = parent

        return f
    end
    local function PopulateListItem(parent,id_or_name)
        if not id_or_name then return end

        local f = CreateListItem(parent)
        f.env = id_or_name

        local spell_id   = tonumber(id_or_name)
        local spell_name = spell_id and GetSpellInfo(spell_id)
        local spell_icon = spell_id and select(3,GetSpellInfo(spell_id))
        f.spell_link     = spell_id and GetSpellLink(spell_id)

        if not spell_id or not spell_name then
            -- unknown spell id
            spell_id = nil
            spell_name = id_or_name
        end

        if spell_name then
            f.name:SetText(spell_name)
        end
        if spell_id then
            f.spellid:SetText(spell_id)
        end
        if spell_icon then
            f.icon:SetTexture(spell_icon)
        end

        if parent.list == LIST_WHITELIST then
            f.btn_all:Show()
            f.btn_all:SetChecked(KSL:SpellIncludedAll(id_or_name))
        else
            f.btn_all:Hide()
        end

        f:Show()
        return f
    end

    -- list functions ##########################################################
    local function ListSort(a,b)
        a = type(a) == 'table' and a[2] or (a)
        b = type(b) == 'table' and b[2] or (b)
        return strlower(a) < strlower(b)
    end
    local function List_Wipe(self)
        for k,v in ipairs(self.items) do
            v:Hide()
        end
        wipe(self.items)
    end
    local function List_ParseList(self,list)
        local list_sorted = {}

        for k,v in pairs(list) do
            local id,name
            id = tonumber(k)
            name = id and GetSpellInfo(id)

            if id and name then
                -- spell id and name
                tinsert(list_sorted,{id,name})
            else
                -- string
                tinsert(list_sorted,k)
            end
        end

        table.sort(list_sorted,ListSort)

        for k,v in ipairs(list_sorted) do
            if type(v) == 'table' then
                self:InsertItem(v[1])
            else
                self:InsertItem(v)
            end
        end
    end
    local function List_InsertItem(self,id_or_name)
        local f = PopulateListItem(self,id_or_name)
        tinsert(self.items,f)

        if #self.items == 1 then
            f:SetPoint('TOPLEFT',0,-10)
        else
            local pi = self.items[#self.items-1]
            f:SetPoint('TOP',pi,'BOTTOM')
        end
    end
    function CreateList(parent,name)
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
        l.items = {}

        l.Wipe = List_Wipe
        l.ParseList = List_ParseList
        l.InsertItem = List_InsertItem

        return l
    end
end
local function whitelist_Update(self)
    self:Wipe()

    -- merge "own" and "all" lists into a copy
    local list = {}
    for k,v in pairs(KSL:Export(true,true)) do
        list[k] = v
    end
    for k,v in pairs(KSL:Export(true)) do
        list[k] = v
    end

    self:ParseList(list)
end
local function blacklist_Update(self)
    self:Wipe()

    local list = {}
    for k,v in pairs(KSL:Export()) do
        list[k] = v
    end

    self:ParseList(list)
end
-- scripts #####################################################################
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
    whitelist.Update = whitelist_Update
    whitelist.list = LIST_WHITELIST
    whitelist.items = {}
    self.whitelist = whitelist

    local blacklist = CreateList(self,'Blacklist')
    blacklist.scroll:SetSize(250,300)
    blacklist.scroll:SetPoint('TOPRIGHT',-44,-44)
    blacklist.Update = blacklist_Update
    blacklist.list = LIST_BLACKLIST
    blacklist.items = {}
    self.blacklist = blacklist

    -- #########################################################################
    KSL:AddSpell(204021,true,true)
    KSL:AddSpell(123,true)
    KSL:AddSpell('fake spell in own',true)
    KSL:AddSpell('fake spell in all',true,true)
    KSL:AddSpell(17,true,true)
    KSL:AddSpell(153211)
    KSL:AddSpell(227723,true,true)

    self.whitelist:Update()
    self.blacklist:Update()
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
