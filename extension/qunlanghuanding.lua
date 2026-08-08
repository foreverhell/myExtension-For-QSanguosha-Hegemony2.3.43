extension = sgs.Package("qunlanghuanding", sgs.Package_GeneralPack)

yuejin_qunlang = sgs.General(extension, "yuejin_qunlang", "wei", 4)

xiaoguoQunlang = sgs.CreateTriggerSkill{
    name = "xiaoguoQunlang",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,

    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:getPhase() == sgs.Player_Finish) then return "" end

        local skill_list = {}
        local name_list = {}
        for _, yuejin in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if yuejin and yuejin:isAlive()
                and yuejin:objectName() ~= player:objectName()
                and not yuejin:isKongcheng()
                and not table.contains(name_list, yuejin:objectName()) then
                table.insert(skill_list, self:objectName())
                table.insert(name_list, yuejin:objectName())
            end
        end

        if #skill_list > 0 then
            return table.concat(skill_list, "|"), table.concat(name_list, "|")
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        local prompt = "@xiaoguoQunlang:" .. player:objectName()
        local card = room:askForCard(ask_who, ".|.|.|hand", prompt, data, sgs.Card_MethodDiscard)
        if card then
            room:doAnimate(1, ask_who:objectName(), player:objectName())
            room:broadcastSkillInvoke(self:objectName(), ask_who)
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        if not (player and player:isAlive() and ask_who and ask_who:isAlive()) then return false end

        local damage = sgs.DamageStruct()
        damage.from = ask_who
        damage.to = player
        damage.damage = 1
        damage.reason = self:objectName()
        damage.nature = sgs.DamageStruct_Normal
        room:damage(damage)

        if player:isAlive() and player:hasEquip() and player:isWounded() then
            local prompt = "@xiaoguoQunlang-discard:" .. ask_who:objectName()
            local card = room:askForCard(player, ".|.|.|equipped", prompt, data, sgs.Card_MethodDiscard)
            if card and player:isAlive() and player:isWounded() then
                local recover = sgs.RecoverStruct()
                recover.who = player
                recover.recover = 1
                room:recover(player, recover)
            end
        end

        return false
    end
}

yuejin_qunlang:addSkill(xiaoguoQunlang)

bianfuren_qunlang = sgs.General(extension, "bianfuren_qunlang", "wei", 3, false)

wanweiQunlangCard = sgs.CreateSkillCard{
    name = "wanweiQunlangCard",
    target_fixed = true,
    will_throw = false,
    handling_method = sgs.Card_MethodNone,

    on_use = function(self, room, source, targets)
        local target = source:getTag("wanweiQunlang_target"):toPlayer()
        if not (target and target:isAlive()) then return end

        local n = self:getSubcards():length()
        if n <= 0 then return end

        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), "wanweiQunlang", "")
        room:moveCardTo(self, target, sgs.Player_PlaceHand, reason)
        room:setPlayerFlag(source, "wanweiQunlang_used")
        room:addPlayerMark(source, "wanweiQunlang_draw_" .. target:objectName(), n)
    end
}

wanweiQunlangVS = sgs.CreateViewAsSkill{
    name = "wanweiQunlang",
    response_pattern = "@@wanweiQunlang",

    view_filter = function(self, selected, to_select)
        return #selected < 3
    end,

    view_as = function(self, cards)
        if #cards == 0 then return nil end

        local skill_card = wanweiQunlangCard:clone()
        for _, card in ipairs(cards) do
            skill_card:addSubcard(card:getId())
        end
        skill_card:setSkillName(self:objectName())
        skill_card:setShowSkill(self:objectName())
        return skill_card
    end
}

wanweiQunlang = sgs.CreateTriggerSkill{
    name = "wanweiQunlang",
    events = {sgs.Dying, sgs.QuitDying},
    frequency = sgs.Skill_Frequent,
    view_as_skill = wanweiQunlangVS,

    can_trigger = function(self, event, room, player, data)
        local dying = data:toDying()

        if event == sgs.Dying then
            if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
            if player:objectName() == dying.who:objectName() then return "" end
            if player:hasFlag("wanweiQunlang_used") then return "" end
            if player:isNude() then return "" end
            if player:willBeFriendWith(dying.who) then
                return self:objectName(), player:objectName()
            end
        elseif event == sgs.QuitDying then
            local skill_list = {}
            local name_list = {}
            for _, bianfuren in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if bianfuren and bianfuren:isAlive() and bianfuren:getMark("wanweiQunlang_draw_" .. dying.who:objectName()) > 0 then
                    table.insert(skill_list, self:objectName())
                    table.insert(name_list, bianfuren:objectName())
                end
            end
            if #skill_list > 0 then
                return table.concat(skill_list, "|"), table.concat(name_list, "|")
            end
        end

        return ""
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        local dying = data:toDying()
        if event == sgs.Dying then
            local target_data = sgs.QVariant()
            target_data:setValue(dying.who)
            ask_who:setTag("wanweiQunlang_target", target_data)
            local prompt = "@wanweiQunlang:" .. dying.who:objectName()
            local invoked = room:askForUseCard(ask_who, "@@wanweiQunlang", prompt) ~= nil
            ask_who:removeTag("wanweiQunlang_target")
            if invoked then
                room:doAnimate(1, ask_who:objectName(), dying.who:objectName())
                room:broadcastSkillInvoke(self:objectName(), ask_who)
                return true
            end
            return false
        elseif event == sgs.QuitDying then
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        if event == sgs.QuitDying then
            local dying = data:toDying()
            local mark_name = "wanweiQunlang_draw_" .. dying.who:objectName()
            local n = ask_who:getMark(mark_name)
            room:setPlayerMark(ask_who, mark_name, 0)
            if n > 0 and ask_who:isAlive() then
                ask_who:drawCards(n, self:objectName())
            end
        end
        return false
    end
}
--[[
yuejianQunlang = sgs.CreateMaxCardsSkill{
    name = "yuejianQunlang",
    frequency = sgs.Skill_Compulsory,

    extra_func = function(self, target)
        local room = target:getRoom()
        for _, bianfuren in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if bianfuren and bianfuren:isAlive() and bianfuren:hasShownSkill(self:objectName()) and bianfuren:isFriendWith(target) then
                return target:getLostHp()
            end
        end
        return 0
    end
}
]]
bianfuren_qunlang:addSkill(wanweiQunlang)
--bianfuren_qunlang:addSkill(yuejianQunlang)

ganfuren_qunlang = sgs.General(extension, "ganfuren_qunlang", "shu", 3, false)

local function shenzhiQunlangChoices(target)
    local choices = {}
    if target:getHandcardNum() == 1 then
        table.insert(choices, "hand")
    end
    if target:getEquips():length() == 1 then
        table.insert(choices, "equip")
    end
    if target:getJudgingArea():length() == 1 then
        table.insert(choices, "judge")
    end
    return choices
end

shenzhiQunlang = sgs.CreateTriggerSkill{
    name = "shenzhiQunlang",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,

    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start) then return "" end

        for _, target in sgs.qlist(room:getAlivePlayers()) do
            if #shenzhiQunlangChoices(target) > 0 then
                return self:objectName()
            end
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        local targets = sgs.SPlayerList()
        for _, target in sgs.qlist(room:getAlivePlayers()) do
            if #shenzhiQunlangChoices(target) > 0 then
                targets:append(target)
            end
        end

        if targets:isEmpty() then return false end

        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@shenzhiQunlang", true, true)
        if target then
            local choices = shenzhiQunlangChoices(target)
            local area = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), data)
            local target_data = sgs.QVariant()
            target_data:setValue(target)
            player:setTag("shenzhiQunlang_target", target_data)
            player:setTag("shenzhiQunlang_area", sgs.QVariant(area))
            room:doAnimate(1, player:objectName(), target:objectName())
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data)
        local target = player:getTag("shenzhiQunlang_target"):toPlayer()
        local area = player:getTag("shenzhiQunlang_area"):toString()
        player:removeTag("shenzhiQunlang_target")
        player:removeTag("shenzhiQunlang_area")

        if not (target and target:isAlive()) then return false end

        local place = ""
        if area == "hand" and target:getHandcardNum() == 1 then
            place = "h"
        elseif area == "equip" and target:getEquips():length() == 1 then
            place = "e"
        elseif area == "judge" and target:getJudgingArea():length() == 1 then
            place = "j"
        end

        if place ~= "" then
            local card_id = room:askForCardChosen(player, target, place, self:objectName(), false, sgs.Card_MethodDiscard)
            room:throwCard(card_id, target, player)
            if target:isAlive() and target:isWounded() then
                local recover = sgs.RecoverStruct()
                recover.who = player
                recover.recover = 1
                room:recover(target, recover)
            end
        end
        return false
    end
}

shushenQunlang = sgs.CreateTriggerSkill{
    name = "shushenQunlang",
    events = {sgs.HpRecover, sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Frequent,

    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end

        if event == sgs.HpRecover then
            local recover = data:toRecover()
            if recover and recover.recover > 0 and not player:hasFlag("shushenQunlangRecover") and not room:getOtherPlayers(player):isEmpty() then
                return self:objectName()
            end
        elseif event == sgs.CardsMoveOneTime then
            if player:hasFlag("shushenQunlangObtain") then return "" end
            local has_wounded_other = false
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:isWounded() then
                    has_wounded_other = true
                    break
                end
            end
            if not has_wounded_other then return "" end
            local move_datas = data:toList()
            for _, move_data in sgs.qlist(move_datas) do
                local move = move_data:toMoveOneTime()
                if move.to and move.to:isAlive() and move.to:objectName() == player:objectName()
                    and move.to_place == sgs.Player_PlaceHand and move.card_ids:length() >= 2 then
                    return self:objectName()
                end
            end
        end

        return ""
    end,

    on_cost = function(self, event, room, player, data)
        local prompt = "@shushenQunlang-draw"
        if event == sgs.CardsMoveOneTime then
            prompt = "@shushenQunlang-recover"
        end

        local targets = sgs.SPlayerList()
        if event == sgs.CardsMoveOneTime then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:isWounded() then
                    targets:append(p)
                end
            end
        else
            targets = room:getOtherPlayers(player)
        end
        if targets:isEmpty() then return false end

        local target = room:askForPlayerChosen(player, targets, self:objectName(), prompt, true, true)
        if target then
            local target_data = sgs.QVariant()
            target_data:setValue(target)
            player:setTag("shushenQunlang_target", target_data)
            room:doAnimate(1, player:objectName(), target:objectName())
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data)
        local target = player:getTag("shushenQunlang_target"):toPlayer()
        player:removeTag("shushenQunlang_target")
        if not (target and target:isAlive()) then return false end

        if event == sgs.HpRecover then
            room:setPlayerFlag(player, "shushenQunlangRecover")
            target:drawCards(2, self:objectName())
        elseif event == sgs.CardsMoveOneTime then
            room:setPlayerFlag(player, "shushenQunlangObtain")
            if target:isWounded() then
                local recover = sgs.RecoverStruct()
                recover.who = player
                recover.recover = 1
                room:recover(target, recover)
            end
        end
        return false
    end
}

ganfuren_qunlang:addSkill(shenzhiQunlang)
ganfuren_qunlang:addSkill(shushenQunlang)


simawei = sgs.General(extension, "simawei", "jin", 4)

local function guoruiAppendSlash(room, card)
    if not (card and card:isKindOf("Slash")) then return end

    local records = {}
    local old_records = room:getTag("guorui_slashes"):toString()
    if old_records and old_records ~= "" then
        table.insert(records, old_records)
    end

    local subcards = card:getSubcards()
    if subcards and not subcards:isEmpty() then
        for _, id in sgs.qlist(subcards) do
            table.insert(records, tostring(id) .. ":" .. card:objectName())
        end
    elseif card:getEffectiveId() >= 0 then
        table.insert(records, tostring(card:getEffectiveId()) .. ":" .. card:objectName())
    end

    room:setTag("guorui_slashes", sgs.QVariant(table.concat(records, ";")))
end

local function guoruiSlashInfos(room)
    local infos = {}
    local seen = {}
    local records = room:getTag("guorui_slashes"):toString()
    if not records or records == "" then return infos end

    for item in string.gmatch(records, "[^;]+") do
        local id_text, name = string.match(item, "^(%-?%d+):([^:]+)$")
        local id = tonumber(id_text)
        if id and id >= 0 and not seen[id] and room:getCardPlace(id) == sgs.Player_DiscardPile then
            local real_card = sgs.Sanguosha:getCard(id)
            if real_card and real_card:isKindOf("Slash") then
                seen[id] = true
                table.insert(infos, {id = id, name = name})
            end
        end
    end
    return infos
end

local function guoruiCanUseSlash(room, source)
    if not (source and source:isAlive()) then return false end

    for _, info in ipairs(guoruiSlashInfos(room)) do
        local real_card = sgs.Sanguosha:getCard(info.id)
        local slash = sgs.Sanguosha:cloneCard(real_card:objectName(), real_card:getSuit(), real_card:getNumber())
        slash:addSubcard(info.id)
        slash:setSkillName("guorui")
        slash:deleteLater()
        if not source:isCardLimited(slash, sgs.Card_MethodUse) then
            for _, target in sgs.qlist(room:getAlivePlayers()) do
                if target:objectName() ~= source:objectName() and source:canSlash(target, slash, false) then
                    return true
                end
            end
        end
    end
    return false
end

guorui = sgs.CreateTriggerSkill{
    name = "guorui",
    events = {sgs.CardUsed, sgs.CardResponded, sgs.CardFinished},
    frequency = sgs.Skill_Frequent,

    on_record = function(self, event, room, player, data)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use and use.card and use.card:isKindOf("Duel") then
                room:setTag("guorui_duel_active", sgs.QVariant(true))
                room:setTag("guorui_slashes", sgs.QVariant(""))
            end
        elseif event == sgs.CardResponded then
            if room:getTag("guorui_duel_active"):toBool() then
                local response = data:toCardResponse()
                if response and response.m_card and response.m_card:isKindOf("Slash") then
                    guoruiAppendSlash(room, response.m_card)
                end
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use and use.card and use.card:isKindOf("Duel") then
                room:setTag("guorui_duel_active", sgs.QVariant(false))
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if event ~= sgs.CardFinished then return "" end
        local use = data:toCardUse()
        if not (use and use.card and use.card:isKindOf("Duel")) then return "" end

        local skill_list = {}
        local owner_list = {}
        for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if owner and owner:isAlive() and (guoruiCanUseSlash(room, owner) or owner:canTransform()) then
                table.insert(skill_list, self:objectName())
                table.insert(owner_list, owner:objectName())
            end
        end
        return table.concat(skill_list, "|"), table.concat(owner_list, "|")
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        local choices = {}
        if guoruiCanUseSlash(room, ask_who) then
            table.insert(choices, "use_slash")
        end
        if ask_who:canTransform() then
            table.insert(choices, "transform")
        end
        if #choices == 0 then return false end
        table.insert(choices, "cancel")

        local choice = room:askForChoice(ask_who, self:objectName(), table.concat(choices, "+"), data)
        if choice == "cancel" then return false end

        ask_who:setTag("guorui_choice", sgs.QVariant(choice))
        if choice == "use_slash" then
            local targets = sgs.SPlayerList()
            for _, target in sgs.qlist(room:getAlivePlayers()) do
                if target:objectName() ~= ask_who:objectName() then
                    for _, info in ipairs(guoruiSlashInfos(room)) do
                        local real_card = sgs.Sanguosha:getCard(info.id)
                        local slash = sgs.Sanguosha:cloneCard(real_card:objectName(), real_card:getSuit(), real_card:getNumber())
                        slash:addSubcard(info.id)
                        slash:setSkillName(self:objectName())
                        slash:deleteLater()
                        if not ask_who:isCardLimited(slash, sgs.Card_MethodUse) and ask_who:canSlash(target, slash, false) then
                            targets:append(target)
                            break
                        end
                    end
                end
            end
            if targets:isEmpty() then
                ask_who:removeTag("guorui_choice")
                return false
            end

            local target = room:askForPlayerChosen(ask_who, targets, self:objectName(), "@guorui-target", false, true)
            local target_data = sgs.QVariant()
            target_data:setValue(target)
            ask_who:setTag("guorui_target", target_data)
            room:doAnimate(1, ask_who:objectName(), target:objectName())
        end

        room:broadcastSkillInvoke(self:objectName(), ask_who)
        return true
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        local choice = ask_who:getTag("guorui_choice"):toString()
        ask_who:removeTag("guorui_choice")

        if choice == "transform" then
            if ask_who:canTransform() then
                room:transformDeputyGeneral(ask_who)
            end
        elseif choice == "use_slash" then
            local target = ask_who:getTag("guorui_target"):toPlayer()
            ask_who:removeTag("guorui_target")
            if not (target and target:isAlive()) then return false end

            for _, info in ipairs(guoruiSlashInfos(room)) do
                if not (ask_who:isAlive() and target:isAlive()) then break end
                if room:getCardPlace(info.id) == sgs.Player_DiscardPile then
                    local real_card = sgs.Sanguosha:getCard(info.id)
                    local slash = sgs.Sanguosha:cloneCard(real_card:objectName(), real_card:getSuit(), real_card:getNumber())
                    slash:addSubcard(info.id)
                    slash:setSkillName(self:objectName())
                    slash:deleteLater()
                    if not ask_who:isCardLimited(slash, sgs.Card_MethodUse) and ask_who:canSlash(target, slash, false) then
                        room:useCard(sgs.CardUseStruct(slash, ask_who, target), false)
                    end
                end
            end
        end
        return false
    end
}

simawei:addSkill(guorui)

simaying = sgs.General(extension, "simaying", "jin", 4)

local function chengguanExchangeHandcards(room, from, to, skill_name)
    if not (from and to and from:isAlive() and to:isAlive()) then return end

    local from_handcards = from:handCards()
    local to_handcards = to:handCards()
    if from_handcards:isEmpty() and to_handcards:isEmpty() then return end

    local move1 = sgs.CardsMoveStruct()
    move1.card_ids = from_handcards
    move1.from = from
    move1.to = to
    move1.to_place = sgs.Player_PlaceHand
    move1.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE,
                                      from:objectName(), to:objectName(), skill_name, "")

    local move2 = sgs.CardsMoveStruct()
    move2.card_ids = to_handcards
    move2.from = to
    move2.to = from
    move2.to_place = sgs.Player_PlaceHand
    move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE,
                                      to:objectName(), from:objectName(), skill_name, "")

    local moves = sgs.CardsMoveList()
    moves:append(move1)
    moves:append(move2)
    room:moveCardsAtomic(moves, true)
end

chengguan = sgs.CreateTriggerSkill{
    name = "chengguan",
    events = {sgs.Damaged},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if event ~= sgs.Damaged then return "" end
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end

        if not player:hasFlag("chengguan_damage") then
            return self:objectName()
        end

        local damage = data:toDamage()
        if damage and damage.from and damage.from:isAlive() and damage.from:objectName() ~= player:objectName()
            and not (damage.from:isKongcheng() and player:isKongcheng()) then
            return self:objectName()
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        if not player:hasFlag("chengguan_damage") then
            room:setPlayerFlag(player, "chengguan_damage")

            local targets = sgs.SPlayerList()
            for _, target in sgs.qlist(room:getOtherPlayers(player)) do
                if not (player:isKongcheng() and target:isKongcheng()) then
                    targets:append(target)
                end
            end
            if targets:isEmpty() then return false end

            local target = room:askForPlayerChosen(player, targets, self:objectName(), "@chengguan-target", true, true)
            if target then
                local target_data = sgs.QVariant()
                target_data:setValue(target)
                player:setTag("chengguan_target", target_data)
                room:doAnimate(1, player:objectName(), target:objectName())
                room:broadcastSkillInvoke(self:objectName(), player)
                return true
            end
        else
            local damage = data:toDamage()
            local source = damage.from
            if not (source and source:isAlive() and source:objectName() ~= player:objectName()) then return false end
            if source:isKongcheng() and player:isKongcheng() then return false end

            local choice = room:askForChoice(source, self:objectName(), "exchange+cancel", data)
            if choice == "exchange" then
                room:doAnimate(1, source:objectName(), player:objectName())
                room:broadcastSkillInvoke(self:objectName(), player)
                return true
            end
        end
        return false
    end,

    on_effect = function(self, event, room, player, data)
        if player:getTag("chengguan_target"):toPlayer() then
            local target = player:getTag("chengguan_target"):toPlayer()
            player:removeTag("chengguan_target")
            chengguanExchangeHandcards(room, player, target, self:objectName())
        else
            local damage = data:toDamage()
            if damage and damage.from and damage.from:isAlive() then
                chengguanExchangeHandcards(room, player, damage.from, self:objectName())
            end
        end
        return false
    end
}

simaying:addSkill(chengguan)

simayu = sgs.General(extension, "simayu", "jin", 4)

local function mieyiIsDamageCard(card)
    local damage_cards = {"Slash", "Duel", "ArcheryAttack", "SavageAssault", "BurningCamps", "Drowning", "FireAttack"}
    for _, class_name in ipairs(damage_cards) do
        if card:isKindOf(class_name) then
            return true
        end
    end
    return false
end

local function mieyiDamageCardIds(player)
    local ids = sgs.IntList()
    for _, card in sgs.qlist(player:getHandcards()) do
        if mieyiIsDamageCard(card) then
            ids:append(card:getId())
        end
    end
    return ids
end

local function mieyiBefriendCard(player, ids)
    if ids:isEmpty() then return nil end

    local card = sgs.Sanguosha:cloneCard("befriend_attacking", sgs.Card_NoSuit, 0)
    for _, id in sgs.qlist(ids) do
        card:addSubcard(id)
    end
    card:setSkillName("mieyi")
    card:deleteLater()
    return card
end

local function mieyiTargets(room, player, card)
    local targets = sgs.SPlayerList()
    if not (card and player and player:isAlive()) then return targets end
    if player:isCardLimited(card, sgs.Card_MethodUse) then return targets end

    for _, target in sgs.qlist(room:getAlivePlayers()) do
        local selected = sgs.PlayerList()
        if target:objectName() ~= player:objectName()
            and card:targetFilter(selected, target, player)
            and not player:isProhibited(target, card) then
            targets:append(target)
        end
    end
    return targets
end

mieyi = sgs.CreateTriggerSkill{
    name = "mieyi",
    events = {sgs.Damaged},
    frequency = sgs.Skill_Frequent,

    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        local ids = mieyiDamageCardIds(player)
        local card = mieyiBefriendCard(player, ids)
        if not card then return "" end
        if mieyiTargets(room, player, card):isEmpty() then return "" end
        return self:objectName()
    end,

    on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data)
        if player:isKongcheng() then return false end
        room:showAllCards(player)

        local ids = mieyiDamageCardIds(player)
        local card = mieyiBefriendCard(player, ids)
        if not card then return false end

        local targets = mieyiTargets(room, player, card)
        if targets:isEmpty() then return false end

        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@mieyi-target", false, true)
        if target then
            room:doAnimate(1, player:objectName(), target:objectName())
            room:useCard(sgs.CardUseStruct(card, player, target), false)
        end
        return false
    end
}

simayu:addSkill(mieyi)

--[[
simayue = sgs.General(extension, "simayue", "jin", 4)
simayue:setHeadMaxHpAdjustedValue(-1)

local function huluanHiddenChoices(target)
    local choices = {}
    if not target:hasShownGeneral1() then
        table.insert(choices, "head_general")
    end
    if target:getGeneral2() and not target:hasShownGeneral2() then
        table.insert(choices, "deputy_general")
    end
    return choices
end

local function huluanHasHiddenGeneral(target)
    return #huluanHiddenChoices(target) > 0
end

local function huluanGeneralName(target, choice)
    if choice == "head_general" then
        return target:getActualGeneral1Name()
    end
    return target:getActualGeneral2Name()
end

local function huluanGeneralKingdom(name)
    local general = sgs.Sanguosha:getGeneral(name)
    if general then
        return general:getKingdom()
    end
    return ""
end

local function huluanKnownNames(viewer, target)
    local names = {}
    local tag = viewer:getTag("KnownBoth_" .. target:objectName()):toString()
    if tag ~= "" then
        names = tag:split("+")
    else
        if target:hasShownGeneral1() then
            table.insert(names, target:getActualGeneral1Name())
        else
            table.insert(names, "anjiang")
        end
        if target:getGeneral2() and target:hasShownGeneral2() then
            table.insert(names, target:getActualGeneral2Name())
        else
            table.insert(names, "anjiang")
        end
    end
    return names
end

local function huluanRecordViewedGeneral(room, viewer, target, choice)
    local names = huluanKnownNames(viewer, target)
    local general_name = huluanGeneralName(target, choice)
    if choice == "head_general" then
        names[1] = general_name
    else
        names[2] = general_name
    end

    target:setMark(("KnownBoth_%s_%s"):format(viewer:objectName(), target:objectName()), 1)
    viewer:setTag("KnownBoth_" .. target:objectName(), sgs.QVariant(table.concat(names, "+")))

    local arg = {}
    table.insert(arg, "huluan")
    table.insert(arg, {general_name})
    room:doNotify(viewer, sgs.CommandType.S_COMMAND_VIEW_GENERALS, json.encode(arg))
    return general_name
end

local function huluanFindPlayer(room, object_name)
    for _, target in sgs.qlist(room:getAlivePlayers()) do
        if target:objectName() == object_name then
            return target
        end
    end
    return nil
end

huluan = sgs.CreateTriggerSkill{
    name = "huluan",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,

    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if player:getPhase() ~= sgs.Player_Start then return "" end

        for _, target in sgs.qlist(room:getAlivePlayers()) do
            if huluanHasHiddenGeneral(target) then
                return self:objectName()
            end
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        local candidates = sgs.SPlayerList()
        for _, target in sgs.qlist(room:getAlivePlayers()) do
            if huluanHasHiddenGeneral(target) then
                candidates:append(target)
            end
        end
        if candidates:isEmpty() then return false end

        local max_count = math.min(3, candidates:length())
        local chosen = room:askForPlayersChosen(player, candidates, self:objectName(), 0, max_count, "@huluan-target", true)
        if not chosen or chosen:isEmpty() then return false end

        local target_names = {}
        local general_names = {}
        for _, target in sgs.qlist(chosen) do
            local choices = huluanHiddenChoices(target)
            if #choices > 0 then
                local choice = choices[1]
                if #choices > 1 then
                    choice = room:askForChoice(player, "huluan_see", table.concat(choices, "+"), data)
                end
                local general_name = huluanRecordViewedGeneral(room, player, target, choice)
                table.insert(target_names, target:objectName())
                table.insert(general_names, general_name)
            end
        end

        if #target_names == 0 then return false end
        player:setTag("huluan_targets", sgs.QVariant(table.concat(target_names, "+")))
        player:setTag("huluan_generals", sgs.QVariant(table.concat(general_names, "+")))
        room:broadcastSkillInvoke(self:objectName(), player)
        return true
    end,

    on_effect = function(self, event, room, player, data)
        local target_tag = player:getTag("huluan_targets"):toString()
        local general_tag = player:getTag("huluan_generals"):toString()
        player:removeTag("huluan_targets")
        player:removeTag("huluan_generals")
        if target_tag == "" or general_tag == "" then return false end

        local target_names = target_tag:split("+")
        local general_names = general_tag:split("+")
        local kingdom = nil
        for _, general_name in ipairs(general_names) do
            local current = huluanGeneralKingdom(general_name)
            if current == "" then return false end
            if not kingdom then
                kingdom = current
            elseif kingdom ~= current then
                return false
            end
        end

        local choice = room:askForChoice(player, self:objectName(), "damage+draw+cancel", data)
        if choice == "cancel" then return false end

        for _, object_name in ipairs(target_names) do
            local target = huluanFindPlayer(room, object_name)
            if target and target:isAlive() then
                if choice == "damage" then
                    local damage = sgs.DamageStruct()
                    damage.from = player
                    damage.to = target
                    damage.damage = 1
                    damage.reason = self:objectName()
                    room:damage(damage)
                elseif choice == "draw" then
                    target:drawCards(2, self:objectName())
                end
            end
        end
        return false
    end
}

yinfuVS = sgs.CreateZeroCardViewAsSkill{
    name = "yinfu",
    response_or_use = true,
    view_as = function(self)
		local card_name = sgs.Self:getTag("yinfu"):toString()
		if card_name ~= "" then
			local card = sgs.Sanguosha:cloneCard(card_name)
			card:setCanRecast(false)
			card:setSkillName("yinfu")
			card:setShowSkill("yinfu")
			return card
		end
    end,
    enabled_at_play = function(self, player)
        return player:hasShownGeneral2() and not player:hasFlag("yinfu_used")
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "nullification" and player:hasShownGeneral2() and not player:hasFlag("yinfu_used")
    end,
    enabled_at_nullification = function(self, player)
        return player:hasShownGeneral2() and not player:hasFlag("yinfu_used")
    end,
	vs_card_names = function(self, selected)
		if #selected == 0 then
			return "duel+nullification"
		end
		return ""
	end,
}
yinfu = sgs.CreateTriggerSkill{
    name = "yinfu",
    events = {sgs.CardUsed},
    view_as_skill = yinfuVS,
    relate_to_place = "head",
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        local use = data:toCardUse()
        if use.card and use.card:getSkillName() == "yinfu" then
            player:hideGeneral(false)
            player:setFlags("yinfu_used")
        end
        return ""
    end
}

simayue:addSkill(huluan)
simayue:addSkill(yinfu)
]]

simajiong = sgs.General(extension, "simajiong", "wei", 3)

local function chuchongSameKingdomTargets(room, player)
    local targets = sgs.SPlayerList()
    for _, target in sgs.qlist(room:getAlivePlayers()) do
        if target:isFriendWith(player) then
            targets:append(target)
        end
    end
    return targets
end

local function chuchongRewardTarget(room, source, target, skill_name, data)
    if not (target and target:isAlive()) then return end

    if target:isWounded() then
        local recover = sgs.RecoverStruct()
        recover.who = source
        recover.recover = target:getLostHp()
        room:recover(target, recover)
    end

    if target:isAlive() and target:getHandcardNum() < 5 then
        target:drawCards(5 - target:getHandcardNum(), skill_name)
    end

    if target:isAlive() and target:canTransform() then
        local choice = room:askForChoice(target, skill_name, "transform+cancel", data)
        if choice == "transform" then
            room:transformDeputyGeneral(target)
        end
    end
end

chuchong = sgs.CreateTriggerSkill{
    name = "chuchong",
    events = {sgs.BuryVictim, sgs.DeathFinished},
    frequency = sgs.Skill_Compulsory,

    can_trigger = function(self, event, room, player, data)
        if event == sgs.BuryVictim then
            if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
            local death = data:toDeath()
            local killer = death.damage and death.damage.from
            if killer and killer:objectName() == player:objectName()
                and death.who and death.who:objectName() ~= player:objectName()
                and player:isFriendWith(death.who) then
                return self:objectName()
            end
        elseif event == sgs.DeathFinished then
            local death = data:toDeath()
            local killer = death.damage and death.damage.from
            if killer and killer:hasFlag("chuchong_skip_game_rule_reward") then
                room:setPlayerFlag(killer, "-skip_game_rule_reward")
                room:setPlayerFlag(killer, "-chuchong_skip_game_rule_reward")
            end
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data)
    end,

    on_effect = function(self, event, room, player, data)
        room:setPlayerFlag(player, "skip_game_rule_reward")
        room:setPlayerFlag(player, "chuchong_skip_game_rule_reward")
        local targets = chuchongSameKingdomTargets(room, player)
        for _, target in sgs.qlist(targets) do
            chuchongRewardTarget(room, player, target, self:objectName(), data)
        end
        return false
    end
}

local function dufuNoSameKingdomOther(room, player)
    for _, target in sgs.qlist(room:getOtherPlayers(player)) do
        if target:isAlive() and target:isFriendWith(player) then
            return false
        end
    end
    return true
end

dufu = sgs.CreateTriggerSkill{
    name = "dufu",
    events = {sgs.ConfirmDamage, sgs.DrawNCards},
    frequency = sgs.Skill_Compulsory,

    can_trigger = function(self, event, room, player, data)
        if event == sgs.ConfirmDamage then
            local damage = data:toDamage()
            local source = damage.from
            if source and source:isAlive() and source:hasSkill(self:objectName())
                and dufuNoSameKingdomOther(room, source) then
                return self:objectName()
            end
        elseif event == sgs.DrawNCards then
            if player and player:isAlive() and player:hasSkill(self:objectName())
                and dufuNoSameKingdomOther(room, player) then
                return self:objectName()
            end
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data)
    end,

    on_effect = function(self, event, room, player, data)
        if event == sgs.ConfirmDamage then
            local damage = data:toDamage()
            damage.damage = damage.damage + 1
            data:setValue(damage)
        elseif event == sgs.DrawNCards then
            local num = data:toInt()
            data:setValue(num + 2)
        end
        return false
    end
}

--simajiong:addSkill(chuchong)
simajiong:addSkill(dufu)

sgs.LoadTranslationTable{
    ["qunlanghuanding"] = "群狼环鼎",

    ["yuejin_qunlang"] = "乐进",
    ["#yuejin_qunlang"] = "奋强突固",
    ["xiaoguoQunlang"] = "骁果",
    [":xiaoguoQunlang"] = "其他角色的结束阶段开始时，你可以弃置一张手牌，对其造成1点伤害，然后其可以弃置一张装备区里的牌并回复1点体力。",
    ["@xiaoguoQunlang"] = "你可以弃置一张手牌，对 %src 造成1点伤害",
    ["@xiaoguoQunlang-discard"] = "你可以弃置一张装备区里的牌并回复1点体力",

    ["bianfuren_qunlang"] = "卞夫人",
    ["#bianfuren_qunlang"] = "武宣皇后",
    ["wanweiQunlang"] = "挽危",
    [":wanweiQunlang"] = "每回合限一次。与你势力相同的其他角色进入濒死状态时，你可以交给其至多3张牌。当其脱离濒死时，你摸等量的牌。",
    ["yuejianQunlang"] = "约俭",
    [":yuejianQunlang"] = "锁定技。与你势力相同的角色手牌上限+X（X为其已损失的体力值）。",
    ["@wanweiQunlang"] = "你可以交给 %src 至多3张牌",

    ["ganfuren_qunlang"] = "甘夫人",
    ["#ganfuren_qunlang"] = "昭烈皇思夫人",
    ["shenzhiQunlang"] = "神智",
    [":shenzhiQunlang"] = "准备阶段，你可以弃置一名角色一个区域内的最后一张牌，然后其回复1点体力。",
    ["shushenQunlang"] = "淑慎",
    [":shushenQunlang"] = "每回合各限一次。当你恢复体力时，你可以令一名其他角色摸2张牌；当你获得至少两张牌时，你可以令一名其他角色回复1点体力。",
    ["@shenzhiQunlang"] = "你可以发动“神智”，选择一名角色",
    ["@shushenQunlang-draw"] = "你可以令一名其他角色摸2张牌",
    ["@shushenQunlang-recover"] = "你可以令一名其他角色回复1点体力",
    ["hand"] = "手牌区",
    ["equip"] = "装备区",
    ["judge"] = "判定区",

    ["simawei"] = "司马玮",
    ["#simawei"] = "楚隐王",
    ["guorui"] = "果锐",
    [":guorui"] = "一张【决斗】结算后，你可以选择一项：1.对一名角色依次使用弃牌堆中此过程中打出的【杀】；2.变更副将。",
    ["@guorui-target"] = "果锐：选择一名角色，对其依次使用弃牌堆中此过程中打出的【杀】",
    ["guorui:use_slash"] = "依次使用杀",
    ["guorui:transform"] = "变更副将",
    ["guorui:cancel"] = "取消",

    ["simaying"] = "司马颖",
    ["#simaying"] = "成都王",
    ["chengguan"] = "承冠",
    [":chengguan"] = "每回合你首次受到伤害后，你可以与一名其他角色交换手牌；你非首次受到伤害后，伤害来源可以与你交换手牌。",
    ["@chengguan-target"] = "承冠：选择一名其他角色，与其交换手牌",
    ["chengguan:exchange"] = "交换手牌",
    ["chengguan:cancel"] = "取消",

    ["simayu"] = "司马颙",
    ["#simayu"] = "河间王",
    ["mieyi"] = "灭翼",
    [":mieyi"] = "当你受到伤害后，你可以展示所有手牌并将其中所有伤害牌当一张【远交近攻】使用。",
    ["@mieyi-target"] = "灭翼：选择一名角色，使用由所有伤害牌转化的【远交近攻】",

    ["simayue"] = "司马越",
    ["#simayue"] = "东海王",
    ["huluan"] = "怙乱",
    [":huluan"] = "准备阶段，你可以观看至多三名角色各一张暗置的武将牌。若这些武将牌势力均相同，你对这些角色各造成1点伤害或令这些角色各摸2张牌。",
    ["@huluan-target"] = "怙乱：选择至多三名有暗置武将牌的角色",
    ["huluan_see"] = "怙乱",
    ["huluan:damage"] = "各造成1点伤害",
    ["huluan:draw"] = "各摸2张牌",
    ["huluan:cancel"] = "取消",
    ["yinfu"] = "隐伏",
    [":yinfu"] = "主将技，-1阴阳鱼。每回合限一次。你可以暗置你的副将牌，视为使用一张【决斗】或【无懈可击】。",
    ["yinfuDuelCard"] = "隐伏",
    ["yinfuNullificationCard"] = "隐伏",

    ["simajiong"] = "司马冏",
    ["#simajiong"] = "齐武闵王",
    ["chuchong"] = "除虫",
    [":chuchong"] = "锁定技。你杀死与你势力相同的其他角色时，奖惩改为所有与你势力相同的角色依次回复所有体力、将手牌摸至5张、可以变更一次副将。",
    ["chuchong:transform"] = "变更副将",
    ["chuchong:cancel"] = "取消",
    ["dufu"] = "独夫",
    [":dufu"] = "锁定技。若场上没有与你势力相同的其他角色，你造成的伤害+1，且摸牌阶段多摸2张牌。"
}

return extension
