-- AI for extension/canghai.lua
local function canghai_qieting_equip_score(self, current, card)
    local old = self:getSameEquip(card, self.player)
    local gain = self:getUseValue(card)
    local replace_cost = old and self:getKeepValue(old) or 0
    local score = gain - replace_cost

    if self:isEnemy(current) then
        score = score + self:getKeepValue(card) * 0.6
        if card:isKindOf("Armor") and self:needToThrowArmor(current) then
            score = score - 4
        end
    elseif self:isFriend(current) then
        score = score - self:getKeepValue(card)
        if card:isKindOf("Armor") and self:needToThrowArmor(current) then
            score = score + 5
        else
            score = score - 3
        end
    else
        score = score - 1
    end

    if old and old:isKindOf("Armor") and not self:needToThrowArmor(self.player) then
        score = score - 2
    end
    return score
end

local function canghai_qieting_best_equip(self, current)
    if not current or current:isDead() or current:getEquips():isEmpty() then return nil, -1000 end

    local best, best_score
    for _, card in sgs.qlist(current:getEquips()) do
        local score = canghai_qieting_equip_score(self, current, card)
        if not best or score > best_score then
            best = card
            best_score = score
        end
    end
    return best, best_score or -1000
end

sgs.ai_skill_invoke.qietingX = function(self, data)
    local current = data:toPlayer()
    if not current or current:isDead() then current = self.room:getCurrent() end
    if not current or current:isDead() then return false end

    if not current:hasFlag("qietingX_used_card_to_others") then return true end
    if not current:hasFlag("qietingX_damage") and not current:getEquips():isEmpty() then
        local card, score = canghai_qieting_best_equip(self, current)
        self.qietingX_equip_id = card and card:getEffectiveId() or nil
        return card ~= nil and score > 0
    end
    return false
end

sgs.ai_skill_invoke["@qieting-move"] = function(self, data)
    local current = self.room:getCurrent()
    local card, score = canghai_qieting_best_equip(self, current)
    self.qietingX_equip_id = card and card:getEffectiveId() or nil
    return card ~= nil and score > 0
end

sgs.ai_skill_cardchosen.qietingX = function(self, who, flags, method, disable_list)
    if self.qietingX_equip_id then
        local id = self.qietingX_equip_id
        self.qietingX_equip_id = nil
        return id
    end

    local card = canghai_qieting_best_equip(self, who)
    if card then return card:getEffectiveId() end
    return self:askForCardChosen(who, flags, "snatch", method, disable_list)
end

local function canghai_xianzhou_victims(self, receiver, targets)
    local enemies, others = {}, {}
    for _, target in sgs.qlist(targets) do
        if self:isEnemy(target) then
            table.insert(enemies, target)
        elseif not self:isFriend(target) then
            table.insert(others, target)
        end
    end

    self:sort(enemies, "hp")
    self:sort(others, "hp")
    local result = {}
    local function add_targets(list)
        for _, target in ipairs(list) do
            if self:damageIsEffective(target, sgs.DamageStruct_Normal, receiver)
                and not self:needDamagedEffects(target, receiver)
                and not self:needToLoseHp(target, receiver) then
                table.insert(result, target)
            end
        end
    end
    add_targets(enemies)
    add_targets(others)
    return result
end

local function canghai_xianzhou_plan(self)
    local equip_count = self.player:getEquips():length()
    if equip_count == 0 then return nil end

    local equip_cost = 0
    for _, equip in sgs.qlist(self.player:getEquips()) do
        local value = self:getKeepValue(equip)
        if equip:isKindOf("Armor") and self:needToThrowArmor(self.player) then value = -2 end
        equip_cost = equip_cost + math.max(-2, value)
    end

    local best
    for _, receiver in ipairs(self.friends_noself) do
        if receiver:isAlive() then
            local candidates = sgs.SPlayerList()
            for _, target in sgs.qlist(self.room:getOtherPlayers(receiver)) do
                if receiver:inMyAttackRange(target) then candidates:append(target) end
            end
            local victims = canghai_xianzhou_victims(self, receiver, candidates)
            local damage_num = math.min(equip_count, #victims)
            local heal_num = math.min(self.player:getLostHp(), damage_num)
            local score = damage_num * 4 + heal_num * 3 - equip_cost
            for _, equip in sgs.qlist(self.player:getEquips()) do
                local replaced = self:getSameEquip(equip, receiver)
                if replaced then score = score - math.max(0, self:getKeepValue(replaced)) end
            end
            for i = 1, damage_num do
                if victims[i]:getHp() <= 1 then
                    score = score + 5
                elseif self:isWeak(victims[i]) then
                    score = score + 2
                end
            end

            if receiver:hasShownSkills(sgs.need_equip_skill) then score = score + equip_count * 1.5 end
            if receiver:hasShownSkills(sgs.lose_equip_skill) then score = score + 1 end
            if damage_num > 0 and (not best or score > best.score) then
                best = { receiver = receiver, victims = victims, score = score }
            end
        end
    end
    return best
end

local xianzhou_skill = {}
xianzhou_skill.name = "xianzhou"
table.insert(sgs.ai_skills, xianzhou_skill)
xianzhou_skill.getTurnUseCard = function(self)
    if self.player:getMark("@xianzhou") == 0 or self.player:getEquips():isEmpty() then return end
    local plan = canghai_xianzhou_plan(self)
    if not plan or plan.score < 4 then return end
    self.xianzhou_canghai_plan = plan
    return sgs.Card_Parse("@xianzhou_card=.&xianzhou")
end

sgs.ai_skill_use_func["#xianzhou_card"] = function(card, use, self)
    local plan = self.xianzhou_canghai_plan or canghai_xianzhou_plan(self)
    if not plan or not plan.receiver then return end
    self.xianzhou_canghai_plan = plan
    use.card = card
    if use.to then use.to:append(plan.receiver) end
end
sgs.ai_skill_use_func["xianzhou_card"] = sgs.ai_skill_use_func["#xianzhou_card"]

sgs.ai_skill_playerchosen.xianzhou_card = function(self, targets, max_num, min_num)
    local plan = self.xianzhou_canghai_plan
    local receiver = plan and plan.receiver or nil
    local candidates = canghai_xianzhou_victims(self, receiver or self.player, targets)
    local chosen = {}
    max_num = max_num or #candidates
    for _, target in ipairs(candidates) do
        if #chosen >= max_num then break end
        table.insert(chosen, target)
    end
    self.xianzhou_canghai_plan = nil
    return chosen
end

sgs.ai_use_priority["#xianzhou_card"] = 5.2
sgs.ai_use_priority.xianzhou_card = 5.2
sgs.ai_use_value["#xianzhou_card"] = 7
sgs.ai_use_value.xianzhou_card = 7
sgs.ai_card_intention["#xianzhou_card"] = -60
sgs.ai_card_intention.xianzhou_card = -60

local function canghai_huaier_hand(self)
    local groups = {
        red = { count = 0, value = 0, has_peach = false, has_analeptic = false },
        black = { count = 0, value = 0, has_peach = false, has_analeptic = false },
    }
    for _, card in sgs.qlist(self.player:getHandcards()) do
        local color = card:isRed() and "red" or (card:isBlack() and "black" or nil)
        if color then
            local group = groups[color]
            group.count = group.count + 1
            group.value = group.value + self:getKeepValue(card)
            group.has_peach = group.has_peach or card:isKindOf("Peach")
            group.has_analeptic = group.has_analeptic or card:isKindOf("Analeptic")
        end
    end
    return groups
end

local function canghai_huaier_targets(self, candidates)
    local ordered = self:findPlayerToDiscard("hej", false, sgs.Card_MethodGet, candidates, true)
    local result, added = {}, {}
    for _, target in ipairs(ordered) do
        local name = target:objectName()
        if not added[name] and self.player:canGetCard(target, "hej") then
            added[name] = true
            table.insert(result, target)
        end
    end
    return result
end

local function canghai_huaier_plan(self, candidates)
    local groups = canghai_huaier_hand(self)
    if groups.red.count == 0 or groups.black.count == 0 then return nil end

    candidates = candidates or self.room:getOtherPlayers(self.player)
    local targets = canghai_huaier_targets(self, candidates)
    if #targets == 0 then return nil end

    local can_lose_hp = self.player:getHp() > 2
        or (self.player:getHp() > 1 and not self:isWeak())
    local target_limit = can_lose_hp and #targets or math.min(1, #targets)
    local best
    for _, color in ipairs({ "red", "black" }) do
        local group = groups[color]
        local gain = math.min(group.count, target_limit)
        local score = gain * 4.5 - group.value * 0.45
            - math.max(0, group.count - gain) * 3

        if gain >= 2 then
            score = score - (self.player:getHp() == 2 and 8 or 2.5)
        end
        if group.has_peach then score = score - (self.player:isWounded() and 12 or 7) end
        if group.has_analeptic and self:isWeak() then score = score - 5 end
        if self:getOverflow() > 0 then
            score = score + math.min(self:getOverflow(), group.count) * 1.5
        end

        if gain > 0 and (not best or score > best.score) then
            best = { color = color, count = gain, targets = targets, score = score }
        end
    end
    if not best or best.score <= 0 then return nil end
    return best
end

local huaier_skill = {}
huaier_skill.name = "huaier"
table.insert(sgs.ai_skills, huaier_skill)
huaier_skill.getTurnUseCard = function(self)
    if self.player:hasUsed("#huaierCard") or self.player:isKongcheng() then return end
    local plan = canghai_huaier_plan(self)
    if not plan then return end
    self.huaier_canghai_plan = plan
    return sgs.Card_Parse("@huaierCard=.&huaier")
end

sgs.ai_skill_use_func["#huaierCard"] = function(card, use, self)
    local plan = canghai_huaier_plan(self)
    if not plan then
        self.huaier_canghai_plan = nil
        return
    end
    self.huaier_canghai_plan = plan
    use.card = card
end
sgs.ai_skill_use_func.huaierCard = sgs.ai_skill_use_func["#huaierCard"]

sgs.ai_skill_choice.huaier = function(self, choices, data)
    local plan = self.huaier_canghai_plan
    if plan and string.find("+" .. choices .. "+", "+" .. plan.color .. "+", 1, true) then
        return plan.color
    end

    local groups = canghai_huaier_hand(self)
    if groups.red.count > 0 and groups.black.count > 0 then
        return groups.red.value <= groups.black.value and "red" or "black"
    end
    local items = choices:split("+")
    return items[1]
end

sgs.ai_skill_playerchosen.huaierCard = function(self, targets, max_num, min_num)
    local plan = self.huaier_canghai_plan
    local ordered = canghai_huaier_targets(self, targets)
    local wanted = plan and plan.count or max_num
    wanted = math.min(wanted or 0, max_num or #ordered, #ordered)

    local result = {}
    for i = 1, wanted do table.insert(result, ordered[i]) end
    self.huaier_canghai_plan = nil
    return result
end
sgs.ai_skill_playerchosen.huaier = sgs.ai_skill_playerchosen.huaierCard

sgs.ai_skill_cardchosen.huaierCard = function(self, who, flags, method, disable_list)
    return self:askForCardChosen(who, flags, "snatch", method, disable_list)
end
sgs.ai_skill_cardchosen.huaier = sgs.ai_skill_cardchosen.huaierCard

sgs.ai_use_priority["#huaierCard"] = 4.2
sgs.ai_use_priority.huaierCard = 4.2
sgs.ai_use_value["#huaierCard"] = 6
sgs.ai_use_value.huaierCard = 6

local function canghai_xiaoni_target_score(self, target, slash)
    if self:isFriend(target) or self:objectiveLevel(target) <= 0 then return -1000 end
    if self:slashProhibit(slash, target) then return -1000 end
    if not self:slashIsEffective(slash, target, self.player) then return -1000 end
    if not self:damageIsEffective(target, sgs.DamageStruct_Normal, self.player) then return -1000 end

    local score = 4
    if target:getHp() <= 1 then
        score = score + 6
    elseif self:isWeak(target) then
        score = score + 2
    end
    if not sgs.isGoodTarget(target, self.enemies, self) then score = score - 2 end
    if self:needDamagedEffects(target, self.player, true) then score = score - 5 end
    if self:needToLoseHp(target, self.player, true, true) then score = score - 4 end

    local jink_num = getCardsNum("Jink", target, self.player)
    if jink_num > 0 or self:hasEightDiagramEffect(target) then
        local cards_after_jink = math.max(0, target:getCardCount(true) - 1)
        score = score + math.min(3, cards_after_jink) * 1.4
    elseif sgs.card_lack[target:objectName()]["Jink"] == 1 then
        score = score + 1
    end
    return score
end

local function canghai_xiaoni_plan(self)
    if self.player:getMark("@xiaoni") <= 0 then return nil end

    local slash = sgs.cloneCard("slash")
    slash:setSkillName("xiaoni")
    local scored = {}
    for _, target in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        local score = canghai_xiaoni_target_score(self, target, slash)
        if score > 1 then table.insert(scored, { target = target, score = score }) end
    end
    slash:deleteLater()

    table.sort(scored, function(a, b) return a.score > b.score end)
    local targets, total = {}, 0
    for _, item in ipairs(scored) do
        table.insert(targets, item.target)
        total = total + item.score
    end
    if #targets == 0 or (total < 7 and not (targets[1]:getHp() <= 1)) then return nil end
    return { targets = targets, score = total }
end

local xiaoni_canghai_skill = {}
xiaoni_canghai_skill.name = "xiaoni"
table.insert(sgs.ai_skills, xiaoni_canghai_skill)
xiaoni_canghai_skill.getTurnUseCard = function(self)
    local plan = canghai_xiaoni_plan(self)
    if not plan then return end
    self.xiaoni_canghai_plan = plan
    return sgs.Card_Parse("@xiaoniCard=.&xiaoni")
end

sgs.ai_skill_use_func["#xiaoniCard"] = function(card, use, self)
    local plan = self.xiaoni_canghai_plan or canghai_xiaoni_plan(self)
    if not plan then return end

    use.card = card
    if use.to then
        for _, target in ipairs(plan.targets) do use.to:append(target) end
    end
    self.xiaoni_canghai_plan = nil
end
sgs.ai_skill_use_func.xiaoniCard = sgs.ai_skill_use_func["#xiaoniCard"]

sgs.ai_skill_playerchosen.xiaoni = function(self, targets, max_num, min_num)
    local ordered = self:findPlayerToDiscard("he", false, sgs.Card_MethodDiscard, targets, true)
    for _, target in ipairs(ordered) do
        if self:isEnemy(target) and self.player:canDiscard(target, "he")
            and not self:doNotDiscard(target, "he", false, 1) then
            return target
        end
    end
    return nil
end

sgs.ai_skill_cardchosen.xiaoni = function(self, who, flags, method, disable_list)
    return self:askForCardChosen(who, flags, "dismantlement", method, disable_list)
end

sgs.ai_use_priority["#xiaoniCard"] = 5.5
sgs.ai_use_priority.xiaoniCard = 5.5
sgs.ai_use_value["#xiaoniCard"] = 8
sgs.ai_use_value.xiaoniCard = 8
sgs.ai_card_intention["#xiaoniCard"] = 80
sgs.ai_card_intention.xiaoniCard = 80

local function canghai_mouzhu_attack_plan(self, actor)
    local slash = sgs.cloneCard("slash")
    local duel = sgs.cloneCard("duel")
    slash:setSkillName("_mouzhu")
    duel:setSkillName("_mouzhu")

    local best
    for _, victim in sgs.qlist(self.room:getOtherPlayers(actor)) do
        if self:isEnemy(victim) then
            if not actor:isCardLimited(slash, sgs.Card_MethodUse)
                and not self:slashProhibit(slash, victim, actor)
                and self:slashIsEffective(slash, victim, actor)
                and self:damageIsEffective(victim, sgs.DamageStruct_Normal, actor) then
                local score = 4
                if victim:getHp() <= 1 then score = score + 5
                elseif self:isWeak(victim) then score = score + 2 end
                if self:needDamagedEffects(victim, actor, true) then score = score - 4 end
                if self:needToLoseHp(victim, actor, true, true) then score = score - 3 end
                if getCardsNum("Jink", victim, actor) == 0 then score = score + 1.5 end
                if not best or score > best.score then
                    best = { choice = "slash", victim = victim, score = score }
                end
            end

            if not actor:isCardLimited(duel, sgs.Card_MethodUse)
                and self:trickIsEffective(duel, victim, actor)
                and self:damageIsEffective(victim, sgs.DamageStruct_Normal, actor) then
                local score = 3.5 + (getCardsNum("Slash", actor, self.player)
                    - getCardsNum("Slash", victim, actor)) * 1.2
                if victim:getHp() <= 1 then score = score + 5
                elseif self:isWeak(victim) then score = score + 2 end
                if self:needDamagedEffects(victim, actor, true) then score = score - 4 end
                if self:needToLoseHp(victim, actor, true, true) then score = score - 3 end
                if not best or score > best.score then
                    best = { choice = "duel", victim = victim, score = score }
                end
            end
        end
    end

    slash:deleteLater()
    duel:deleteLater()
    return best
end

local function canghai_mouzhu_plan(self)
    if self.player:hasUsed("#mouzhu") then return nil end

    local best
    local source_hand = self.player:getHandcardNum()
    for _, target in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if not target:isKongcheng() then
            local score
            if self:isFriend(target) and target:getHandcardNum() < source_hand + 2 then
                local attack = canghai_mouzhu_attack_plan(self, target)
                if attack and attack.score > 2 then
                    score = attack.score + math.max(0, self:getOverflow(target)) * 0.5
                    if self:isWeak(target) then score = score - 2 end
                end
            elseif self:isEnemy(target) and target:getHandcardNum() >= source_hand + 2 then
                score = 4 + math.min(2, target:getHandcardNum() - source_hand) * 0.5
                if target:hasShownSkills(sgs.cardneed_skill) then score = score + 1 end
            end

            if score and (not best or score > best.score) then
                best = { target = target, score = score }
            end
        end
    end
    return best
end

local mouzhu_canghai_skill = {}
mouzhu_canghai_skill.name = "mouzhu"
table.insert(sgs.ai_skills, mouzhu_canghai_skill)
mouzhu_canghai_skill.getTurnUseCard = function(self)
    local plan = canghai_mouzhu_plan(self)
    if not plan then return end
    self.mouzhu_canghai_plan = plan
    return sgs.Card_Parse("@mouzhu=.&mouzhu")
end

sgs.ai_skill_use_func["#mouzhu"] = function(card, use, self)
    local plan = self.mouzhu_canghai_plan or canghai_mouzhu_plan(self)
    if not plan or not plan.target then return end
    use.card = card
    if use.to then use.to:append(plan.target) end
    self.mouzhu_canghai_plan = nil
end
sgs.ai_skill_use_func.mouzhu = sgs.ai_skill_use_func["#mouzhu"]

sgs.ai_skill_cardchosen.mouzhu = function(self, who, flags, method, disable_list)
    local cards = sgs.QList2Table(who:getHandcards())
    self:sortByKeepValue(cards)
    if #cards > 0 then return cards[1]:getEffectiveId() end
    return -1
end

sgs.ai_skill_choice.mouzhu = function(self, choices, data)
    local available = {}
    for _, choice in ipairs(choices:split("+")) do available[choice] = true end
    local plan = canghai_mouzhu_attack_plan(self, self.player)
    if plan and available[plan.choice] then
        self.mouzhu_canghai_victim = plan.victim
        self.mouzhu_canghai_choice = plan.choice
        return plan.choice
    end

    local choice = available.slash and "slash" or "duel"
    self.mouzhu_canghai_choice = choice
    return choice
end

sgs.ai_skill_playerchosen.mouzhu = function(self, targets, max_num, min_num)
    local stored = self.mouzhu_canghai_victim
    if stored then
        for _, target in sgs.qlist(targets) do
            if target:objectName() == stored:objectName() then
                self.mouzhu_canghai_victim = nil
                return target
            end
        end
    end

    local plan = canghai_mouzhu_attack_plan(self, self.player)
    if plan and (not self.mouzhu_canghai_choice or plan.choice == self.mouzhu_canghai_choice) then
        self.mouzhu_canghai_victim = nil
        return plan.victim
    end
    for _, target in sgs.qlist(targets) do
        if not self:isFriend(target) then return target end
    end
    return targets:first()
end

sgs.ai_skill_invoke.yanhuo = function(self, data)
    local death = data:toDeath()
    local killer = death.damage and death.damage.from or nil
    if not killer or killer:isDead() or killer:isNude() or self:isFriend(killer) then return false end
    if killer:getCardCount(true) == 1 and killer:getArmor()
        and self:needToThrowArmor(killer) then return false end
    return self.player:getCardCount(true) > 0
end

sgs.ai_skill_cardchosen.yanhuo = function(self, who, flags, method, disable_list)
    return self:askForCardChosen(who, flags, "dismantlement", method, disable_list)
end

sgs.ai_use_priority["#mouzhu"] = 4.8
sgs.ai_use_priority.mouzhu = 4.8
sgs.ai_use_value["#mouzhu"] = 7
sgs.ai_use_value.mouzhu = 7
sgs.ai_card_intention.mouzhu = function(self, card, from, tos)
    local to = tos[1]
    if not to then return end
    local retaliates = to:getHandcardNum() < from:getHandcardNum() + 2
    sgs.updateIntention(from, to, retaliates and -20 or 60, card)
end
