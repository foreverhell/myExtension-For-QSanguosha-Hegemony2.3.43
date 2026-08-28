extension = sgs.Package("hanjin", sgs.Package_GeneralPack)
local skills = sgs.SkillList()

shenpei_hanjin = sgs.General(extension, "shenpei_hanjin", "qun", 3)

local function duceUseLureTiger(room, user, opponent)
    if not (user and user:isAlive()) then return end

    local lure_tiger = sgs.Sanguosha:cloneCard("lure_tiger", sgs.Card_NoSuit, 0)
    lure_tiger:setSkillName("duce")

    if user:isCardLimited(lure_tiger, sgs.Card_MethodUse) then
        lure_tiger:deleteLater()
        return
    end

    local candidates = sgs.SPlayerList()
    local empty_targets = sgs.PlayerList()
    for _, p in sgs.qlist(room:getOtherPlayers(user)) do
        if p:objectName() ~= opponent:objectName()
            and lure_tiger:targetFilter(empty_targets, p, user)
            and not user:isProhibited(p, lure_tiger) then
            candidates:append(p)
        end
    end

    if not candidates:isEmpty() then
        local max_num = math.min(2, candidates:length())
        local targets = room:askForPlayersChosen(user, candidates, "duce", 1, max_num,
            "@duce-lure:" .. opponent:objectName())
        local use = sgs.CardUseStruct()
        use.card = lure_tiger
        use.from = user
        for _, p in sgs.qlist(targets) do
            use.to:append(p)
        end
        room:useCard(use)
    end

    lure_tiger:deleteLater()
end

local function duceUseArcheryAttack(room, user)
    if not (user and user:isAlive()) then return end

    local archery_attack = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_NoSuit, 0)
    archery_attack:setSkillName("duce")
    if user:isCardLimited(archery_attack, sgs.Card_MethodUse) then
        archery_attack:deleteLater()
        return
    end
    local use = sgs.CardUseStruct()
    use.card = archery_attack
    use.from = user
    room:useCard(use)
    archery_attack:deleteLater()
end

duce = sgs.CreateTriggerSkill{
    name = "duce",
    events = {sgs.EventPhaseStart, sgs.Pindian},
    frequency = sgs.Skill_NotFrequent,

    can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart then
            if not (player and player:isAlive() and player:hasSkill(self:objectName())
                and player:getPhase() == sgs.Player_Start and not player:isKongcheng()) then
                return ""
            end

            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if not p:isKongcheng() then
                    return self:objectName()
                end
            end
        elseif event == sgs.Pindian then
            local pindian = data:toPindian()
            if pindian.reason == self:objectName() then
                return self:objectName()
            end
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        if event == sgs.Pindian then return true end

        local candidates = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if not p:isKongcheng() then
                candidates:append(p)
            end
        end
        local target = room:askForPlayerChosen(player, candidates, self:objectName(), "@duce-pindian", true, true)
        if not target then return false end

        room:setPlayerProperty(player, "duce_target", sgs.QVariant(target:objectName()))
        room:broadcastSkillInvoke(self:objectName(), player)
        return true
    end,

    on_effect = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart then
            local target_name = player:property("duce_target"):toString()
            room:setPlayerProperty(player, "duce_target", sgs.QVariant(""))
            local target = nil
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:objectName() == target_name then
                    target = p
                    break
                end
            end
            if target and target:isAlive() and not player:isKongcheng() and not target:isKongcheng() then
                player:pindian(target,self:objectName())
            end
            return false
        end

        local pindian = data:toPindian()
        local from = pindian.from
        local to = pindian.to
        if pindian.from_number > pindian.to_number then
            duceUseLureTiger(room, to, from)
            duceUseArcheryAttack(room, from)
        elseif pindian.from_number < pindian.to_number then
            duceUseLureTiger(room, from, to)
            duceUseArcheryAttack(room, to)
        else
            duceUseLureTiger(room, from, to)
            duceUseLureTiger(room, to, from)
        end
        return false
    end,
}

shuairanSummonCard = sgs.CreateArraySummonCard{
    name = "shuairan",
    mute = true,
}

shuairanVS = sgs.CreateArraySummonSkill{
    name = "shuairan",
    array_summon_card = shuairanSummonCard,
}

shuairan = sgs.CreateTriggerSkill{
    name = "shuairan",
    is_battle_array = true,
    battle_array_type = sgs.Formation,
    view_as_skill = shuairanVS,
    can_preshow = false,
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart, sgs.GeneralShown, sgs.GeneralHidden, sgs.GeneralRemoved,
        sgs.DFDebut, sgs.Death, sgs.EventAcquireSkill, sgs.EventLoseSkill,
        sgs.RemoveStateChanged},

    can_trigger = function(self, event, room, player, data)
        local skill_list = {}
        local owner_list = {}

        for _, owner in sgs.qlist(room:getAllPlayers()) do
            if owner:hasSkill(self:objectName()) then
                local old_count = owner:getMark("shuairan_formation_count")
                local new_count = owner:isAlive() and owner:getFormation():length() or 0
                room:setPlayerMark(owner, "shuairan_formation_count", new_count)

                if event ~= sgs.GameStart and owner:isAlive()
                    and owner:hasShownSkill(self:objectName())
                    and room:alivePlayerCount() >= 4 and old_count > 0
                    and new_count ~= old_count then
                    room:setPlayerMark(owner, "shuairan_change", new_count > old_count and 1 or -1)
                    table.insert(skill_list, self:objectName())
                    table.insert(owner_list, owner:objectName())
                end
            end
        end

        return table.concat(skill_list, "|"), table.concat(owner_list, "|")
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        room:sendCompulsoryTriggerLog(ask_who, self:objectName())
        room:broadcastSkillInvoke(self:objectName(), ask_who)
        room:doBattleArrayAnimate(ask_who)
        return true
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        local change = ask_who:getMark("shuairan_change")
        room:setPlayerMark(ask_who, "shuairan_change", 0)

        local formation = ask_who:getFormation()
        if change > 0 then
            for _, p in sgs.qlist(formation) do
                if p:isAlive() then room:drawCards(p, 1, self:objectName()) end
            end
        elseif change < 0 then
            for _, p in sgs.qlist(formation) do
                if p:isAlive() then
                    local recover = sgs.RecoverStruct()
                    recover.who = ask_who
                    recover.recover = 1
                    room:recover(p, recover)
                end
            end
        end
        return false
    end,
}

zhanglu_hanjin = sgs.General(extension, "zhanglu_hanjin", "qun", 3)

mijiaoCard = sgs.CreateSkillCard{
    name = "mijiaoCard",
    skill_name = "mijiao",
    target_fixed = false,
    will_throw = false,

    filter = function(self, targets, to_select, source)
        return #targets == 0 and to_select:objectName() ~= source:objectName()
            and math.abs(to_select:getHandcardNum() - source:getHandcardNum()) <= 2
    end,

    on_use = function(self, room, source, targets)
        local target = targets[1]
        if not (target and target:isAlive()) then return end

        local source_num = source:getHandcardNum()
        local target_num = target:getHandcardNum()
        if target_num < source_num then
            target:drawCards(source_num - target_num, "mijiao")
            if source:isAlive() and target:isAlive()
                and source:askForSkillInvoke("mijiao_damage",
                    sgs.QVariant("damage:" .. target:objectName())) then
                local damage = sgs.DamageStruct()
                damage.from = source
                damage.to = target
                damage.damage = 1
                damage.reason = "mijiao"
                room:damage(damage)
            end
        elseif target_num > source_num then
            room:askForDiscard(target, "mijiao", target_num - source_num,
                target_num - source_num, false, false)
            if source:isAlive() and target:isAlive() and target:isWounded()
                and source:askForSkillInvoke("mijiao_recover",
                    sgs.QVariant("recover:" .. target:objectName())) then
                local recover = sgs.RecoverStruct()
                recover.who = source
                recover.recover = 1
                room:recover(target, recover)
            end
        end
    end,
}

mijiao = sgs.CreateZeroCardViewAsSkill{
    name = "mijiao",
    view_as = function(self)
        local card = mijiaoCard:clone()
        card:setShowSkill(self:objectName())
        return card
    end,
    enabled_at_play = function(self, player)
        if player:hasUsed("#mijiaoCard") then return false end
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if math.abs(p:getHandcardNum() - player:getHandcardNum()) <= 2 then
                return true
            end
        end
        return false
    end,
}

local function guianBigKingdomSignature(player)
    local kingdoms = player:getBigKingdoms("guian", sgs.Max)
    local names = {}
    for i = 1, #kingdoms do
        table.insert(names, tostring(kingdoms[i]))
    end
    table.sort(names)
    return table.concat(names, "+")
end

guian = sgs.CreateTriggerSkill{
    name = "guian",
    frequency = sgs.Skill_Frequent,
    events = {sgs.GameStart, sgs.GeneralShown, sgs.GeneralHidden, sgs.GeneralRemoved,
        sgs.DFDebut, sgs.Death, sgs.CardsMoveOneTime, sgs.EventAcquireSkill,
        sgs.EventLoseSkill, sgs.RemoveStateChanged},

    can_trigger = function(self, event, room, player, data)
        local skill_list = {}
        local owner_list = {}
        for _, owner in sgs.qlist(room:getAllPlayers()) do
            if owner:hasSkill(self:objectName()) then
                local tag_name = "guian_big_kingdoms_" .. owner:objectName()
                local init_name = "guian_big_kingdoms_initialized_" .. owner:objectName()
                local initialized = room:getTag(init_name):toBool()
                local old_signature = room:getTag(tag_name):toString()
                local new_signature = guianBigKingdomSignature(owner)
                room:setTag(tag_name, sgs.QVariant(new_signature))
                room:setTag(init_name, sgs.QVariant(true))

                if event ~= sgs.GameStart and initialized
                    and old_signature ~= new_signature and owner:isAlive()
                    and owner:hasShownSkill(self:objectName()) then
                    table.insert(skill_list, self:objectName())
                    table.insert(owner_list, owner:objectName())
                end
            end
        end
        return table.concat(skill_list, "|"), table.concat(owner_list, "|")
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        local targets = room:askForPlayersChosen(ask_who, room:getAlivePlayers(),
            self:objectName(), 1, 2, "@guian-choose")
        if targets:isEmpty() then return false end

        for _, p in sgs.qlist(targets) do
            room:setPlayerMark(p, "guian_target_" .. ask_who:objectName(), 1)
        end
        room:broadcastSkillInvoke(self:objectName(), ask_who)
        return true
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        local mark_name = "guian_target_" .. ask_who:objectName()
        for _, p in sgs.qlist(room:getAllPlayers()) do
            if p:getMark(mark_name) > 0 then
                room:setPlayerMark(p, mark_name, 0)
                if p:isAlive() then
                    room:drawCards(p, 1, self:objectName())
                end
            end
        end
        return false
    end,
}

huoyi_hanjin = sgs.General(extension, "huoyi_hanjin", "shu", 4)

sijuVS = sgs.CreateZeroCardViewAsSkill{
    name = "siju",
    guhuo_type = "t",
    view_as = function(self)
        local card_name = sgs.Self:getTag(self:objectName()):toString()
        if card_name == "" then return nil end

        local card = sgs.Sanguosha:cloneCard(card_name, sgs.Card_NoSuit, 0)
        if not card then return nil end
        card:setCanRecast(false)
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card
    end,

    enabled_at_play = function(self, player)
        return player:faceUp()
    end,
    vs_card_names = function(self, selected)
        if #selected > 0 then return "" end
        return "duel+fire_attack+savage_assault+archery_attack+burning_camps+drowning"
    end,
}

siju = sgs.CreateTriggerSkill{
    name = "siju",
    view_as_skill = sijuVS,
    events = {sgs.PreCardUsed},
    frequency = sgs.Skill_Frequent,

    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then
            return ""
        end
        local use = data:toCardUse()
        if use.card and use.card:getSkillName() == self:objectName() and player:faceUp() then
            return self:objectName()
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        return true
    end,

    on_effect = function(self, event, room, player, data)
        player:turnOver()

        local has_friend = false
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if player:willBeFriendWith(p) then
                has_friend = true
                break
            end
        end
        if not has_friend then
            local use = data:toCardUse()
            use.card:setFlags("GlobalCardUseDisresponsive")
            data:setValue(use)
        end
        return false
    end,
}

zhongjue = sgs.CreateTriggerSkill{
    name = "zhongjue",
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_Compulsory,

    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())
            and (player:isChained() or not player:faceUp())) then
            return ""
        end
        if player:isNude() then return "" end
        local damage = data:toDamage()
        if damage.damage > 0 then return self:objectName() end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        if not player:hasShownSkill(self:objectName())
            and not player:askForSkillInvoke(self:objectName(), data) then
            return false
        end
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:broadcastSkillInvoke(self:objectName(), player)
        return true
    end,

    on_effect = function(self, event, room, player, data)
        local damage = data:toDamage()
        local max_num = math.min(damage.damage, player:getCards("he"):length())
        if max_num > 0 then
            local card_ids = room:askForExchange(player, self:objectName(), max_num, 1,
                "@zhongjue-discard:::" .. tostring(damage.damage), "", ".|.|.|hand,equipped")
            if not card_ids:isEmpty() then
                local dummy = sgs.DummyCard(card_ids)
                room:throwCard(dummy, player, player, self:objectName())
                dummy:deleteLater()

                damage.damage = damage.damage - card_ids:length()
                data:setValue(damage)
            end
        end

        if player:isAlive() and (player:isKongcheng() or player:getHp() == 1) then
            if player:isChained() then
                room:setPlayerProperty(player, "chained", sgs.QVariant(false))
            end
            if not player:faceUp() then
                player:turnOver()
            end
        end

        return damage.damage <= 0
    end,
}

liuba_hanjin = sgs.General(extension, "liuba_hanjin", "shu", 3)

local function liuzhuanDiamondDiscards(room, data)
    local card_ids = sgs.IntList()
    local move_datas = data:toList()
    for _, move_data in sgs.qlist(move_datas) do
        local move = move_data:toMoveOneTime()
        local basic_reason = bit32.band(move.reason.m_reason,
            sgs.CardMoveReason_S_MASK_BASIC_REASON)
        if move.to_place == sgs.Player_DiscardPile
            and basic_reason == sgs.CardMoveReason_S_REASON_DISCARD then
            for _, card_id in sgs.qlist(move.card_ids) do
                local card = sgs.Sanguosha:getCard(card_id)
                if card and card:getSuit() == sgs.Card_Diamond
                    and room:getCardPlace(card_id) == sgs.Player_DiscardPile then
                    card_ids:append(card_id)
                end
            end
        end
    end
    return card_ids
end

liuzhuan = sgs.CreateTriggerSkill{
    name = "liuzhuan",
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,

    can_trigger = function(self, event, room, player, data)
        local skill_list = {}
        local owner_list = {}

        if event == sgs.CardsMoveOneTime then
            if liuzhuanDiamondDiscards(room, data):isEmpty() then return "" end
            for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if owner:isAlive() then
                    table.insert(skill_list, self:objectName())
                    table.insert(owner_list, owner:objectName())
                end
            end
        elseif player and player:isAlive() and player:getPhase() == sgs.Player_Finish
            and player:hasSkill(self:objectName()) and not player:getPile("coin"):isEmpty() then
            return self:objectName()
        end

        return table.concat(skill_list, "|"), table.concat(owner_list, "|")
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        if event == sgs.CardsMoveOneTime then
            if ask_who:askForSkillInvoke(self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName(), ask_who)
                return true
            end
            return false
        end

        room:sendCompulsoryTriggerLog(ask_who, self:objectName())
        room:broadcastSkillInvoke(self:objectName(), ask_who)
        return true
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        if event == sgs.CardsMoveOneTime then
            local card_ids = liuzhuanDiamondDiscards(room, data)
            if not card_ids:isEmpty() then
                ask_who:addToPile("coin", card_ids, true)
            end
            return false
        end

        local coin_num = ask_who:getPile("coin"):length()
        if coin_num < 1 then return false end
        ask_who:clearOnePrivatePile("coin")

        local ex_nihilo = sgs.Sanguosha:cloneCard("ex_nihilo", sgs.Card_NoSuit, 0)
        ex_nihilo:setSkillName(self:objectName())

        if ask_who:isCardLimited(ex_nihilo, sgs.Card_MethodUse) then
            ex_nihilo:deleteLater()
            return false
        end

        local candidates = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if not ask_who:isProhibited(p, ex_nihilo) then
                candidates:append(p)
            end
        end

        if not candidates:isEmpty() then
            local max_num = math.min(coin_num, candidates:length())
            local targets = room:askForPlayersChosen(ask_who, candidates,
                self:objectName(), 1, max_num, "@liuzhuan-use:::" .. tostring(coin_num), false)
            local use = sgs.CardUseStruct()
            use.card = ex_nihilo
            use.from = ask_who
            for _, p in sgs.qlist(targets) do
                use.to:append(p)
            end
            room:useCard(use)
        end
        ex_nihilo:deleteLater()
        return false
    end,
}

langji = sgs.CreateTriggerSkill{
    name = "langji",
    events = {sgs.CardUsed},

    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasShownSkill(self:objectName())) then
            return ""
        end
        local use = data:toCardUse()
        if use.to:contains(player) then
            room:setPlayerFlag(player, "ji")--成为牌的目标，添加标记
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        return false
    end,

    on_effect = function(self, event, room, player, data)
        return false
    end
}

langjiMod = sgs.CreateDistanceSkill{
    name = "#langji-distance",
    correct_func = function(self, from, to)
        if from:hasShownSkill("langji") and not from:hasFlag("ji") then
			return 1
		end
        if to:hasShownSkill("langji") and not to:hasFlag("ji") then
			return 1
		end
        return 0
	end
}

sunlang_hanjin = sgs.General(extension, "sunlang_hanjin", "shu", 4)

local function juyiIsDamageTrick(card)
    if not (card and card:isKindOf("TrickCard") and not card:isKindOf("DelayedTrick")) then
        return false
    end
    local damage_tricks = {
        "Duel", "ArcheryAttack", "SavageAssault",
        "BurningCamps", "Drowning", "FireAttack"
    }
    for _, class_name in ipairs(damage_tricks) do
        if card:isKindOf(class_name) then return true end
    end
    return false
end

juyi = sgs.CreateTriggerSkill{
    name = "juyi",
    events = {sgs.TargetConfirming},
    frequency = sgs.Skill_NotFrequent,

    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive()) then return "" end
        local use = data:toCardUse()
        if not (use.card and juyiIsDamageTrick(use.card) and use.to:contains(player)) then
            return ""
        end

        local skill_list = {}
        local owner_list = {}
        for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if owner:isAlive() and (owner:objectName() == player:objectName()
                or player:getHp() == 1) then
                table.insert(skill_list, self:objectName())
                table.insert(owner_list, owner:objectName())
            end
        end
        return table.concat(skill_list, "|"), table.concat(owner_list, "|")
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        local use = data:toCardUse()
        if not use.to:contains(player) then return false end
        if ask_who:askForSkillInvoke(self:objectName(),
            sgs.QVariant("invoke:" .. player:objectName() .. ":" .. use.card:objectName())) then
            room:broadcastSkillInvoke(self:objectName(), ask_who)
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        local use = data:toCardUse()
        if not use.to:contains(player) then return false end

        sgs.Room_cancelTarget(use, player)
        data:setValue(use)

        local choices = {"juyi_losehp"}
        if use.from and use.from:isAlive()
            and use.from:objectName() ~= ask_who:objectName()
            and ask_who:canSlash(use.from, nil, false) then --false表示无距离限制
            table.insert(choices, 1, "juyi_slash")
        end

        local choice = room:askForChoice(ask_who, self:objectName(),
            table.concat(choices, "+"), data)
        if choice == "juyi_slash" then
            local slash = room:askForUseSlashTo(ask_who, use.from,
                "@juyi-slash:" .. use.from:objectName(), false, false, false)--是否距离限制，是否禁止额外目标，是否计入次数
            if not slash and ask_who:isAlive() then
                room:loseHp(ask_who, 1)
            end
        elseif ask_who:isAlive() then
            room:loseHp(ask_who, 1)
        end
        return false
    end,
}

yingshou = sgs.CreateOneCardViewAsSkill{  
    name = "yingshou",  
    filter_pattern = "TrickCard|heart|.|.",  --red heart trick cards
    view_as = function(self, card)  
        local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())  
        slash:addSubcard(card:getId())  
        slash:setSkillName(self:objectName())  
        slash:setShowSkill(self:objectName())  
        return slash  
    end  
}

xiahoulan_hanjin = sgs.General(extension, "xiahoulan_hanjin", "shu", 3, false)

local function lanqieDiscardedCards(room, data, owner)
    local card_ids = sgs.IntList()
    for _, move_data in sgs.qlist(data:toList()) do
        local move = move_data:toMoveOneTime()
        local basic_reason = bit32.band(move.reason.m_reason,
            sgs.CardMoveReason_S_MASK_BASIC_REASON)
        if move.to_place == sgs.Player_DiscardPile
            and basic_reason == sgs.CardMoveReason_S_REASON_DISCARD
            and move.reason.m_playerId == owner:objectName() then
            for _, card_id in sgs.qlist(move.card_ids) do
                if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
                    card_ids:append(card_id)
                end
            end
        end
    end
    return card_ids
end

lanqie = sgs.CreateTriggerSkill{
    name = "lanqie",
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseChanging, sgs.EventPhaseStart,
        sgs.CardUsed, sgs.Damage, sgs.CardFinished},
    frequency = sgs.Skill_Frequent,

    on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player and player:isAlive()
            and player:getPhase() == sgs.Player_RoundStart
            and player:hasSkill(self:objectName()) then
            room:setPlayerMark(player, "lanqie_disabled", 0)
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.from and use.card and use.card:getSkillName() == self:objectName() then
                local serial = use.from:getMark("lanqie_serial") + 1
                room:setPlayerMark(use.from, "lanqie_serial", serial)
                use.card:setTag("lanqie_serial", sgs.QVariant(serial))
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.from and damage.to and damage.card
                and damage.card:getSkillName() == self:objectName() then
                local serial = damage.card:getTag("lanqie_serial"):toInt()
                if serial > 0 then
                    room:setPlayerMark(damage.to,
                        "lanqie_damaged_" .. damage.from:objectName() .. "_" .. tostring(serial), 1)
                end
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if event == sgs.CardsMoveOneTime then
            local skill_list = {}
            local owner_list = {}
            for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if owner:isAlive() and owner:getMark("lanqie_disabled") == 0
                    and not lanqieDiscardedCards(room, data, owner):isEmpty() then
                    table.insert(skill_list, self:objectName())
                    table.insert(owner_list, owner:objectName())
                end
            end
            return table.concat(skill_list, "|"), table.concat(owner_list, "|")
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to ~= sgs.Player_NotActive then return "" end
            local skill_list = {}
            local owner_list = {}
            for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if owner:isAlive() and owner:getMark("lanqie_disabled") == 0
                    and not owner:getPile("storm"):isEmpty() then
                    table.insert(skill_list, self:objectName())
                    table.insert(owner_list, owner:objectName())
                end
            end
            return table.concat(skill_list, "|"), table.concat(owner_list, "|")
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.from and use.from:isAlive() and use.card
                and use.card:getSkillName() == self:objectName() then
                return self:objectName(), use.from:objectName()
            end
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        if event == sgs.CardsMoveOneTime then
            if ask_who:askForSkillInvoke(self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName(), ask_who)
                return true
            end
            return false
        end
        return true
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        if event == sgs.CardsMoveOneTime then
            local card_ids = lanqieDiscardedCards(room, data, ask_who)
            if not card_ids:isEmpty() then
                ask_who:addToPile("storm", card_ids, true)
            end
            return false
        elseif event == sgs.EventPhaseChanging then
            local pile = ask_who:getPile("storm")
            if pile:isEmpty() then return false end

            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
            slash:setSkillName(self:objectName())
            for _, card_id in sgs.qlist(pile) do
                slash:addSubcard(card_id)
            end

            local candidates = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(ask_who)) do
                if ask_who:canSlash(p, slash, true) then
                    candidates:append(p)
                end
            end
            if not candidates:isEmpty() then
                local max_num = math.min(pile:length(), candidates:length())
                local targets = room:askForPlayersChosen(ask_who, candidates,
                    self:objectName(), 1, max_num,
                    "@lanqie-slash:::" .. tostring(pile:length()), false)
                local use = sgs.CardUseStruct()
                use.card = slash
                use.from = ask_who
                for _, p in sgs.qlist(targets) do
                    use.to:append(p)
                end
                room:useCard(use, false)
            end
            slash:deleteLater()
            return false
        end

        local use = data:toCardUse()
        local serial = use.card:getTag("lanqie_serial"):toInt()
        local all_damaged = serial > 0 and not use.to:isEmpty()
        for _, p in sgs.qlist(use.to) do
            local damage_mark = "lanqie_damaged_" .. ask_who:objectName()
                .. "_" .. tostring(serial)
            if p:getMark(damage_mark) == 0 then all_damaged = false end
            room:setPlayerMark(p, damage_mark, 0)
        end
        if all_damaged then
            room:setPlayerMark(ask_who, "lanqie_disabled", 1)
        end

        local available_ids = sgs.IntList()
        for _, card_id in sgs.qlist(use.card:getSubcards()) do
            if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
                available_ids:append(card_id)
            end
        end
        local recipients = room:getOtherPlayers(ask_who)
        if ask_who:isAlive() and not available_ids:isEmpty() and not recipients:isEmpty()
            and ask_who:askForSkillInvoke("lanqie_give", data) then
            for _, card_id in sgs.qlist(available_ids) do
                if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
                    local target = room:askForPlayerChosen(ask_who, recipients,
                        "lanqie_give", "@lanqie-give:::" ..
                        sgs.Sanguosha:getCard(card_id):objectName(), false, false)
                    room:obtainCard(target, card_id, true)
                end
            end
        end
        return false
    end,
}

jinqi = sgs.CreateTriggerSkill{
    name = "jinqi",
    events = {sgs.GameStart},
    frequency = sgs.Skill_Compulsory,

    can_trigger = function(self, event, room, player, data)
        if not (player and player:hasSkill(self:objectName())
            and player:getMark("jinqi_maxhp") == 0) then
            return ""
        end

        local head = player:getActualGeneral1()
        local deputy = player:getActualGeneral2()
        local other = nil
        if head and head:ownSkill(self:objectName()) then
            other = deputy
        elseif deputy and deputy:ownSkill(self:objectName()) then
            other = head
        end
        if other and other:isFemale() then
            room:setPlayerMark(player, "jinqi_maxhp", 1)
            room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
            room:setPlayerProperty(player, "hp", sgs.QVariant(player:getHp() + 1))
        end
        return ""
    end,
}

zulang_hanjin = sgs.General(extension, "zulang_hanjin", "qun", 4)

raoxi = sgs.CreateTriggerSkill{
    name = "raoxi",
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart, sgs.EventPhaseEnd},
    frequency = sgs.Skill_NotFrequent,

    on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player
            and player:getPhase() == sgs.Player_RoundStart then
            if player:hasSkill(self:objectName()) then
                room:setPlayerMark(player, "raoxi_used_round", 0)
            end
        elseif event == sgs.CardsMoveOneTime then
            local current = room:getCurrent()
            if not (current and current:getPhase() ~= sgs.Player_NotActive) then return end

            for _, move_data in sgs.qlist(data:toList()) do
                local move = move_data:toMoveOneTime()
                if move.from and (move.from_places:contains(sgs.Player_PlaceHand)
                    or move.from_places:contains(sgs.Player_PlaceEquip)) then
                    for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                        if move.from:objectName() == owner:objectName() then
                            room:setPlayerFlag(owner, "raoxi_lost_turn")
                        end
                    end
                end
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if not (event == sgs.EventPhaseEnd and player and player:isAlive()
            and player:getPhase() == sgs.Player_Finish) then
            return ""
        end

        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        slash:setSkillName(self:objectName())
        local skill_list = {}
        local owner_list = {}
        for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if owner:isAlive() and owner:objectName() ~= player:objectName()
                and not owner:hasFlag("raoxi_lost_turn")
                and owner:getMark("raoxi_used_round") < 2
                and not owner:isCardLimited(slash, sgs.Card_MethodUse)
                and owner:canSlash(player, slash, false)
                and not owner:isProhibited(player, slash) then
                table.insert(skill_list, self:objectName())
                table.insert(owner_list, owner:objectName())
            end
        end
        slash:deleteLater()
        return table.concat(skill_list, "|"), table.concat(owner_list, "|")
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        if ask_who:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), ask_who)
            room:addPlayerMark(ask_who, "raoxi_used_round")
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        if not (ask_who:isAlive() and player:isAlive()) then return false end

        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        slash:setSkillName(self:objectName())
        if not ask_who:isCardLimited(slash, sgs.Card_MethodUse)
            and ask_who:canSlash(player, slash, false)
            and not ask_who:isProhibited(player, slash) then
            local use = sgs.CardUseStruct()
            use.card = slash
            use.from = ask_who
            use.to:append(player)
            room:useCard(use, false)
        end
        slash:deleteLater()
        return false
    end,
}

jiangji_hanjin = sgs.General(extension, "jiangji_hanjin", "wei", 3)

xuxieVS = sgs.CreateOneCardViewAsSkill{
    name = "xuxie",
    filter_pattern = ".|.|.|hand,equipped",
    response_pattern = "nullification",
    response_or_use = true,

    view_as = function(self, card)
        local nullification = sgs.Sanguosha:cloneCard("nullification",
            card:getSuit(), card:getNumber())
        nullification:addSubcard(card:getId())
        nullification:setSkillName(self:objectName())
        nullification:setShowSkill(self:objectName())
        return nullification
    end,

    enabled_at_play = function(self, player)
        return false
    end,

    enabled_at_response = function(self, player, pattern)
        return pattern == "nullification" and player:getMark("xuxie_used_round") == 0
    end,

    enabled_at_nullification = function(self, player)
        return player:getMark("xuxie_used_round") == 0 and not player:isNude()
    end,
}

xuxie = sgs.CreateTriggerSkill{
    name = "xuxie",
    events = {sgs.CardUsed, sgs.CardFinished, sgs.EventPhaseStart},
    view_as_skill = xuxieVS,
    frequency = sgs.Skill_Frequent,

    on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player and player:hasSkill(self:objectName())
            and player:getPhase() == sgs.Player_RoundStart then
            room:setPlayerMark(player, "xuxie_used_round", 0)
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then
            return ""
        end
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Nullification")
                and use.card:getSkillName() == self:objectName()
                and not room:getOtherPlayers(player):isEmpty() then
                return self:objectName()
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Nullification")
                and use.card:getSkillName() == self:objectName()
                and use.card:getTag("xuxie_target"):toString() ~= "" then
                return self:objectName()
            end
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        if event == sgs.CardFinished then return true end

        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player),
            self:objectName(), "@xuxie-give", false, false)
        if not target then return false end
        local use = data:toCardUse()
        use.card:setTag("xuxie_target", sgs.QVariant(target:objectName()))
        room:broadcastSkillInvoke(self:objectName(), player)
        return true
    end,

    on_effect = function(self, event, room, player, data)
        local use = data:toCardUse()
        if event == sgs.CardUsed then
            room:addPlayerMark(player, "xuxie_used_round")
            local target = room:findPlayer(use.card:getTag("xuxie_target"):toString())
            if not (target and target:isAlive()) then return false end

            local pattern = nil
            if use.card:isRed() then
                pattern = ".|red"
            elseif use.card:isBlack() then
                pattern = ".|black"
            end
            if pattern then
                room:setPlayerCardLimitation(player, "use", pattern, true)
                room:setPlayerCardLimitation(target, "use", pattern, true)
            end
            return false
        end

        local target = room:findPlayer(use.card:getTag("xuxie_target"):toString())
        if not (target and target:isAlive()) then return false end
        local card_ids = sgs.IntList()
        for _, card_id in sgs.qlist(use.card:getSubcards()) do
            if room:getCardPlace(card_id) == sgs.Player_DiscardPile
                or room:getCardPlace(card_id) == sgs.Player_PlaceTable then
                card_ids:append(card_id)
            end
        end
        if not card_ids:isEmpty() then
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,
                player:objectName(), target:objectName(), self:objectName(), "")
            local move = sgs.CardsMoveStruct(card_ids, target, sgs.Player_PlaceHand, reason)
            room:moveCardsAtomic(move, true)
        end
        return false
    end,
}

local function liuluTarget(event, data, owner)
    if event == sgs.Damaged then
        local damage = data:toDamage()
        if damage.to and damage.to:objectName() == owner:objectName()
            and damage.from and damage.from:isAlive()
            and damage.from:objectName() ~= owner:objectName() then
            return damage.from
        end
        return nil
    end

    for _, move_data in sgs.qlist(data:toList()) do
        local move = move_data:toMoveOneTime()
        if move.to and move.to:isAlive()
            and move.to:objectName() ~= owner:objectName()
            and (move.to_place == sgs.Player_PlaceHand
                or move.to_place == sgs.Player_PlaceEquip) then
            local directly_from_owner = move.from
                and move.from:objectName() == owner:objectName()
            local given_by_xuxie = move.reason.m_skillName == "xuxie"
                and move.reason.m_playerId == owner:objectName()
            if directly_from_owner or given_by_xuxie then
                return move.to
            end
        end
    end
    return nil
end

liulu = sgs.CreateTriggerSkill{
    name = "liulu",
    events = {sgs.Damaged, sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Frequent,

    can_trigger = function(self, event, room, player, data)
        local skill_list = {}
        local owner_list = {}
        for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if owner:isAlive() and liuluTarget(event, data, owner) then
                table.insert(skill_list, self:objectName())
                table.insert(owner_list, owner:objectName())
            end
        end
        return table.concat(skill_list, "|"), table.concat(owner_list, "|")
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        local target = liuluTarget(event, data, ask_who)
        if not target then return false end
        ask_who:setTag("liulu_target", sgs.QVariant(target:objectName()))
        if ask_who:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), ask_who)
            return true
        end
        ask_who:removeTag("liulu_target")
        return false
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        local target = room:findPlayer(ask_who:getTag("liulu_target"):toString())
        ask_who:removeTag("liulu_target")
        if not (target and target:isAlive()) then return false end

        target:drawCards(1, self:objectName())
        if ask_who:isAlive() and target:isAlive() and not target:isNude() then
            local card_id = room:askForCardChosen(ask_who, target, "he",
                self:objectName(), false, sgs.Card_MethodNone)
            room:obtainCard(ask_who, card_id, false)
        end
        return false
    end,
}

chengpu_hanjin = sgs.General(extension, "chengpu_hanjin", "wu", 4)

lihuoVS = sgs.CreateViewAsSkill{
    name = "lihuo",
    n = 2,

    view_filter = function(self, selected, to_select)
        return #selected < 2 and not sgs.Self:isJilei(to_select)
    end,

    view_as = function(self, cards)
        if #cards ~= 2 then return nil end
        local fire_slash = sgs.Sanguosha:cloneCard("fire_slash",
            sgs.Card_SuitToBeDecided, -1)
        for _, card in ipairs(cards) do
            fire_slash:addSubcard(card)
        end
        fire_slash:setSkillName(self:objectName())
        fire_slash:setShowSkill(self:objectName())
        return fire_slash
    end,

    enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player) and player:getCardCount(true) >= 2
    end,
}

lihuo = sgs.CreateTriggerSkill{
    name = "lihuo",
    events = {sgs.CardUsed, sgs.Damage, sgs.CardFinished},
    view_as_skill = lihuoVS,
    frequency = sgs.Skill_Frequent,

    on_record = function(self, event, room, player, data)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("FireSlash")
                and use.card:getSkillName() == self:objectName() then
                use.card:setTag("lihuo_damage", sgs.QVariant(0))
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("FireSlash")
                and damage.card:getSkillName() == self:objectName() then
                local total = damage.card:getTag("lihuo_damage"):toInt()
                damage.card:setTag("lihuo_damage", sgs.QVariant(total + damage.damage))
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if not (event == sgs.CardFinished and player and player:isAlive()
            and player:hasSkill(self:objectName())) then
            return ""
        end
        local use = data:toCardUse()
        if not (use.card and use.card:isKindOf("FireSlash")
            and use.card:getSkillName() == self:objectName()
            and use.card:getTag("lihuo_damage"):toInt() > 1) then
            return ""
        end
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if player:isFriendWith(p) then return self:objectName() end
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        local candidates = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if player:isFriendWith(p) then candidates:append(p) end
        end
        if candidates:isEmpty() then return false end

        local target = room:askForPlayerChosen(player, candidates, self:objectName(),
            "@lihuo-yinyang", true, true)
        if not target then return false end
        player:setTag("lihuo_target", sgs.QVariant(target:objectName()))
        room:broadcastSkillInvoke(self:objectName(), player)
        return true
    end,

    on_effect = function(self, event, room, player, data)
        local target = room:findPlayer(player:getTag("lihuo_target"):toString())
        player:removeTag("lihuo_target")
        if not (target and target:isAlive()) then return false end
        room:addPlayerMark(player, "@halfmaxhp")
        room:addPlayerMark(target, "@halfmaxhp")
        return false
    end,
}

lihuoMod = sgs.CreateTargetModSkill{
    name = "#lihuo-target",
    pattern = "Slash",

    extra_target_func = function(self, player, card)
        if card and card:getSkillName() == "lihuo" then return 1 end
        return 0
    end,
}

chunlaoAttachVS = sgs.CreateZeroCardViewAsSkill{
    name = "chunlao_attach",
    response_pattern = "analeptic",

    view_as = function(self)
        local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
        analeptic:setSkillName(self:objectName())
        return analeptic
    end,

    enabled_at_play = function(self, player)
        return player:getMark("@halfmaxhp") > 0 and sgs.Analeptic_IsAvailable(player)
    end,

    enabled_at_response = function(self, player, pattern)
        return player:getMark("@halfmaxhp") > 0
            and string.find(pattern, "analeptic") ~= nil
    end,
}

chunlaoAttach = sgs.CreateTriggerSkill{
    name = "chunlao_attach",
    events = {sgs.PreCardUsed},
    view_as_skill = chunlaoAttachVS,

    on_record = function(self, event, room, player, data)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf("Analeptic")
            and use.card:getSkillName() == self:objectName()
            and player:getMark("@halfmaxhp") > 0 then
            room:removePlayerMark(player, "@halfmaxhp")
        end
    end,

    can_trigger = function(self, event, room, player, data)
        return ""
    end,
}

local function refreshChunlaoAttach(room)
    local owners = room:findPlayersBySkillName("chunlao")
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        local eligible = false
        for _, owner in sgs.qlist(owners) do
            if owner:isAlive() and owner:hasShownSkill("chunlao")
                and (p:objectName() == owner:objectName() or p:isFriendWith(owner)) then
                eligible = true
                break
            end
        end
        if eligible and not p:hasSkill("chunlao_attach") then
            room:attachSkillToPlayer(p, "chunlao_attach")
        elseif not eligible and p:hasSkill("chunlao_attach") then
            room:detachSkillFromPlayer(p, "chunlao_attach")
        end
    end
end

chunlao = sgs.CreateTriggerSkill{
    name = "chunlao",
    events = {sgs.GameStart, sgs.GeneralShown, sgs.GeneralHidden, sgs.GeneralRemoved,
        sgs.DFDebut, sgs.Death, sgs.EventAcquireSkill, sgs.EventLoseSkill,
        sgs.RemoveStateChanged},
    frequency = sgs.Skill_Compulsory,

    on_record = function(self, event, room, player, data)
        refreshChunlaoAttach(room)
    end,

    can_trigger = function(self, event, room, player, data)
        return ""
    end,
}

guyong_hanjin = sgs.General(extension, "guyong_hanjin", "wu", 3)

mizhong = sgs.CreateTriggerSkill{
    name = "mizhong",
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_Compulsory,

    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName())
            and player:getHandcardNum() == player:getHp() then
            local damage = data:toDamage()
            if damage.damage > 0 then return self:objectName() end
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        if not player:hasShownSkill(self:objectName())
            and not player:askForSkillInvoke(self:objectName(), data) then
            return false
        end
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:broadcastSkillInvoke(self:objectName(), player)
        return true
    end,

    on_effect = function(self, event, room, player, data)
        local damage = data:toDamage()
        damage.damage = damage.damage - 1
        data:setValue(damage)
        return damage.damage <= 0
    end,
}

local function bingyiHandcardsSameColor(player)
    local handcards = player:getHandcards()
    if handcards:isEmpty() then return false end
    local color = handcards:first():getColor()
    for _, card in sgs.qlist(handcards) do
        if card:getColor() ~= color then return false end
    end
    return true
end

local function bingyiDiscardedByOwner(data, owner)
    for _, move_data in sgs.qlist(data:toList()) do
        local move = move_data:toMoveOneTime()
        local basic_reason = bit32.band(move.reason.m_reason,
            sgs.CardMoveReason_S_MASK_BASIC_REASON)
        if basic_reason == sgs.CardMoveReason_S_REASON_DISCARD
            and move.from and move.from:objectName() == owner:objectName()
            and not move.card_ids:isEmpty() then
            return true
        end
    end
    return false
end

bingyi = sgs.CreateTriggerSkill{
    name = "bingyi",
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,

    on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player
            and player:getPhase() == sgs.Player_RoundStart then
            for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                room:setPlayerMark(owner, "bingyi_used_turn", 0)
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if event ~= sgs.CardsMoveOneTime then return "" end
        local skill_list = {}
        local owner_list = {}
        for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if owner:isAlive() and owner:getMark("bingyi_used_turn") == 0
                and bingyiDiscardedByOwner(data, owner)
                and bingyiHandcardsSameColor(owner) then
                table.insert(skill_list, self:objectName())
                table.insert(owner_list, owner:objectName())
            end
        end
        return table.concat(skill_list, "|"), table.concat(owner_list, "|")
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        if ask_who:askForSkillInvoke(self:objectName(), data) then
            room:setPlayerMark(ask_who, "bingyi_used_turn", 1)
            room:broadcastSkillInvoke(self:objectName(), ask_who)
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        if not (ask_who:isAlive() and bingyiHandcardsSameColor(ask_who)) then
            return false
        end
        room:showAllCards(ask_who)
        local max_num = math.min(ask_who:getHandcardNum(), room:alivePlayerCount())
        if max_num <= 0 then return false end
        local targets = room:askForPlayersChosen(ask_who, room:getAlivePlayers(),
            self:objectName(), 0, max_num,
            "@bingyi-draw:::" .. tostring(max_num), true)
        for _, target in sgs.qlist(targets) do
            target:drawCards(1, self:objectName())
        end
        return false
    end,
}

zhanghong_hanjin = sgs.General(extension, "zhanghong_hanjin", "wu", 3)

shuoshanCard = sgs.CreateSkillCard{
    name = "shuoshanCard",
    skill_name = "shuoshan",
    target_fixed = false,
    will_throw = false,

    filter = function(self, targets, to_select, source)
        return #targets == 0
            and to_select:objectName() ~= source:objectName()
            and not source:isKongcheng() and not to_select:isKongcheng()
    end,

    on_use = function(self, room, source, targets)
        local target = targets[1]
        if target and target:isAlive() and not source:isKongcheng()
            and not target:isKongcheng() then
            source:pindian(target, "shuoshan")
        end
    end,
}

shuoshanVS = sgs.CreateZeroCardViewAsSkill{
    name = "shuoshan",

    view_as = function(self)
        local card = shuoshanCard:clone()
        card:setShowSkill(self:objectName())
        return card
    end,

    enabled_at_play = function(self, player)
        if player:hasUsed("#shuoshanCard") or player:isKongcheng() then
            return false
        end
        return true
    end,
}

shuoshan = sgs.CreateTriggerSkill{
    name = "shuoshan",
    events = {sgs.Pindian},
    view_as_skill = shuoshanVS,
    frequency = sgs.Skill_Frequent,

    can_trigger = function(self, event, room, player, data)
        local pindian = data:toPindian()
        if pindian.reason == self:objectName() then return self:objectName() end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        return true
    end,

    on_effect = function(self, event, room, player, data)
        local pindian = data:toPindian()
        local winner = nil
        local loser = nil
        if pindian.from_number > pindian.to_number then
            winner = pindian.from
            loser = pindian.to
        elseif pindian.from_number < pindian.to_number then
            winner = pindian.to
            loser = pindian.from
        else
            return false
        end

        if not (winner and winner:isAlive() and loser and loser:isAlive()) then
            return false
        end
        local draw_num = math.max(0,
            winner:getHandcardNum() - loser:getHandcardNum())
        if draw_num > 0 then
            loser:drawCards(draw_num, self:objectName())
        elseif loser:isWounded() then
            local recover = sgs.RecoverStruct()
            recover.who = pindian.from
            recover.recover = 1
            room:recover(loser, recover)
        end
        return false
    end,
}

local function roufuIsDamageCard(card)
    if not card then return false end
    local damage_cards = {
        "Slash", "Duel", "ArcheryAttack", "SavageAssault",
        "BurningCamps", "Drowning", "FireAttack"
    }
    for _, class_name in ipairs(damage_cards) do
        if card:isKindOf(class_name) then return true end
    end
    return false
end

roufu = sgs.CreateTriggerSkill{
    name = "roufu",
    events = {sgs.TargetConfirmed, sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,

    on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player
            and player:getPhase() == sgs.Player_RoundStart then
            for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                room:setPlayerMark(owner, "roufu_used_turn", 0)
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if not (event == sgs.TargetConfirmed and player and player:isAlive()
            and player:hasSkill(self:objectName())) then
            return ""
        end
        local use = data:toCardUse()
        if use.from and use.from:isAlive()
            and use.from:objectName() ~= player:objectName()
            and roufuIsDamageCard(use.card)
            and use.to:length() == 1 and use.to:contains(player)
            and not player:willBeFriendWith(use.from) then
            return self:objectName()
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data)
        local use = data:toCardUse()
        local source = use.from
        if not (source and source:isAlive()) then return false end

        room:addPlayerMark(player, "roufu_used_turn")
        local x = player:getMark("roufu_used_turn")
        source:drawCards(1, self:objectName())

        if player:isAlive() and source:isAlive() and not source:isNude() then
            local give_num = math.min(x, source:getCardCount(true))
            local card_ids = room:askForExchange(source, self:objectName(),
                give_num, give_num,
                "@roufu-give:" .. player:objectName() .. "::" .. tostring(give_num),
                "", ".|.|.|hand,equipped")
            if not card_ids:isEmpty() then
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,
                    source:objectName(), player:objectName(), self:objectName(), "")
                local move = sgs.CardsMoveStruct(card_ids, player,
                    sgs.Player_PlaceHand, reason)
                room:moveCardsAtomic(move, false)
            end
        end
        return false
    end,
}

zhuling_hanjin = sgs.General(extension, "zhuling_hanjin", "wei", 4)

local function jixianConditionCount(source, target)
    local count = 0
    if target:getFormation():length() > 1 then count = count + 1 end
    if target:getVisibleSkillList():length()
        > source:getVisibleSkillList():length() then
        count = count + 1
    end
    if not target:isWounded() then count = count + 1 end
    return count
end

local function jixianCandidates(room, source)
    local candidates = sgs.SPlayerList()
    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
    slash:setSkillName("jixian")
    if not source:isCardLimited(slash, sgs.Card_MethodUse)
        and sgs.Slash_IsAvailable(source) then
        for _, target in sgs.qlist(room:getOtherPlayers(source)) do
            if jixianConditionCount(source, target) > 0
                and source:canSlash(target, slash, false)
                and not source:isProhibited(target, slash) then
                candidates:append(target)
            end
        end
    end
    slash:deleteLater()
    return candidates
end

jixian = sgs.CreateTriggerSkill{
    name = "jixian",
    events = {sgs.EventPhaseStart, sgs.Damage, sgs.CardFinished},
    frequency = sgs.Skill_Frequent,

    on_record = function(self, event, room, player, data)
        if event ~= sgs.Damage then return end
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash")
            and damage.card:getSkillName() == self:objectName() then
            local total = damage.card:getTag("jixian_damage"):toInt()
            damage.card:setTag("jixian_damage",
                sgs.QVariant(total + damage.damage))
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart then
            if player and player:isAlive() and player:hasSkill(self:objectName())
                and player:getPhase() == sgs.Player_Play
                and not jixianCandidates(room, player):isEmpty() then
                return self:objectName()
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.from and use.from:isAlive() and use.from:hasSkill(self:objectName())
                and use.card and use.card:isKindOf("Slash")
                and use.card:getSkillName() == self:objectName() then
                return self:objectName(), use.from:objectName()
            end
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        if event == sgs.CardFinished then return true end
        local target = room:askForPlayerChosen(ask_who,
            jixianCandidates(room, ask_who), self:objectName(),
            "@jixian-target", true, true)
        if not target then return false end
        ask_who:setTag("jixian_target", sgs.QVariant(target:objectName()))
        room:setPlayerMark(ask_who, "jixian_draw",
            jixianConditionCount(ask_who, target))
        room:broadcastSkillInvoke(self:objectName(), ask_who)
        return true
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:getTag("jixian_damage"):toInt() == 0
                and ask_who:isAlive() then
                room:loseHp(ask_who, 1)
            end
            return false
        end

        local target = room:findPlayer(ask_who:getTag("jixian_target"):toString())
        ask_who:removeTag("jixian_target")
        local draw_num = ask_who:getMark("jixian_draw")
        room:setPlayerMark(ask_who, "jixian_draw", 0)
        if not (target and target:isAlive()) then return false end

        if draw_num > 0 then ask_who:drawCards(draw_num, self:objectName()) end
        if not (ask_who:isAlive() and target:isAlive()) then return false end

        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        slash:setSkillName(self:objectName())
        slash:setTag("jixian_damage", sgs.QVariant(0))
        if not ask_who:isCardLimited(slash, sgs.Card_MethodUse)
            and ask_who:canSlash(target, slash, false)
            and not ask_who:isProhibited(target, slash) then
            local use = sgs.CardUseStruct()
            use.card = slash
            use.from = ask_who
            use.to:append(target)
            room:useCard(use)
        end
        slash:deleteLater()
        return false
    end,
}

qianshuo_hanjin = sgs.General(extension, "qianshuo_hanjin", "qun", 4)

jibing = sgs.CreateTriggerSkill{
    name = "jibing",
    events = {sgs.DrawNCards, sgs.Damage, sgs.EventPhaseChanging},
    frequency = sgs.Skill_Frequent,

    on_record = function(self, event, room, player, data)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.from and damage.from:getMark("jibing_x") > 0
                and damage.damage > 0 then
                room:addPlayerMark(damage.from, "jibing_damage", damage.damage)
            end
        elseif event == sgs.EventPhaseChanging and player then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive and player:getMark("jibing_x") > 0
                and player:getMark("jibing_damage") >= player:getMark("jibing_x") then
                room:setPlayerMark(player, "jibing_x", 0)
                room:setPlayerMark(player, "jibing_damage", 0)
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if event == sgs.DrawNCards then
            if player and player:isAlive() and player:hasSkill(self:objectName()) then
                return self:objectName()
            end
        elseif event == sgs.EventPhaseChanging and player and player:isAlive() then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive and player:getMark("jibing_x") > 0
                and player:getMark("jibing_damage") < player:getMark("jibing_x") then
                return self:objectName()
            end
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        if event == sgs.EventPhaseChanging then return true end
        if player:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data)
        if event == sgs.DrawNCards then
            local x = math.max(1,
                player:getPlayerNumWithSameKingdom(self:objectName()))
            room:setPlayerMark(player, "jibing_x", x)
            room:setPlayerMark(player, "jibing_damage", 0)
            data:setValue(data:toInt() + x)
            return false
        end

        room:setPlayerMark(player, "jibing_x", 0)
        room:setPlayerMark(player, "jibing_damage", 0)
        room:loseHp(player, 1)
        return false
    end,
}

duanwei_hanjin = sgs.General(extension, "duanwei_hanjin", "qun", 4)

kentun = sgs.CreateTriggerSkill{
    name = "kentun",
    events = {sgs.CardUsed, sgs.EventPhaseStart, sgs.EventPhaseEnd},
    frequency = sgs.Skill_Frequent,

    on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player
            and player:getPhase() == sgs.Player_Play
            and player:hasSkill(self:objectName()) then
            room:setPlayerMark(player, "kentun_last_card", 0)
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if not (use.from and use.from:isAlive()
                and use.from:hasSkill(self:objectName())
                and use.from:getPhase() == sgs.Player_Play) then
                return
            end

            local qualified = not use.to:isEmpty()
            if qualified then
                for _, target in sgs.qlist(use.to) do
                    if not use.from:isFriendWith(target) then
                        qualified = false
                        break
                    end
                end
            end
            room:setPlayerMark(use.from, "kentun_last_card", qualified and 1 or 0)
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseEnd and player and player:isAlive()
            and player:hasSkill(self:objectName())
            and player:getPhase() == sgs.Player_Play
            and player:getMark("kentun_last_card") > 0 then
            room:setPlayerMark(player, "kentun_last_card", 0)
            return self:objectName()
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data)
        player:drawCards(2, self:objectName())
        return false
    end,
}

xunshou = sgs.CreateTriggerSkill{
    name = "xunshou",
    events = {sgs.Damage},
    frequency = sgs.Skill_Frequent,

    can_trigger = function(self, event, room, player, data)
        local damage = data:toDamage()
        if not (damage.from and damage.from:isAlive() and damage.to
            and damage.damage > 0 and damage.from:isFriendWith(damage.to)) then
            return ""
        end

        local skill_list = {}
        local owner_list = {}
        for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if owner:isAlive() and not owner:isNude()
                and owner:objectName() ~= damage.from:objectName() then
                table.insert(skill_list, self:objectName())
                table.insert(owner_list, owner:objectName())
            end
        end
        return table.concat(skill_list, "|"), table.concat(owner_list, "|")
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        return room:askForDiscard(ask_who, self:objectName(), 1, 1, true, true)
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        local source = data:toDamage().from
        if source and source:isAlive() and ask_who:isAlive() then
            local damage = sgs.DamageStruct()
            damage.from = ask_who
            damage.to = source
            damage.damage = 1
            damage.reason = self:objectName()
            room:damage(damage)
        end
        return false
    end,
}

liuchong_hanjin = sgs.General(extension, "liuchong_hanjin", "qun", 4)

jinnu = sgs.CreateTriggerSkill{
    name = "jinnu",
    events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.EventPhaseEnd},

    on_record = function(self, event, room, player, data)
        if not (player and player:hasSkill(self:objectName())) then return end

        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
            room:setPlayerMark(player, "jinnu_used", 0)
            room:setPlayerMark(player, "jinnu_non_slash", 0)
            room:setPlayerMark(player, "jinnu_last_slash", 0)
            room:setPlayerMark(player, "jinnu_second_last_slash", 0)
        elseif event == sgs.CardUsed and player:getPhase() == sgs.Player_Play then
            local use = data:toCardUse()
            if use.from and use.from:objectName() == player:objectName()
                and use.card and use.card:getSkillName() ~= self:objectName() then
                room:setPlayerMark(player, "jinnu_used", player:getMark("jinnu_used") + 1)
                room:setPlayerMark(player, "jinnu_second_last_slash",
                    player:getMark("jinnu_last_slash"))
                local is_slash = use.card:isKindOf("Slash")
                room:setPlayerMark(player, "jinnu_last_slash", is_slash and 1 or 0)
                if not is_slash then
                    room:setPlayerMark(player, "jinnu_non_slash",
                        player:getMark("jinnu_non_slash") + 1)
                end
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if event ~= sgs.EventPhaseEnd or not (player and player:isAlive()
            and player:hasSkill(self:objectName())
            and player:getPhase() == sgs.Player_Play) then
            return ""
        end

        local used = player:getMark("jinnu_used")
        local all_slash = used > 0 and player:getMark("jinnu_non_slash") == 0
        local last_two_not_slash = used >= 2
            and player:getMark("jinnu_last_slash") == 0
            and player:getMark("jinnu_second_last_slash") == 0
        if not (all_slash or last_two_not_slash) then return "" end

        local slash = sgs.Sanguosha:cloneCard("slash")
        slash:setSkillName(self:objectName())
        local can_use = false
        if not player:isCardLimited(slash, sgs.Card_MethodUse) then
            for _, target in sgs.qlist(room:getOtherPlayers(player)) do
                if player:canSlash(target, slash, true)
                    and not room:isProhibited(player, target, slash) then
                    can_use = true
                    break
                end
            end
        end
        slash:deleteLater()
        return can_use and self:objectName() or ""
    end,

    on_cost = function(self, event, room, player, data)
        local slash = sgs.Sanguosha:cloneCard("slash")
        slash:setSkillName(self:objectName())
        local candidates = sgs.SPlayerList()
        for _, target in sgs.qlist(room:getOtherPlayers(player)) do
            if player:canSlash(target, slash, true)
                and not room:isProhibited(player, target, slash) then
                candidates:append(target)
            end
        end
        slash:deleteLater()

        local target = room:askForPlayerChosen(player, candidates, self:objectName(),
            "@jinnu-slash", true, true)
        if target then
            local target_data = sgs.QVariant()
            target_data:setValue(target)
            player:setTag("jinnu_target", target_data)
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data)
        local target = player:getTag("jinnu_target"):toPlayer()
        player:removeTag("jinnu_target")
        if not (target and target:isAlive()) then return false end

        local slash = sgs.Sanguosha:cloneCard("slash")
        slash:setSkillName(self:objectName())
        local use = sgs.CardUseStruct()
        use.card = slash
        use.from = player
        use.to:append(target)
        room:useCard(use, false)
        slash:deleteLater()
        return false
    end,
}

weitun = sgs.CreateTriggerSkill{
    name = "weitun",
    events = {sgs.EventPhaseChanging},
    frequency = sgs.Skill_Limited,
    limit_mark = "@weitun",

    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())
            and player:getMark("@weitun") > 0
            and data:toPhaseChange().to == sgs.Player_Discard) then
            return ""
        end

        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getHandcardNum() > player:getHandcardNum() then return "" end
        end
        return self:objectName()
    end,

    on_cost = function(self, event, room, player, data)
        return player:askForSkillInvoke(self:objectName(), data)
    end,

    on_effect = function(self, event, room, player, data)
        room:removePlayerMark(player, "@weitun")
        room:broadcastSkillInvoke(self:objectName(), player)
        player:skip(sgs.Player_Discard)

        local targets = room:askForPlayersChosen(player, room:getAlivePlayers(),
            self:objectName(), 1, room:alivePlayerCount(), "@weitun-target", false)

        if not targets:isEmpty() then
            local god_salvation = sgs.Sanguosha:cloneCard("god_salvation")
            god_salvation:setSkillName(self:objectName())
            room:useCard(sgs.CardUseStruct(god_salvation, player, targets), false)
            god_salvation:deleteLater()

            local amazing_grace = sgs.Sanguosha:cloneCard("amazing_grace")
            amazing_grace:setSkillName(self:objectName())
            room:useCard(sgs.CardUseStruct(amazing_grace, player, targets), false)
            amazing_grace:deleteLater()
        end
        return false
    end,
}

tangji_hanjin = sgs.General(extension, "tangji_hanjin", "qun", 3, false)

aiwu = sgs.CreateTriggerSkill{
    name = "aiwu",
    events = {sgs.Damaged, sgs.EventPhaseChanging},
    frequency = sgs.Skill_Frequent,

    on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseChanging
            and data:toPhaseChange().to == sgs.Player_NotActive then
            for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                room:setPlayerMark(owner, "aiwu_used_turn", 0)
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if event ~= sgs.Damaged or not player then return "" end

        local skill_list = {}
        local owner_list = {}
        for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if owner:isAlive() and owner:objectName() ~= player:objectName()
                and owner:getMark("aiwu_used_turn") == 0 and not owner:isNude() then
                table.insert(skill_list, self:objectName())
                table.insert(owner_list, owner:objectName())
            end
        end
        return table.concat(skill_list, "|"), table.concat(owner_list, "|")
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        local max_num = ask_who:getCardCount(true)
        local card_ids = room:askForExchange(ask_who, self:objectName(), max_num, 1,
            "@aiwu-discard:" .. player:objectName(), "", ".|.|.|hand,equipped")
        if card_ids:isEmpty() then return false end

        room:setPlayerMark(ask_who, "aiwu_used_turn", 1)
        room:setPlayerMark(ask_who, "aiwu_discard_count", card_ids:length())
        local dummy = sgs.DummyCard(card_ids)
        room:throwCard(dummy, ask_who, ask_who, self:objectName())
        dummy:deleteLater()
        room:broadcastSkillInvoke(self:objectName(), ask_who)
        return true
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        local total = ask_who:getMark("aiwu_discard_count")
        room:setPlayerMark(ask_who, "aiwu_discard_count", 0)

        if player:isAlive() and not player:isNude() then
            local max_num = player:getCardCount(true)
            local card_ids = room:askForExchange(player, self:objectName(), max_num, 0,
                "@aiwu-target-discard:" .. ask_who:objectName(), "",
                ".|.|.|hand,equipped")
            if not card_ids:isEmpty() then
                total = total + card_ids:length()
                local dummy = sgs.DummyCard(card_ids)
                room:throwCard(dummy, player, player, self:objectName())
                dummy:deleteLater()
            end
        end

        if total >= 3 then
            if ask_who:isAlive() and ask_who:isWounded() then
                local recover = sgs.RecoverStruct()
                recover.who = ask_who
                recover.recover = 1
                room:recover(ask_who, recover)
            end
            if player:isAlive() and player:isWounded() then
                local recover = sgs.RecoverStruct()
                recover.who = ask_who
                recover.recover = 1
                room:recover(player, recover)
            end
        end
        return false
    end,
}

juebies = sgs.CreateTriggerSkill{
    name = "juebies",
    events = {sgs.Death},
    frequency = sgs.Skill_Frequent,

    can_trigger = function(self, event, room, player, data)
        local death = data:toDeath()
        local dead = death.who
        if not dead then return "" end

        local skill_list = {}
        local owner_list = {}
        for _, owner in sgs.qlist(room:getAllPlayers(true)) do
            if owner:hasSkill(self:objectName())
                and (owner:isAlive() or owner:objectName() == dead:objectName())
                and owner:isFriendWith(dead) then
                local has_target = false
                for _, target in sgs.qlist(room:getAlivePlayers()) do
                    if target:objectName() ~= dead:objectName()
                        and owner:isFriendWith(target) then
                        has_target = true
                        break
                    end
                end
                if has_target then
                    table.insert(skill_list, self:objectName())
                    table.insert(owner_list, owner:objectName())
                end
            end
        end
        return table.concat(skill_list, "|"), table.concat(owner_list, "|")
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        local dead = data:toDeath().who
        if dead:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), ask_who)
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        local dead = data:toDeath().who
        local candidates = sgs.SPlayerList()
        for _, target in sgs.qlist(room:getAlivePlayers()) do
            if target:objectName() ~= dead:objectName()
                and ask_who:isFriendWith(target) then
                candidates:append(target)
            end
        end
        if candidates:isEmpty() then return false end

        local target = room:askForPlayerChosen(dead, candidates, self:objectName(),
            "@juebies-target", false, true)
        if not target then return false end

        local all_cards = sgs.IntList()
        for _, card_id in sgs.qlist(dead:handCards()) do
            all_cards:append(card_id)
        end
        for _, card in sgs.qlist(dead:getEquips()) do
            all_cards:append(card:getId())
        end
        for _, card in sgs.qlist(dead:getJudgingArea()) do
            all_cards:append(card:getId())
        end

        local choices = "draw"
        if not all_cards:isEmpty() then choices = "obtain+draw" end
        local choice = room:askForChoice(dead, self:objectName(), choices, data)
        if choice == "obtain" and not all_cards:isEmpty() then
            local move = sgs.CardsMoveStruct()
            move.card_ids = all_cards
            move.to = target
            move.to_place = sgs.Player_PlaceHand
            move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD,
                dead:objectName(), target:objectName(), self:objectName(), "")
            room:moveCardsAtomic(move, true)
        else
            target:drawCards(3, self:objectName())
        end
        return false
    end,
}

yanpu_hanjin = sgs.General(extension, "yanpu_hanjin", "wei", 3)

huantu = sgs.CreateTriggerSkill{
    name = "huantu",
    events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
    frequency = sgs.Skill_Frequent,

    on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player
            and player:getPhase() == sgs.Player_RoundStart
            and player:hasSkill(self:objectName()) then
            room:setPlayerMark(player, "huantu_used_round", 0)
        elseif event == sgs.EventPhaseChanging and player
            and data:toPhaseChange().to == sgs.Player_NotActive then
            local count = player:getMark("huantu_companion_pending")
            if count > 0 then
                room:setPlayerMark(player, "huantu_companion_pending", 0)
                room:addPlayerMark(player, "@companion", count)
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if event ~= sgs.EventPhaseChanging or not (player and player:isAlive())
            or data:toPhaseChange().to ~= sgs.Player_Draw then
            return ""
        end

        local skill_list = {}
        local owner_list = {}
        for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if owner:isAlive() and owner:objectName() ~= player:objectName()
                and owner:isFriendWith(player)
                and owner:getMark("huantu_used_round") == 0
                and not owner:isNude() then
                table.insert(skill_list, self:objectName())
                table.insert(owner_list, owner:objectName())
            end
        end
        return table.concat(skill_list, "|"), table.concat(owner_list, "|")
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        local max_num = ask_who:getCardCount(true)
        local card_ids = room:askForExchange(ask_who, self:objectName(), max_num, 1,
            "@huantu-give:" .. player:objectName(), "", ".|.|.|hand,equipped")
        if card_ids:isEmpty() then return false end

        room:setPlayerMark(ask_who, "huantu_used_round", 1)
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,
            ask_who:objectName(), player:objectName(), self:objectName(), "")
        local move = sgs.CardsMoveStruct(card_ids, player, sgs.Player_PlaceHand, reason)
        room:moveCardsAtomic(move, false)
        room:broadcastSkillInvoke(self:objectName(), ask_who)
        return true
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        player:skip(sgs.Player_Draw)
        room:addPlayerMark(player, "huantu_companion_pending", 1)
        return false
    end,
}

bihuo = sgs.CreateTriggerSkill{
    name = "bihuo",
    events = {sgs.QuitDying, sgs.EventPhaseChanging, sgs.Death},
    frequency = sgs.Skill_Limited,
    limit_mark = "@bihuo",

    on_record = function(self, event, room, player, data)
        local turn_ended = event == sgs.EventPhaseChanging
            and data:toPhaseChange().to == sgs.Player_NotActive
        if event == sgs.Death then
            local current = room:getCurrent()
            turn_ended = current and data:toDeath().who:objectName() == current:objectName()
        end
        if turn_ended then--当前回合结束，或当前回合角色死亡，清除标记
            for _, target in sgs.qlist(room:getAllPlayers(true)) do
                if target:getMark("bihuo_removed_turn") > 0 then
                    room:setPlayerMark(target, "bihuo_removed_turn", 0)
                    if target:isRemoved() then
                        room:setPlayerProperty(target, "removed", sgs.QVariant(false))
                    end
                end
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if event ~= sgs.QuitDying then return "" end
        local dying = data:toDying()
        if not (dying.who and dying.who:isAlive()) then
            return ""
        end

        local skill_list = {}
        local owner_list = {}
        for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if owner:isAlive() and owner:getMark("@bihuo") > 0 then
                table.insert(skill_list, self:objectName())
                table.insert(owner_list, owner:objectName())
            end
        end
        return table.concat(skill_list, "|"), table.concat(owner_list, "|")
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        if ask_who:askForSkillInvoke(self:objectName(), data) then
            room:removePlayerMark(ask_who, "@bihuo")
            room:broadcastSkillInvoke(self:objectName(), ask_who)
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        local target = data:toDying().who
        target:drawCards(3, self:objectName())
        if target:isAlive() then
            room:setPlayerMark(target, "bihuo_removed_turn", 1)
            room:setPlayerProperty(target, "removed", sgs.QVariant(true))
        end
        return false
    end,
}

yangbiao_hanjin = sgs.General(extension, "yangbiao_hanjin", "qun", 3)

rangjie = sgs.CreateTriggerSkill{
    name = "rangjie",
    events = {sgs.Damaged},
    frequency = sgs.Skill_Frequent,

    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())
            and not player:isKongcheng()) then
            return ""
        end
        local damage = data:toDamage()
        if damage.from and damage.from:isAlive() and damage.card
            and damage.card:isKindOf("Slash") then
            return self:objectName()
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data)
        local source = data:toDamage().from
        if not (source and source:isAlive() and player:isAlive()
            and not player:isKongcheng()) then
            return false
        end

        local shown_id = room:askForCardChosen(source, player, "h",
            self:objectName(), false, sgs.Card_MethodNone)
        room:showCard(player, shown_id)
        local shown_card = sgs.Sanguosha:getCard(shown_id)
        if shown_card:getSuit() == sgs.Card_Heart then
            if player:canTransform() then
                room:transformDeputyGeneral(player)
            end
            return false
        end

        if player:isAlive() and not player:isKongcheng() then
            local top_id = room:askForCardChosen(player, player, "h",
                self:objectName(), false, sgs.Card_MethodNone)
            room:moveCardTo(sgs.Sanguosha:getCard(top_id), nil,
                sgs.Player_DrawPile, true)
        end
        if player:isAlive() and player:isWounded() then
            local recover = sgs.RecoverStruct()
            recover.who = player
            recover.recover = 1
            room:recover(player, recover)
        end
        return false
    end,
}

YizhaCard = sgs.CreateSkillCard{
    name = "YizhaCard",
    target_fixed = false,
    will_throw = false,

    filter = function(self, targets, to_select, source)
        return #targets == 0 and to_select:objectName() ~= source:objectName()
            and to_select:getHp() > source:getHp() and not to_select:isKongcheng()
    end,

    feasible = function(self, targets, source)
        return #targets == 1
    end,

    on_use = function(self, room, source, targets)
        local target = targets[1]
        if not (target and target:isAlive() and source:isAlive()
            and not source:isKongcheng() and not target:isKongcheng()) then
            return
        end
        source:pindian(target, "yizha")
    end,
}

yizhaVS = sgs.CreateZeroCardViewAsSkill{
    name = "yizha",

    view_as = function(self)
        local card = YizhaCard:clone()
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card
    end,

    enabled_at_play = function(self, player)
        if player:hasUsed("#YizhaCard") or player:isKongcheng() then return false end
        for _, target in sgs.qlist(player:getAliveSiblings()) do
            if target:getHp() > player:getHp() and not target:isKongcheng() then
                return true
            end
        end
        return false
    end,
}

yizha = sgs.CreateTriggerSkill{
    name = "yizha",
    events = {sgs.Pindian},
    view_as_skill = yizhaVS,
    frequency = sgs.Skill_Frequent,

    can_trigger = function(self, event, room, player, data)
        local pindian = data:toPindian()
        if pindian.reason == self:objectName() then return self:objectName() end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        return true
    end,

    on_effect = function(self, event, room, player, data)
        local pindian = data:toPindian()
        local winner = nil
        local loser = nil
        if pindian.from_number > pindian.to_number then
            winner = pindian.from
            loser = pindian.to
        elseif pindian.from_number < pindian.to_number then
            winner = pindian.to
            loser = pindian.from
        end

        if winner and winner:isAlive() and loser and loser:isAlive()
            and not loser:isNude() then
            local card_id = room:askForCardChosen(winner, loser, "he",
                self:objectName(), false, sgs.Card_MethodGet)
            room:obtainCard(winner, card_id, false)
        end

        if pindian.from and pindian.from:isAlive() and pindian.from_card
            and pindian.to_card and pindian.from_card:isRed() ~= pindian.to_card:isRed() then
            pindian.from:drawCards(1, self:objectName())
        end
        return false
    end,
}

wangxu_hanjin = sgs.General(extension, "wangxu_hanjin", "wei", 4)

jianzhi = sgs.CreateTriggerSkill{
    name = "jianzhi",
    events = {sgs.EventPhaseStart, sgs.TargetChoosing, sgs.TargetConfirmed},
    frequency = sgs.Skill_Frequent,

    on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player then
            if player:getPhase() == sgs.Player_RoundStart then
                for _, p in sgs.qlist(room:getAllPlayers(true)) do
                    room:setPlayerMark(p, "jianzhi_targeted_turn", 0)
                end
            end
            if player:getPhase() == sgs.Player_Play
                and player:hasSkill(self:objectName()) then
                room:setPlayerMark(player, "jianzhi_used_phase", 0)
            end
        elseif event == sgs.TargetConfirmed and player then
            local use = data:toCardUse()
            if use.card and use.card:getTypeId() ~= sgs.Card_TypeSkill
                and use.to:contains(player) then
                room:setPlayerMark(player, "jianzhi_targeted_turn", 1)
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if event ~= sgs.TargetChoosing or not (player and player:isAlive()
            and player:hasSkill(self:objectName())
            and player:getPhase() == sgs.Player_Play
            and player:getMark("jianzhi_used_phase") == 0) then
            return ""
        end

        local use = data:toCardUse()
        if not use.card or use.card:getTypeId() == sgs.Card_TypeSkill then return "" end
        local extra_targets = room:getUseExtraTargets(use, false)
        for _, target in sgs.qlist(extra_targets) do
            if target:getMark("jianzhi_targeted_turn") > 0 then
                return self:objectName()
            end
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        local use = data:toCardUse()
        local candidates = sgs.SPlayerList()
        for _, target in sgs.qlist(room:getUseExtraTargets(use, false)) do
            if target:getMark("jianzhi_targeted_turn") > 0 then
                candidates:append(target)
            end
        end
        if candidates:isEmpty() then return false end

        local chosen = room:askForPlayersChosen(player, candidates,
            self:objectName(), 0, candidates:length(),
            "@jianzhi-target:::" .. use.card:objectName(), false)
        if chosen:isEmpty() then return false end

        local names = {}
        for _, target in sgs.qlist(chosen) do
            table.insert(names, target:objectName())
        end
        player:setTag("jianzhi_targets", sgs.QVariant(table.concat(names, "+")))
        room:setPlayerMark(player, "jianzhi_used_phase", 1)
        room:broadcastSkillInvoke(self:objectName(), player)
        return true
    end,

    on_effect = function(self, event, room, player, data)
        local use = data:toCardUse()
        local names = player:getTag("jianzhi_targets"):toString():split("+")
        player:removeTag("jianzhi_targets")
        for _, name in ipairs(names) do
            local target = room:findPlayer(name)
            if target and target:isAlive() and not use.to:contains(target) then
                use.to:append(target)
            end
        end
        room:sortByActionOrder(use.to)
        data:setValue(use)
        return false
    end,
}

liuye_hanjin = sgs.General(extension, "liuye_hanjin", "wei", 3)

local function poyuanAreaChoices(player)
    local choices = {}
    if not player:isKongcheng() then table.insert(choices, "hand") end
    if not player:getEquips():isEmpty() then table.insert(choices, "equip") end
    if not player:getJudgingArea():isEmpty() then table.insert(choices, "judge") end
    return choices
end

poyuan = sgs.CreateTriggerSkill{
    name = "poyuan",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Limited,
    limit_mark = "@poyuan",
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())
            and player:getPhase() == sgs.Player_Start and player:getMark("@poyuan") > 0
            and #poyuanAreaChoices(player) > 0) then return "" end
        return room:getOtherPlayers(player):isEmpty() and "" or self:objectName()
    end,
    on_cost = function(self, event, room, player, data)
        if not player:askForSkillInvoke(self:objectName(), data) then return false end
        local area = room:askForChoice(player, self:objectName(),
            table.concat(poyuanAreaChoices(player), "+"), data, "@poyuan-area")
        player:setTag("poyuan_area", sgs.QVariant(area))
        room:removePlayerMark(player, "@poyuan")
        room:broadcastSkillInvoke(self:objectName(), player)
        return true
    end,
    on_effect = function(self, event, room, player, data)
        local area = player:getTag("poyuan_area"):toString()
        player:removeTag("poyuan_area")
        local cards = sgs.IntList()
        if area == "hand" then
            for _, id in sgs.qlist(player:handCards()) do cards:append(id) end
        elseif area == "equip" then
            for _, card in sgs.qlist(player:getEquips()) do cards:append(card:getId()) end
        elseif area == "judge" then
            for _, card in sgs.qlist(player:getJudgingArea()) do cards:append(card:getId()) end
        end
        if cards:isEmpty() then return false end
        local count = cards:length()
        local dummy = sgs.DummyCard(cards)
        room:throwCard(dummy, player, player, self:objectName())
        dummy:deleteLater()
        if not player:isAlive() then return false end

        local candidates = sgs.SPlayerList()
        for _, target in sgs.qlist(room:getOtherPlayers(player)) do
            if not target:isAllNude() and player:canDiscard(target, "hej") then
                candidates:append(target)
            end
        end
        if candidates:isEmpty() then return false end
        local target = room:askForPlayerChosen(player, candidates, self:objectName(),
            "@poyuan-target:::" .. tostring(count + 1), false, false)
        local max_num = math.min(count + 1, target:getCards("hej"):length())
        for i = 1, max_num do
            if not (player:isAlive() and target:isAlive()
                and player:canDiscard(target, "hej")) then break end
            local choice = room:askForChoice(player, "poyuan_continue", "discard+cancel",
                data, "@poyuan-discard:" .. target:objectName() .. "::" ..
                    tostring(i - 1) .. ":" .. tostring(max_num))
            if choice == "cancel" then break end
            local id = room:askForCardChosen(player, target, "hej",
                self:objectName(), false, sgs.Card_MethodDiscard)
            room:throwCard(id, target, player, self:objectName())
        end
        return false
    end,
}

choulue = sgs.CreateTriggerSkill{
    name = "choulue",
    events = {sgs.Damaged, sgs.EventPhaseChanging, sgs.Death},
    frequency = sgs.Skill_Frequent,
    on_record = function(self, event, room, player, data)
        local turn_ended = event == sgs.EventPhaseChanging
            and data:toPhaseChange().to == sgs.Player_NotActive
        if event == sgs.Death then
            local current = room:getCurrent()
            turn_ended = current and data:toDeath().who:objectName() == current:objectName()
        end
        if turn_ended then--当前回合结束，或当前回合角色死亡，取消不可明置
            for _, target in sgs.qlist(room:getAllPlayers(true)) do
                room:removePlayerDisableShow(target, self:objectName())
            end
        end
    end,
    can_trigger = function(self, event, room, player, data)
        if event ~= sgs.Damaged or not (player and player:isAlive()
            and player:hasSkill(self:objectName())) then return "" end
        for _, target in sgs.qlist(room:getAlivePlayers()) do
            if target:hasShownAllGenerals() then return self:objectName() end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        local candidates = sgs.SPlayerList()
        for _, target in sgs.qlist(room:getAlivePlayers()) do
            if target:hasShownAllGenerals() then candidates:append(target) end
        end
        local target = room:askForPlayerChosen(player, candidates,
            self:objectName(), "@choulue-target", true, false)
        if not target then return false end
        local target_data = sgs.QVariant()
        target_data:setValue(target)
        player:setTag("choulue_target", target_data)
        room:broadcastSkillInvoke(self:objectName(), player)
        return true
    end,
    on_effect = function(self, event, room, player, data)
        local target = player:getTag("choulue_target"):toPlayer()
        player:removeTag("choulue_target")
        if not (target and target:isAlive() and target:hasShownAllGenerals()) then
            return false
        end
        local draw_num = tonumber(room:askForChoice(player, self:objectName(),
            "1+2", data, "@choulue-draw:" .. target:objectName())) or 1
        target:drawCards(draw_num, self:objectName())
        if not (player:isAlive() and target:isAlive()
            and target:hasShownAllGenerals()) then return false end
        local position = room:askForChoice(player, "choulue_hide", "head+deputy",
            data, "@choulue-hide:" .. target:objectName())
        local head = position == "head"
        target:hideGeneral(head)
        room:setPlayerDisableShow(target, head and "h" or "d", self:objectName())--本回合不可明置主/副将
        return false
    end,
}

zhugezhan_hanjin = sgs.General(extension, "zhugezhan_hanjin", "shu", 3)

mengyin = sgs.CreateTriggerSkill{
    name = "mengyin",
    events = {sgs.EventPhaseEnd},
    frequency = sgs.Skill_Frequent,

    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:getPhase() == sgs.Player_Finish) then
            return ""
        end
        local skill_list = {}
        local owner_list = {}
        for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            local target_num = math.min(5, player:getHandcardNum())
            if owner:isAlive() and owner:objectName() ~= player:objectName()
                and owner:isFriendWith(player)
                and owner:getHandcardNum() < target_num then
                table.insert(skill_list, self:objectName())
                table.insert(owner_list, owner:objectName())
            end
        end
        return table.concat(skill_list, "|"), table.concat(owner_list, "|")
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        if ask_who:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), ask_who)
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        local draw_num = math.min(5, player:getHandcardNum()) - ask_who:getHandcardNum()
        if draw_num > 0 then ask_who:drawCards(draw_num, self:objectName()) end
        return false
    end,
}

zuilunResponse = sgs.CreateZeroCardViewAsSkill{
    name = "zuilunResponse",
    response_pattern = "@@zuilunResponse",

    view_as = function(self)
        local card_id = sgs.Self:getMark("zuilun_card_id") - 1
        if card_id < 0 then return nil end
        return sgs.Sanguosha:getCard(card_id)
    end,
}

zuilunUse = sgs.CreateTriggerSkill{
    name = "zuilunUse",
    events = {sgs.EventPhaseStart, sgs.CardUsed},
    frequency = sgs.Skill_Frequent,

    on_record = function(self, event, room, player, data)
        if event == sgs.CardUsed and player and player:hasFlag("zuilun_using") then
            local use = data:toCardUse()
            local card_id = player:getMark("zuilun_card_id") - 1
            if use.from and use.from:objectName() == player:objectName()
                and use.card and use.card:getEffectiveId() == card_id then
                room:addPlayerMark(player, "zuilun_target_count", use.to:length())
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player and player:isAlive()
            and player:hasSkill(self:objectName())
            and player:getPhase() == sgs.Player_Draw then
            return self:objectName()
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data)
        local cards = room:getNCards(3, false)
        if cards:isEmpty() then return false end

        local move = sgs.CardsMoveStruct()
        move.card_ids = cards
        move.from = nil
        move.from_place = sgs.Player_DrawPile
        move.to = nil
        move.to_place = sgs.Player_PlaceTable
        move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER,
            player:objectName(), self:objectName(), "")
        room:moveCardsAtomic(move, false)

        local remaining = sgs.IntList()
        for _, card_id in sgs.qlist(cards) do remaining:append(card_id) end
        room:setPlayerMark(player, "zuilun_target_count", 0)

        while player:isAlive() and not remaining:isEmpty() do
            room:fillAG(remaining, player)
            local card_id = room:askForAG(player, remaining, true, self:objectName())
            room:clearAG(player)
            if card_id == -1 then break end
            remaining:removeOne(card_id)

            if room:getCardPlace(card_id) == sgs.Player_PlaceTable then
                local card = sgs.Sanguosha:getCard(card_id)
                if card:isAvailable(player) and not player:isCardLimited(card, sgs.Card_MethodUse) then
                    room:setPlayerMark(player, "zuilun_card_id", card_id + 1)
                    player:setFlags("zuilun_using")
                    room:askForUseCard(player, "@@zuilunResponse",
                        "@zuilun-use:::" .. card:objectName(), -1,
                        sgs.Card_MethodUse, true)
                    player:setFlags("-zuilun_using")
                    room:setPlayerMark(player, "zuilun_card_id", 0)
                end
            end
        end

        for i = cards:length() - 1, 0, -1 do
            local card_id = cards:at(i)
            if room:getCardPlace(card_id) == sgs.Player_PlaceTable then
                room:moveCardTo(sgs.Sanguosha:getCard(card_id), nil,
                    sgs.Player_DrawPile, false)
            end
        end

        if player:isAlive() then
            local discard_num = math.max(0, 3 - player:getMark("zuilun_target_count"))
            room:setPlayerMark(player, "zuilun_target_count", 0)
            if discard_num > 0 then
                room:askForDiscard(player, self:objectName(), discard_num,
                    discard_num, false, true, "@zuilun-discard:::" .. tostring(discard_num))
            end
        end
        return false
    end,
}

zhangshiping_hanjin = sgs.General(extension, "zhangshiping_hanjin", "shu", 3)

local function zileiHasThreeTypes(owner)
    local types = {}
    for _, card_id in sgs.qlist(owner:getPile("capital")) do
        types[sgs.Sanguosha:getCard(card_id):getTypeId()] = true
    end
    return types[sgs.Card_TypeBasic] and types[sgs.Card_TypeTrick]
        and types[sgs.Card_TypeEquip]
end

zileiViewHas = sgs.CreateViewHasSkill{
    name = "#zilei-feiying",
    global = true,
    is_viewhas = function(self, player, skill_name, flag)
        if flag ~= "skill" or skill_name ~= "feiying" or not player:isAlive() then
            return false
        end
        if player:hasShownSkill("zilei") and zileiHasThreeTypes(player) then
            return true
        end
        for _, owner in sgs.qlist(player:getAliveSiblings()) do
            if owner:hasShownSkill("zilei") and owner:isFriendWith(player)
                and zileiHasThreeTypes(owner) then return true end
        end
        return false
    end,
}

zilei = sgs.CreateTriggerSkill{
    name = "zilei",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and not player:isNude()
            and (player:getPhase() == sgs.Player_Start
                or player:getPhase() == sgs.Player_Finish)) then return "" end
        local skill_list = {}
        local owner_list = {}
        for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if owner:isAlive() and owner:isFriendWith(player) then
                table.insert(skill_list, self:objectName())
                table.insert(owner_list, owner:objectName())
            end
        end
        return table.concat(skill_list, "|"), table.concat(owner_list, "|")
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        if player:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), ask_who)
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        local old_capital = sgs.IntList()
        for _, card_id in sgs.qlist(ask_who:getPile("capital")) do
            old_capital:append(card_id)
        end
        local max_num = math.min(2, player:getCardCount(true))
        local card_ids = room:askForExchange(player, self:objectName(), max_num, 1,
            "@zilei-put:" .. ask_who:objectName(), "", ".|.|.|hand,equipped")
        if card_ids:isEmpty() then return false end
        ask_who:addToPile("capital", card_ids, true)

        local obtainable = sgs.IntList()
        for _, card_id in sgs.qlist(old_capital) do
            if ask_who:getPile("capital"):contains(card_id) then obtainable:append(card_id) end
        end
        if not obtainable:isEmpty() then
            room:fillAG(obtainable, player)
            local card_id = room:askForAG(player, obtainable, true, self:objectName())
            room:clearAG(player)
            if card_id ~= -1 then
                local reason = sgs.CardMoveReason(
                    sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE,
                    ask_who:objectName(), player:objectName(), self:objectName(), "")
                room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, true)
            end
        end
        return false
    end,
}

YixieCard = sgs.CreateSkillCard{
    name = "YixieCard",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select, source)
        return #targets == 0 and to_select:objectName() ~= source:objectName()
            and not to_select:getEquips():isEmpty() and source:canGetCard(to_select, "e")
    end,
    feasible = function(self, targets, source)
        return #targets == 1
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        if not (target and target:isAlive() and not source:getPile("capital"):isEmpty()) then
            return
        end
        room:fillAG(source:getPile("capital"), source)
        local card_id = room:askForAG(source, source:getPile("capital"), false, "yixie")
        room:clearAG(source)
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,
            source:objectName(), target:objectName(), "yixie", "")
        room:obtainCard(target, sgs.Sanguosha:getCard(card_id), reason, true)
        if source:isAlive() and target:isAlive() and source:canGetCard(target, "e") then
            local equip_id = room:askForCardChosen(source, target, "e", "yixie",
                false, sgs.Card_MethodGet)
            room:obtainCard(source, equip_id, false)
        end
    end,
}

yixie = sgs.CreateZeroCardViewAsSkill{
    name = "yixie",
    view_as = function(self)
        local card = YixieCard:clone()
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card
    end,
    enabled_at_play = function(self, player)
        if player:hasUsed("#YixieCard") or player:getPile("capital"):isEmpty() then
            return false
        end
        for _, target in sgs.qlist(player:getAliveSiblings()) do
            if not target:getEquips():isEmpty() and player:canGetCard(target, "e") then
                return true
            end
        end
        return false
    end,
}

shenpei_hanjin:addSkill(duce)
shenpei_hanjin:addSkill(shuairan)
zhanglu_hanjin:addSkill(mijiao)
zhanglu_hanjin:addSkill(guian)
huoyi_hanjin:addSkill(siju)
huoyi_hanjin:addSkill(zhongjue)
liuba_hanjin:addSkill(liuzhuan)
liuba_hanjin:addSkill(langji)
liuba_hanjin:addSkill(langjiMod)
extension:insertRelatedSkills("langji", "#langji-distance")
sunlang_hanjin:addSkill(juyi)
sunlang_hanjin:addSkill(yingshou)
xiahoulan_hanjin:addSkill(lanqie)
xiahoulan_hanjin:addSkill(jinqi)
zulang_hanjin:addSkill(raoxi)
jiangji_hanjin:addSkill(xuxie)
jiangji_hanjin:addSkill(liulu)
chengpu_hanjin:addSkill(lihuo)
chengpu_hanjin:addSkill(lihuoMod)
chengpu_hanjin:addSkill(chunlao)
extension:insertRelatedSkills("lihuo", "#lihuo-target")
if not sgs.Sanguosha:getSkill("chunlao_attach") then skills:append(chunlaoAttach) end
guyong_hanjin:addSkill(mizhong)
guyong_hanjin:addSkill(bingyi)
zhanghong_hanjin:addSkill(shuoshan)
zhanghong_hanjin:addSkill(roufu)
zhuling_hanjin:addSkill(jixian)
qianshuo_hanjin:addSkill(jibing)
duanwei_hanjin:addSkill(kentun)
duanwei_hanjin:addSkill(xunshou)
liuchong_hanjin:addSkill(jinnu)
liuchong_hanjin:addSkill(weitun)
tangji_hanjin:addSkill(aiwu)
tangji_hanjin:addSkill(juebies)
yanpu_hanjin:addSkill(huantu)
yanpu_hanjin:addSkill(bihuo)
yangbiao_hanjin:addSkill(rangjie)
yangbiao_hanjin:addSkill(yizha)
wangxu_hanjin:addSkill(jianzhi)
liuye_hanjin:addSkill(poyuan)
liuye_hanjin:addSkill(choulue)
zhugezhan_hanjin:addSkill(mengyin)
zhugezhan_hanjin:addSkill(zuilunUse)
if not sgs.Sanguosha:getSkill("zuilunResponse") then skills:append(zuilunResponse) end
zhangshiping_hanjin:addSkill(zilei)
zhangshiping_hanjin:addSkill(yixie)
extension:insertRelatedSkills("zilei", "#zilei-feiying")
if not sgs.Sanguosha:getSkill("#zilei-feiying") then skills:append(zileiViewHas) end

sgs.LoadTranslationTable{
    ["hanjin"] = "汉晋",

    ["shenpei_hanjin"] = "审配",
    ["#shenpei_hanjin"] = "正南义烈",
    ["duce"] = "度策",
    [":duce"] = "准备阶段，你可以与一名其他角色拼点。没赢的角色视为使用一张不指定对方为目标的【调虎离山】，赢的角色视为使用一张【万箭齐发】。",
    ["@duce-pindian"] = "度策：你可以选择一名其他角色与其拼点",
    ["@duce-lure"] = "度策：请选择一至两名角色作为【调虎离山】的目标（不能选择 %src）",
    ["shuairan"] = "率然",
    [":shuairan"] = "阵法技。与你处于同一队列的角色数增加后，当前队列角色各摸一张牌；减少后，当前队列角色各回复1点体力。",

    ["zhanglu_hanjin"] = "张鲁",
    ["#zhanglu_hanjin"] = "米道师君",
    ["mijiao"] = "米教",
    [":mijiao"] = "出牌阶段限一次。你可以令一名与你手牌数相差不大于2的其他角色将手牌调整至与你相同，若其因此摸牌，你可以对其造成1点伤害；若其因此弃牌，你可以令其回复1点体力。",
    ["mijiao_damage"] = "米教",
    ["mijiao_recover"] = "米教",
    ["mijiao_damage:damage"] = "你可以对其造成1点伤害",
    ["mijiao_recover:recover"] = "你可以令其回复1点体力",
    ["guian"] = "归安",
    [":guian"] = "当作为大势力的势力变化后，你可以令至多两名角色各摸一张牌。",
    ["@guian-choose"] = "归安：你可以令至多两名角色各摸一张牌",

    ["huoyi_hanjin"] = "霍弋",
    ["#huoyi_hanjin"] = "孤城忠烈",
    ["siju"] = "死拒",
    [":siju"] = "出牌阶段，若你平置，你可以叠置，然后视为使用一张伤害类锦囊；若没有与你势力相同的其他角色，该锦囊不可响应。",
    ["zhongjue"] = "忠绝",
    [":zhongjue"] = "锁定技。当你受到伤害时，若你横置或叠置，你弃置至少一张牌并防止等量伤害，然后若你没有手牌或体力值为1，你复原武将牌。",
    ["@zhongjue-discard"] = "忠绝：请弃置至少一张牌，防止等量伤害（当前伤害为 %arg 点）",

    ["liuba_hanjin"] = "刘巴",
    ["#liuba_hanjin"] = "财理政通",
    ["liuzhuan"] = "流转",
    [":liuzhuan"] = "当牌因弃置进入弃牌堆时，你可以将其中的方片牌置于武将牌上，称为“币”；结束阶段，你移去所有“币”，视为对至多等量名角色使用一张【无中生有】。",
    ["coin"] = "币",
    ["@liuzhuan-use"] = "流转：请选择至多 %arg 名角色，视为对这些角色使用【无中生有】",
    ["langji"] = "浪迹",
    [":langji"] = "锁定技。若你本回合未成为过牌的目标，你与其他角色的距离以及其他角色与你的距离+1。",

    ["sunlang_hanjin"] = "孙狼",
    ["#sunlang_hanjin"] = "危途义烈",
    ["juyi"] = "拒役",
    [":juyi"] = "当你或体力值为1的其他角色成为伤害类锦囊牌的目标时，你可以取消之并选择一项：1.对使用者使用一张【杀】；2.失去1点体力。",
    ["juyi:juyi_slash"] = "对使用者使用一张【杀】",
    ["juyi:juyi_losehp"] = "失去1点体力",
    ["@juyi-slash"] = "拒役：请对 %src 使用一张【杀】，否则你失去1点体力",
    ["yingshou"] = "应绶",
    [":yingshou"] = "你可以将一张红桃锦囊牌当【杀】使用或打出。",

    ["xiahoulan_hanjin"] = "夏侯岚",
    ["#xiahoulan_hanjin"] = "惊风掠阵",
    ["lanqie"] = "岚切",
    [":lanqie"] = "当你弃置任意角色的牌后，你可以将弃置的牌置于武将牌上，称为“岚”；每回合结束时，你将所有“岚”当指定至多等量目标的【杀】使用。若此【杀】对所有目标均造成过伤害，此技能本轮失效。然后你可以将转化所用的牌交给任意名其他角色。",
    ["storm"] = "岚",
    ["@lanqie-slash"] = "岚切：请选择至多 %arg 名角色作为【杀】的目标",
    ["lanqie_give"] = "岚切",
    ["@lanqie-give"] = "岚切：请选择一名其他角色获得转化所用的【%arg】",
    ["jinqi"] = "金契",
    [":jinqi"] = "若你的另一个武将是女性，你计算体力上限时增加2个单独的阴阳鱼。",

    ["zulang_hanjin"] = "祖郎",
    ["#zulang_hanjin"] = "山越桀帅",
    ["raoxi"] = "扰袭",
    [":raoxi"] = "每轮限两次。其他角色的结束阶段，若你本回合未失去过牌，你可以视为对其使用一张【杀】。",

    ["jiangji_hanjin"] = "蒋济",
    ["#jiangji_hanjin"] = "筹画明达",
    ["xuxie"] = "虚懈",
    [":xuxie"] = "每轮限一次。你可以将一张牌当【无懈可击】使用并交给一名其他角色，本回合你与其不能使用此牌颜色的牌。",
    ["@xuxie-give"] = "虚懈：请选择一名其他角色，结算后将转化所用的牌交给其",
    ["liulu"] = "流赂",
    [":liulu"] = "当你受到其他角色的伤害后，或其他角色得到你的牌后，你可以令其摸一张牌，然后你获得其一张牌。",

    ["chengpu_hanjin"] = "程普",
    ["#chengpu_hanjin"] = "三朝虎臣",
    ["lihuo"] = "疠火",
    [":lihuo"] = "你可以将两张牌当目标数上限+1的【火杀】使用。若此【杀】造成的伤害大于1，你可以令你与一名与你势力相同的其他角色各获得一个阴阳鱼标记。",
    ["@lihuo-yinyang"] = "疠火：你可以选择一名与你势力相同的其他角色，你与其各获得一个阴阳鱼标记",
    ["chunlao"] = "醇醪",
    [":chunlao"] = "与你势力相同的角色可以将一个阴阳鱼标记当【酒】使用。",
    ["chunlao_attach"] = "醇醪",
    [":chunlao_attach"] = "你可以将一个阴阳鱼标记当【酒】使用。",

    ["guyong_hanjin"] = "顾雍",
    ["#guyong_hanjin"] = "庙堂股肱",
    ["mizhong"] = "密重",
    [":mizhong"] = "锁定技。当你受到伤害时，若你的手牌数等于体力值，此伤害-1。",
    ["bingyi"] = "秉壹",
    [":bingyi"] = "每回合限一次。当你因弃置而失去牌后，若你的手牌颜色均相同，你可以展示所有手牌，令至多等同于你手牌数的角色各摸一张牌。",
    ["@bingyi-draw"] = "秉壹：请选择至多 %arg 名角色各摸一张牌",

    ["zhanghong_hanjin"] = "张纮",
    ["#zhanghong_hanjin"] = "江东谋主",
    ["shuoshan"] = "说善",
    [":shuoshan"] = "出牌阶段限一次。你可以与一名其他角色拼点，输的角色将手牌摸至与赢的角色相等；若其以此法摸牌数为0，则改为回复1点体力。",
    ["roufu"] = "柔服",
    [":roufu"] = "当你成为其他势力角色使用伤害牌的唯一目标后，你可以令其摸一张牌，然后其交给你X张牌（X为你本回合发动此技能的次数）。",
    ["@roufu-give"] = "柔服：请交给 %src %arg 张牌",

    ["zhuling_hanjin"] = "朱灵",
    ["#zhuling_hanjin"] = "历战陷阵",
    ["jixian"] = "急陷",
    [":jixian"] = "出牌阶段开始时，你可以指定一名符合以下任意项条件的其他角色并摸X张牌（X为其符合的条件数），然后视为对其使用一张【杀】：1.处于队列；2.技能数多于你；3.未受伤。若此【杀】未造成伤害，你失去1点体力。",
    ["@jixian-target"] = "急陷：你可以选择一名符合条件且能成为【杀】目标的其他角色",

    ["qianshuo_hanjin"] = "骞硕",
    ["#qianshuo_hanjin"] = "西园上军",
    ["jibing"] = "集兵",
    [":jibing"] = "摸牌阶段，你可以多摸X张牌（X为与你势力相同的角色数）。若如此做，回合结束时，若你本回合造成的伤害点数小于X，你失去1点体力。",

    ["duanwei_hanjin"] = "段煨",
    ["#duanwei_hanjin"] = "安边营田",
    ["kentun"] = "垦屯",
    [":kentun"] = "出牌阶段结束时，若你此阶段使用的最后一张牌仅指定与你势力相同的角色为目标，你可以摸两张牌。",
    ["xunshou"] = "巡狩",
    [":xunshou"] = "其他角色对与其势力相同的角色造成伤害后，你可以弃置一张牌并对伤害来源造成1点伤害。",

    ["liuchong_hanjin"] = "刘宠",
    ["#liuchong_hanjin"] = "陈国明王",
    ["jinnu"] = "劲弩",
    [":jinnu"] = "出牌阶段结束时，若你此阶段使用过的牌均为【杀】，或使用的最后两张牌均不为【杀】，你可以视为使用一张无距离限制的【杀】。",
    ["@jinnu-slash"] = "劲弩：你可以选择一名角色，视为对其使用一张无距离限制的【杀】",
    ["weitun"] = "威屯",
    [":weitun"] = "限定技。弃牌阶段开始前，若你的手牌数最多，你可以跳过此阶段，视为对任意名角色使用一张【桃园结义】和【五谷丰登】。",
    ["@weitun"] = "威屯",
    ["@weitun-target"] = "威屯：请选择任意名角色，依次对其使用【桃园结义】和【五谷丰登】",

    ["tangji_hanjin"] = "唐姬",
    ["#tangji_hanjin"] = "弘农王妃",
    ["aiwu"] = "哀舞",
    [":aiwu"] = "每回合限一次。其他角色受到伤害后，你可以弃置至少一张牌，然后其可以弃置至少一张牌。若你与其以此法共计弃置的牌数达到三张，你与其各回复1点体力。",
    ["@aiwu-discard"] = "哀舞：你可以弃置至少一张牌，令 %src 可以弃置至少一张牌",
    ["@aiwu-target-discard"] = "哀舞：你可以弃置至少一张牌；若你与 %src 共计弃置至少三张牌，你们各回复1点体力",
    ["juebies"] = "诀别",
    [":juebies"] = "与你势力相同的角色死亡时，其可以令另一名与你势力相同的角色获得其所有牌或摸三张牌。",
    ["@juebies-target"] = "诀别：请选择另一名与唐姬势力相同的角色",
    ["juebies:obtain"] = "获得死亡角色的所有牌",
    ["juebies:draw"] = "摸三张牌",

    ["yanpu_hanjin"] = "阎圃",
    ["#yanpu_hanjin"] = "识治审势",
    ["huantu"] = "缓图",
    [":huantu"] = "每轮限一次。与你势力相同的其他角色摸牌阶段开始前，你可以交给其任意张牌并令其跳过此阶段。此回合结束时，其获得1个珠联璧合标记。",
    ["@huantu-give"] = "缓图：你可以交给 %src 任意张牌，令其跳过摸牌阶段",
    ["bihuo"] = "避祸",
    [":bihuo"] = "限定技。当一名角色脱离濒死时，你可以令其摸三张牌，然后其于本回合内移出游戏。",
    ["@bihuo"] = "避祸",

    ["yangbiao_hanjin"] = "杨彪",
    ["#yangbiao_hanjin"] = "德彰海内",
    ["rangjie"] = "让节",
    [":rangjie"] = "当你受到【杀】的伤害后，你可以令伤害来源展示你的一张手牌。若此牌为红桃，你变更副将；否则，你将一张手牌置于牌堆顶并回复1点体力。",
    ["yizha"] = "义吒",
    [":yizha"] = "出牌阶段限一次。你可以与一名体力值大于你的角色拼点，赢的角色获得输的角色一张牌。若两张拼点牌颜色不同，你摸一张牌。",

    ["wangxu_hanjin"] = "王旭",
    ["#wangxu_hanjin"] = "兼济时艰",
    ["jianzhi"] = "兼治",
    [":jianzhi"] = "出牌阶段限一次。你使用牌时，可以额外指定任意名本回合成为过牌目标的角色为目标。",
    ["@jianzhi-target"] = "兼治：你可以为【%arg】额外指定任意名本回合成为过牌目标的角色",

    ["liuye_hanjin"] = "刘晔",
    ["#liuye_hanjin"] = "佐世之才",
    ["poyuan"] = "破垣",
    [":poyuan"] = "限定技。准备阶段，你可以弃置一个区域内的所有牌，然后弃置一名其他角色至多X+1张牌（X为你以此法弃置的牌数）。",
    ["@poyuan"] = "破垣",
    ["@poyuan-area"] = "破垣：请选择要弃置所有牌的区域",
    ["poyuan:hand"] = "手牌区",
    ["poyuan:equip"] = "装备区",
    ["poyuan:judge"] = "判定区",
    ["@poyuan-target"] = "破垣：请选择一名其他角色，至多弃置其 %arg 张牌",
    ["@poyuan-discard"] = "破垣：已弃置 %arg 张牌，至多可弃置 %arg2 张；是否继续弃置 %src 的牌？",
    ["poyuan_continue:discard"] = "继续弃置",
    ["poyuan_continue:cancel"] = "停止弃置",
    ["choulue"] = "筹略",
    [":choulue"] = "当你受到伤害后，你可以令一名武将牌均明置的角色摸一至两张牌，然后你暗置其一张武将牌，其本回合不能再明置此武将牌。",
    ["@choulue-target"] = "筹略：你可以选择一名武将牌均明置的角色",
    ["@choulue-draw"] = "筹略：请选择令 %src 摸牌的数量",
    ["choulue:1"] = "摸一张牌",
    ["choulue:2"] = "摸两张牌",
    ["@choulue-hide"] = "筹略：请选择要暗置 %src 的哪张武将牌",
    ["choulue_hide:head"] = "主将",
    ["choulue_hide:deputy"] = "副将",

    ["zhugezhan_hanjin"] = "诸葛瞻",
    ["#zhugezhan_hanjin"] = "忠武遗烈",
    ["mengyin"] = "蒙荫",
    [":mengyin"] = "与你势力相同的其他角色结束阶段，你可以将手牌摸至与其相同，至多摸至五张。",
    ["zuilunUse"] = "罪论",
    [":zuilunUse"] = "摸牌阶段开始时，你可以观看牌堆顶三张牌，并依次使用其中任意张牌，然后弃置X张牌（X为3减去你以此法指定过的目标数）。",
    ["@zuilun-use"] = "罪论：你可以使用【%arg】",
    ["@zuilun-discard"] = "罪论：请弃置 %arg 张牌",

    ["zhangshiping_hanjin"] = "张世平",
    ["#zhangshiping_hanjin"] = "资财济世",
    ["zilei"] = "赀累",
    [":zilei"] = "与你势力相同的角色准备阶段和结束阶段，其可以将一至两张牌置于你的武将牌上，称为“赀”，然后其可以获得另一张“赀”。若“赀”包含三种类别，与你势力相同的角色视为拥有“飞影”。",
    ["capital"] = "赀",
    ["@zilei-put"] = "赀累：你可以将一至两张牌作为“赀”置于 %src 的武将牌上",
    ["yixie"] = "易械",
    [":yixie"] = "出牌阶段限一次。你可以将一张“赀”交给一名其他角色，然后获得其装备区的一张牌。",
}

sgs.Sanguosha:addSkills(skills)

return {extension}
