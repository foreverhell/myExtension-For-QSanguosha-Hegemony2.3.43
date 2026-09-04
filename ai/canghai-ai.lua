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

local function canghai_jianxiang_targets(self)
    local min_hand = 1000
    for _, player in sgs.qlist(self.room:getAlivePlayers()) do
        min_hand = math.min(min_hand, player:getHandcardNum())
    end

    local friends = {}
    for _, player in sgs.qlist(self.room:getAlivePlayers()) do
        if player:getHandcardNum() == min_hand and self:isFriend(player) then
            table.insert(friends, player)
        end
    end
    table.sort(friends, function(a, b)
        if self:isWeak(a) ~= self:isWeak(b) then return self:isWeak(a) end
        if a:getHp() ~= b:getHp() then return a:getHp() < b:getHp() end
        return a:getHandcardNum() < b:getHandcardNum()
    end)
    return friends
end

sgs.ai_skill_invoke.JianXiang = function(self, data)
    return #canghai_jianxiang_targets(self) > 0
end

sgs.ai_skill_playerchosen.JianXiang = function(self, targets, max_num, min_num)
    local friends = {}
    for _, target in sgs.qlist(targets) do
        if self:isFriend(target) then table.insert(friends, target) end
    end
    table.sort(friends, function(a, b)
        if self:isWeak(a) ~= self:isWeak(b) then return self:isWeak(a) end
        if a:getHp() ~= b:getHp() then return a:getHp() < b:getHp() end
        return a:getHandcardNum() < b:getHandcardNum()
    end)
    return friends[1]
end
sgs.ai_playerchosen_intention.JianXiang = -50

local function canghai_shenshi_cards(self)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    return cards
end

local function canghai_shenshi_damage_value(self, target)
    if not self:damageIsEffective(target, sgs.DamageStruct_Normal, self.player) then return 0 end
    if self:needDamagedEffects(target, self.player, true)
        or self:needToLoseHp(target, self.player, true, true) then
        return -1
    end

    local value = 4
    if target:getHp() <= 1 then value = value + 6
    elseif self:isWeak(target) then value = value + 2 end
    return value
end

local function canghai_shenshi_card_cost(self, cards, count)
    local cost = 0
    for i = 1, count do
        cost = cost + self:getKeepValue(cards[i])
        if cards[i]:isKindOf("Peach") then cost = cost + 10 end
        if cards[i]:isKindOf("Analeptic") and self:isWeak() then cost = cost + 5 end
    end
    return cost
end

local function canghai_shenshi_plan(self)
    if self.player:hasUsed("#shenshiCard") or self.player:isKongcheng() then return nil end

    local cards = canghai_shenshi_cards(self)
    local source_hand = self.player:getHandcardNum()
    local best
    for _, target in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if self:isFriend(target) then
            local gap = source_hand - target:getHandcardNum()
            local count = math.min(2, math.floor(gap / 2), #cards)
            if count > 0 and (self:isWeak(target) or self:getOverflow() > 0
                or target:hasShownSkills(sgs.cardneed_skill)) then
                local score = count * 1.8 + math.min(count, math.max(0, self:getOverflow()))
                if self:isWeak(target) then score = score + 3 end
                score = score - canghai_shenshi_card_cost(self, cards, count) * 0.12
                if not best or score > best.score then
                    best = { target = target, count = count, score = score }
                end
            end
        elseif self:isEnemy(target) then
            for count = 1, math.min(2, #cards) do
                local discard_num = math.max(0,
                    target:getHandcardNum() - source_hand + count * 2)
                local discard_value = discard_num * 2.2
                if self:needKongcheng(target) and discard_num >= target:getHandcardNum() + count then
                    discard_value = discard_value - 4
                end
                local damage_value = canghai_shenshi_damage_value(self, target)
                local forced_value = math.min(discard_value, damage_value)
                local score = forced_value - count * 1.8
                    - canghai_shenshi_card_cost(self, cards, count) * 0.18
                if not best or score > best.score then
                    best = { target = target, count = count, score = score }
                end
            end
        end
    end

    if not best or best.score < 1.2 then return nil end
    best.card_ids = {}
    for i = 1, best.count do
        table.insert(best.card_ids, cards[i]:getEffectiveId())
    end
    return best
end

local shenshi_canghai_skill = {}
shenshi_canghai_skill.name = "shenshi"
table.insert(sgs.ai_skills, shenshi_canghai_skill)
shenshi_canghai_skill.getTurnUseCard = function(self)
    local plan = canghai_shenshi_plan(self)
    if not plan then return end
    self.shenshi_canghai_plan = plan
    return sgs.Card_Parse("@shenshiCard=" .. table.concat(plan.card_ids, "+") .. "&shenshi")
end

sgs.ai_skill_use_func["#shenshiCard"] = function(card, use, self)
    local plan = self.shenshi_canghai_plan or canghai_shenshi_plan(self)
    if not plan or not plan.target then return end
    use.card = card
    if use.to then use.to:append(plan.target) end
    self.shenshi_canghai_plan = nil
end
sgs.ai_skill_use_func.shenshiCard = sgs.ai_skill_use_func["#shenshiCard"]

sgs.ai_skill_choice.shenshiCard = function(self, choices, data)
    local source = self.room:getCurrent()
    if not source or source:isDead() then return "discard" end

    local discard_num = math.max(0, self.player:getHandcardNum() - source:getHandcardNum())
    if discard_num == 0 then return "discard" end
    if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, source)
        or self:needDamagedEffects(self.player, source, true)
        or self:needToLoseHp(self.player, source, true, true) then
        return "damage"
    end
    if self.player:getHp() <= 1 or self:isWeak() then return "discard" end
    return discard_num >= 2 and "damage" or "discard"
end
sgs.ai_skill_choice.shenshi = sgs.ai_skill_choice.shenshiCard

sgs.ai_use_priority["#shenshiCard"] = 4.5
sgs.ai_use_priority.shenshiCard = 4.5
sgs.ai_use_value["#shenshiCard"] = 6.5
sgs.ai_use_value.shenshiCard = 6.5
sgs.ai_card_intention.shenshiCard = function(self, card, from, tos)
    local to = tos[1]
    if not to then return end
    local discard_num = math.max(0,
        to:getHandcardNum() - from:getHandcardNum() + card:subcardsLength() * 2)
    sgs.updateIntention(from, to, discard_num == 0 and -50 or 50, card)
end

sgs.ai_skill_playerchosen.juece = function(self, targets, max_num, min_num)
    local enemies = {}
    for _, target in sgs.qlist(targets) do
        if self:isEnemy(target)
            and self:damageIsEffective(target, sgs.DamageStruct_Normal, self.player)
            and not self:needDamagedEffects(target, self.player, true)
            and not self:needToLoseHp(target, self.player, true, true) then
            table.insert(enemies, target)
        end
    end
    self:sort(enemies, "hp")
    return enemies[1]
end
sgs.ai_playerchosen_intention.juece = 80

local function canghai_mieji_plan(self)
    if self.player:hasUsed("#miejiCard") then return nil end

    local cards = {}
    for _, card in sgs.qlist(self.player:getHandcards()) do
        if card:isBlack() and card:isKindOf("TrickCard") then table.insert(cards, card) end
    end
    if #cards == 0 then return nil end
    self:sortByUseValue(cards, true)

    local card = cards[1]
    local card_cost = self:getUseValue(card) + self:getKeepValue(card) * 0.3
    if card:isKindOf("Nullification") and self:getCardsNum("Nullification") == 1 then
        card_cost = card_cost + 4
    end

    local best
    for _, target in ipairs(self.enemies) do
        if target:isAlive() then
            local discard_num = math.min(2, target:getCardCount(true))
            local score = 3 + discard_num * 2.2 - card_cost * 0.45
            if self:isWeak(target) then score = score + 1.5 end
            if discard_num > 0 and self:doNotDiscard(target, "he", false, 1) then
                score = score - 2
            end
            if not best or score > best.score then
                best = { card = card, target = target, score = score }
            end
        end
    end
    if not best or best.score < 2 then return nil end
    return best
end

local mieji_canghai_skill = {}
mieji_canghai_skill.name = "mieji"
table.insert(sgs.ai_skills, mieji_canghai_skill)
mieji_canghai_skill.getTurnUseCard = function(self)
    local plan = canghai_mieji_plan(self)
    if not plan then return end
    self.mieji_canghai_plan = plan
    return sgs.Card_Parse("@miejiCard=" .. plan.card:getEffectiveId() .. "&mieji")
end

sgs.ai_skill_use_func["#miejiCard"] = function(card, use, self)
    local plan = self.mieji_canghai_plan or canghai_mieji_plan(self)
    if not plan or not plan.target then return end
    use.card = card
    if use.to then use.to:append(plan.target) end
    self.mieji_canghai_plan = nil
end
sgs.ai_skill_use_func.miejiCard = sgs.ai_skill_use_func["#miejiCard"]

sgs.ai_skill_cardchosen.miejiCard = function(self, who, flags, method, disable_list)
    return self:askForCardChosen(who, flags, "dismantlement", method, disable_list)
end
sgs.ai_skill_cardchosen.mieji = sgs.ai_skill_cardchosen.miejiCard

sgs.ai_skill_choice.startcommand_miejiCard = function(self, choices, data)
    local callback = sgs.ai_skill_choice.startcommand_to
    if callback then return callback(self, choices, data) end
    return choices:split("+")[1]
end
sgs.ai_skill_choice.startcommand_mieji = sgs.ai_skill_choice.startcommand_miejiCard
sgs.ai_skill_choice.docommand_miejiCard = function(self, choices, data)
    local source = data:toPlayer()
    local index = self.player:getMark("command_index")
    if source and self:isFriend(source) then return "yes" end

    if index == 1 then return "yes" end
    if index == 2 then return self.player:getCardCount(true) <= 1 and "yes" or "no" end
    if index == 3 then
        return (self.player:getHp() > 2 or self:needToLoseHp(self.player, source)) and "yes" or "no"
    end
    if index == 4 then return "yes" end
    if index == 5 then return not self.player:faceUp() and "yes" or "no" end
    if index == 6 then
        return (self.player:getHandcardNum() <= 1 and self.player:getEquips():length() <= 1)
            and "yes" or "no"
    end
    return "no"
end
sgs.ai_skill_choice.docommand_mieji = sgs.ai_skill_choice.docommand_miejiCard
sgs.ai_skill_playerchosen.command_miejiCard = sgs.ai_skill_playerchosen.damage
sgs.ai_skill_playerchosen.command_mieji = sgs.ai_skill_playerchosen.damage

local function canghai_fencheng_discard_cost(self, player, discard_num)
    local cards = sgs.QList2Table(player:getCards("he"))
    self:sortByKeepValue(cards)
    local cost = 0
    for i = 1, math.min(discard_num, #cards) do
        cost = cost + math.max(1, self:getKeepValue(cards[i]))
    end
    if player:hasShownSkills(sgs.lose_equip_skill) and player:hasEquip() then cost = cost - 1.5 end
    if self:getOverflow(player) > 0 then cost = cost - math.min(discard_num, self:getOverflow(player)) end
    return math.max(0, cost)
end

local function canghai_fencheng_damage_cost(self, player, source)
    if not self:damageIsEffective(player, sgs.DamageStruct_Fire, source) then return -1 end
    if self:needDamagedEffects(player, source, true)
        or self:needToLoseHp(player, source, true, true) then
        return -1
    end

    local cost = 4
    if player:getHp() <= 1 then cost = 11
    elseif self:isWeak(player) then cost = 7 end
    if player:hasArmorEffect("Vine") then cost = cost + 4 end
    if player:isChained() and not self:isGoodChainTarget(player, source, sgs.DamageStruct_Fire) then
        cost = cost + 3
    end
    return cost
end

local function canghai_fencheng_plan(self)
    if self.player:getMark("@fencheng") <= 0 then return nil end

    local discard_num, score, enemy_hits = 0, 0, 0
    for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        local needed = discard_num + 1
        local damage_cost = canghai_fencheng_damage_cost(self, player, self.player)
        local choice, personal_cost
        if player:getHandcardNum() < needed then
            choice, personal_cost = "damage", damage_cost
        else
            local discard_cost = canghai_fencheng_discard_cost(self, player, needed)
            if damage_cost <= discard_cost then
                choice, personal_cost = "damage", damage_cost
            else
                choice, personal_cost = "discard", discard_cost
            end
        end

        if choice == "discard" then discard_num = needed else discard_num = 0 end
        if self:isEnemy(player) then
            score = score + math.max(0, personal_cost)
            if choice == "damage" and personal_cost > 0 then enemy_hits = enemy_hits + 1 end
        elseif self:isFriend(player) then
            score = score - math.max(0, personal_cost) * 1.25
            if choice == "damage" and player:getHp() <= 1 and personal_cost > 0 then score = score - 8 end
        else
            score = score + math.max(0, personal_cost) * 0.2
        end
    end

    if score < 6 or (enemy_hits == 0 and score < 9) then return nil end
    return { score = score }
end

local fencheng_canghai_skill = {}
fencheng_canghai_skill.name = "fencheng"
table.insert(sgs.ai_skills, fencheng_canghai_skill)
fencheng_canghai_skill.getTurnUseCard = function(self)
    if not canghai_fencheng_plan(self) then return end
    return sgs.Card_Parse("@fenchengCard=.&fencheng")
end

sgs.ai_skill_use_func["#fenchengCard"] = function(card, use, self)
    if canghai_fencheng_plan(self) then use.card = card end
end
sgs.ai_skill_use_func.fenchengCard = sgs.ai_skill_use_func["#fenchengCard"]

sgs.ai_skill_choice.fencheng = function(self, choices, data)
    local discard_num = data:toInt()
    local source = self.room:getCurrent()
    if discard_num <= 0 then discard_num = 1 end
    if not source or source:isDead() then source = self.player end

    if self.player:getHandcardNum() < discard_num then return "damage" end
    local damage_cost = canghai_fencheng_damage_cost(self, self.player, source)
    if damage_cost <= 0 then return "damage" end
    local discard_cost = canghai_fencheng_discard_cost(self, self.player, discard_num)
    return discard_cost < damage_cost and "discard" or "damage"
end

sgs.ai_skill_discard.fencheng = function(self, discard_num, min_num, optional, include_equip)
    return self:askForDiscard("dummy_reason", discard_num, min_num, false, include_equip)
end

sgs.ai_use_priority["#miejiCard"] = 4.6
sgs.ai_use_priority.miejiCard = 4.6
sgs.ai_use_value["#miejiCard"] = 6.5
sgs.ai_use_value.miejiCard = 6.5
sgs.ai_card_intention.miejiCard = 60
sgs.ai_use_priority["#fenchengCard"] = 7
sgs.ai_use_priority.fenchengCard = 7
sgs.ai_use_value["#fenchengCard"] = 8
sgs.ai_use_value.fenchengCard = 8

local function canghai_tianming_discards(self, count)
    local cards = sgs.QList2Table(self.player:getHandcards())
    local jink_num = self:getCardsNum("Jink")
    table.sort(cards, function(a, b)
        local av = self:getKeepValue(a)
        local bv = self:getKeepValue(b)
        if a:isKindOf("Peach") then av = av + 10 end
        if b:isKindOf("Peach") then bv = bv + 10 end
        if a:isKindOf("Jink") and jink_num <= 1 then av = av + 8 end
        if b:isKindOf("Jink") and jink_num <= 1 then bv = bv + 8 end
        if a:isKindOf("Analeptic") and self:isWeak() then av = av + 5 end
        if b:isKindOf("Analeptic") and self:isWeak() then bv = bv + 5 end
        return av < bv
    end)

    local result = {}
    for i = 1, math.min(count, #cards) do
        table.insert(result, cards[i]:getEffectiveId())
    end
    return result, cards
end

sgs.ai_skill_invoke.tianming = function(self, data)
    local hand_num = self.player:getHandcardNum()
    if hand_num == 0 then return true end

    local discard_num = math.min(2, hand_num)
    local ids, cards = canghai_tianming_discards(self, discard_num)
    if #ids < discard_num then return false end

    local use = data:toCardUse()
    local dangerous_slash = use.card and use.card:isKindOf("Slash") and use.from
        and self:slashIsEffective(use.card, self.player, use.from)
        and self:damageIsEffective(self.player, nil, use.from)
    if dangerous_slash and self:getCardsNum("Jink") == 1 then
        for i = 1, discard_num do
            if cards[i]:isKindOf("Jink") then return false end
        end
    end
    if self.player:getHp() <= 1 then
        for i = 1, discard_num do
            if cards[i]:isKindOf("Peach") or cards[i]:isKindOf("Analeptic") then return false end
        end
    end

    local cost = 0
    for i = 1, discard_num do cost = cost + self:getKeepValue(cards[i]) end
    return hand_num < 2 or self:getOverflow() > 0 or cost <= 8
end

sgs.ai_skill_discard.tianming = function(self, discard_num, min_num, optional, include_equip)
    local ids = canghai_tianming_discards(self, discard_num)
    return ids
end

local function canghai_mizhao_limit(player)
    local kingdoms, count = {}, 0
    for _, other in sgs.qlist(player:getAliveSiblings()) do
        if other:hasShownOneGeneral() then
            if other:getRole() == "careerist" then
                count = count + 1
            else
                kingdoms[other:getKingdom()] = true
            end
        end
    end
    kingdoms[player:getKingdom()] = true
    for _ in pairs(kingdoms) do count = count + 1 end
    return math.max(0, count - 1)
end

local function canghai_mizhao_max_number(player)
    local number = 0
    for _, card in sgs.qlist(player:getHandcards()) do
        number = math.max(number, card:getNumber())
    end
    return number
end

local function canghai_mizhao_slash_value(self, from, to)
    local slash = sgs.cloneCard("slash")
    slash:setSkillName("mizhao")
    local value = 0
    if from:canSlash(to, slash, false) and not self:slashProhibit(slash, to, from)
        and self:slashIsEffective(slash, to, from)
        and self:damageIsEffective(to, sgs.DamageStruct_Normal, from) then
        value = 4
        if to:getHp() <= 1 then value = value + 5
        elseif self:isWeak(to) then value = value + 2 end
        if self:needDamagedEffects(to, from, true) then value = value - 4 end
        if self:needToLoseHp(to, from, true, true) then value = value - 3 end
    end
    slash:deleteLater()
    return value
end

local function canghai_mizhao_plan(self)
    if self.player:hasUsed("#mizhao") or self.player:isKongcheng()
        or canghai_mizhao_limit(self.player) < 1 then
        return nil
    end

    local cards = sgs.QList2Table(self.player:getHandcards())
    local best
    for _, card in ipairs(cards) do
        local card_cost = self:getKeepValue(card) * 0.35
        if card:isKindOf("Peach") then card_cost = card_cost + 8 end
        if card:isKindOf("Jink") and self:getCardsNum("Jink") <= 1 then card_cost = card_cost + 5 end

        for _, recipient in sgs.qlist(self.room:getOtherPlayers(self.player)) do
            local recipient_number = math.max(canghai_mizhao_max_number(recipient), card:getNumber())
            for _, opponent in sgs.qlist(self.room:getOtherPlayers(recipient)) do
                if opponent:objectName() ~= self.player:objectName() and not opponent:isKongcheng() then
                    local opponent_number = canghai_mizhao_max_number(opponent)
                    local score
                    if self:isFriend(recipient) and self:isEnemy(opponent) then
                        if recipient_number > opponent_number then
                            score = canghai_mizhao_slash_value(self, recipient, opponent)
                        elseif recipient_number < opponent_number then
                            score = -canghai_mizhao_slash_value(self, opponent, recipient)
                        else
                            score = 0
                        end
                        score = score + (self:isWeak(recipient) and 2.5 or 1) - card_cost
                    elseif self:isEnemy(recipient) and self:isEnemy(opponent) then
                        local winner, loser
                        if recipient_number > opponent_number then
                            winner, loser = recipient, opponent
                        elseif recipient_number < opponent_number then
                            winner, loser = opponent, recipient
                        end
                        score = winner and canghai_mizhao_slash_value(self, winner, loser) - card_cost - 1.5
                            or -card_cost - 1.5
                    end

                    if score and (not best or score > best.score) then
                        best = {
                            card = card,
                            recipient = recipient,
                            opponent = opponent,
                            score = score,
                        }
                    end
                end
            end
        end
    end
    if not best or best.score < 2 then return nil end
    return best
end

local mizhao_canghai_skill = {}
mizhao_canghai_skill.name = "mizhao"
table.insert(sgs.ai_skills, mizhao_canghai_skill)
mizhao_canghai_skill.getTurnUseCard = function(self)
    local plan = canghai_mizhao_plan(self)
    if not plan then return end
    self.mizhao_canghai_plan = plan
    return sgs.Card_Parse("@mizhao=" .. plan.card:getEffectiveId() .. "&mizhao")
end

sgs.ai_skill_use_func["#mizhao"] = function(card, use, self)
    local plan = self.mizhao_canghai_plan or canghai_mizhao_plan(self)
    if not plan or not plan.recipient then return end
    use.card = card
    if use.to then use.to:append(plan.recipient) end
end
sgs.ai_skill_use_func.mizhao = sgs.ai_skill_use_func["#mizhao"]

sgs.ai_skill_playerchosen.mizhao = function(self, targets, max_num, min_num)
    local plan = self.mizhao_canghai_plan
    local recipient_name = self.player:getTag("MizhaoTarget"):toString()
    local recipient = self.room:findPlayer(recipient_name)
    local opponent = plan and plan.opponent or nil

    if recipient and sgs.ais[recipient:objectName()] then
        local max_card = sgs.ais[recipient:objectName()]:getMaxNumberCard(recipient)
        if max_card then sgs.ais[recipient:objectName()].mizhao_card = max_card:getEffectiveId() end
    end

    if opponent then
        for _, target in sgs.qlist(targets) do
            if target:objectName() == opponent:objectName() then
                self.mizhao_canghai_plan = nil
                return target
            end
        end
    end
    if recipient then
        local fallback
        for _, target in sgs.qlist(targets) do
            if self:isEnemy(target) then
                fallback = target
                break
            end
        end
        self.mizhao_canghai_plan = nil
        return fallback
    end
    self.mizhao_canghai_plan = nil
    return nil
end

sgs.ai_skill_pindian.mizhao = function(minusecard, self, requestor, maxcard, mincard)
    if self:isFriend(requestor) then return mincard end
    return maxcard:getNumber() < 6 and minusecard or maxcard
end

sgs.ai_use_priority["#mizhao"] = 5
sgs.ai_use_priority.mizhao = 5
sgs.ai_use_value["#mizhao"] = 7
sgs.ai_use_value.mizhao = 7
sgs.ai_card_intention.mizhao = function(self, card, from, tos)
    local to = tos[1]
    if to then sgs.updateIntention(from, to, self:isFriend(to) and -50 or 20, card) end
end

-- 鲁芝
local xianjing_skill = {}
xianjing_skill.name = "xianjing"
table.insert(sgs.ai_skills, xianjing_skill)
xianjing_skill.getTurnUseCard = function(self)
    if self.player:hasFlag("xianjing_used") or self.player:isKongcheng()
        or not sgs.Slash_IsAvailable(self.player) then
        return
    end
    return sgs.Card_Parse("slash:xianjing[no_suit:0]=.&xianjing")
end

sgs.ai_cardsview.xianjing = function(self, class_name, player)
    if player:hasFlag("xianjing_used") or player:isKongcheng() then return end
    if class_name == "Slash" then
        return "slash:xianjing[no_suit:0]=.&xianjing"
    elseif class_name == "Jink" then
        return "jink:xianjing[no_suit:0]=.&xianjing"
    end
end

sgs.ai_skill_invoke.qingzhong = function(self, data)
    local others = self.room:getOtherPlayers(self.player)
    if others:isEmpty() then return false end

    local min_hand = 1000
    for _, p in sgs.qlist(others) do
        min_hand = math.min(min_hand, p:getHandcardNum())
    end

    for _, p in sgs.qlist(others) do
        if p:getHandcardNum() == min_hand and self:isFriend(p) then
            return true
        end
    end

    if min_hand >= self.player:getHandcardNum() or self:getOverflow() >= 1 then
        return true
    end
    if min_hand == 0 and self:isWeak() and self.player:getHandcardNum() > 2 then
        return false
    end
    return true
end

sgs.ai_skill_playerchosen.qingzhong = function(self, targets)
    local hand_num = self.player:getHandcardNum()
    local best, best_score
    for _, target in sgs.qlist(targets) do
        local difference = target:getHandcardNum() - hand_num
        local score
        if self:isEnemy(target) then
            score = difference * 4
            if self:isWeak(target) and difference <= 0 then score = score - 1 end
        elseif self:isFriend(target) then
            score = -difference * 3
            if self:isWeak(target) then score = score + 2 end
            if self:isWeak() and difference < 0 then score = score - 3 end
        else
            score = difference
        end
        if not best_score or score > best_score then
            best, best_score = target, score
        end
    end
    return best
end

-- 满宠
local function canghai_junxing_plan(self)
    if self.player:hasUsed("#junxing_card") then return nil end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    if #cards < 2 then return nil end
    self:sortByKeepValue(cards)

    local best
    for i = 1, #cards - 1 do
        for j = i + 1, #cards do
            local first, second = cards[i], cards[j]
            if first:getTypeId() ~= second:getTypeId()
                and not first:isKindOf("Peach") and not second:isKindOf("Peach") then
                local used_types = {
                    [first:getTypeId()] = true,
                    [second:getTypeId()] = true,
                }
                local cost = self:getKeepValue(first) + self:getKeepValue(second)
                for _, target in sgs.qlist(self.room:getOtherPlayers(self.player)) do
                    local score = -100
                    if self:isFriend(target) and not target:faceUp() then
                        score = 8 - cost
                    elseif self:isEnemy(target) and target:faceUp() then
                        local has_third_type = false
                        for _, card in sgs.qlist(target:getCards("he")) do
                            if not used_types[card:getTypeId()] then
                                has_third_type = true
                                break
                            end
                        end
                        score = (has_third_type and 3 or 6) - cost
                        if target:getHp() <= 1 then score = score + 4 end
                        if self:isWeak(target) then score = score + 1 end
                        if self:needToLoseHp(target, self.player) then score = score - 2 end
                    end
                    if not best or score > best.score then
                        best = { cards = { first, second }, target = target, score = score }
                    end
                end
            end
        end
    end
    if not best or best.score < 2 then return nil end
    return best
end

local junxing_canghai_skill = {}
junxing_canghai_skill.name = "junxing"
table.insert(sgs.ai_skills, junxing_canghai_skill)
junxing_canghai_skill.getTurnUseCard = function(self)
    local plan = canghai_junxing_plan(self)
    if not plan then return end
    self.junxing_canghai_plan = plan
    return sgs.Card_Parse("@junxing_card=" .. plan.cards[1]:getEffectiveId() .. "+"
        .. plan.cards[2]:getEffectiveId() .. "&junxing")
end

sgs.ai_skill_use_func["#junxing_card"] = function(card, use, self)
    local plan = self.junxing_canghai_plan or canghai_junxing_plan(self)
    if not plan then return end
    use.card = card
    if use.to then use.to:append(plan.target) end
    self.junxing_canghai_plan = nil
end
sgs.ai_skill_use_func.junxing_card = sgs.ai_skill_use_func["#junxing_card"]

sgs.ai_skill_choice.junxing = function(self, choices, data)
    local items = choices:split("+")
    local function contains(choice)
        return table.contains(items, choice)
    end

    if not self.player:faceUp() and contains("junxing_turnOver") then
        return "junxing_turnOver"
    end
    if contains("junxing_loseHp") and self.player:getHp() > 1
        and self:needToLoseHp(self.player, self.room:getCurrent()) then
        return "junxing_loseHp"
    end
    if contains("junxing_discard") then return "junxing_discard" end
    if contains("junxing_loseHp") and self.player:getHp() > 2 then
        return "junxing_loseHp"
    end
    return contains("junxing_turnOver") and "junxing_turnOver" or items[1]
end

sgs.ai_skill_askforag.junxing = function(self, card_ids)
    local cards = {}
    for _, id in ipairs(card_ids) do
        table.insert(cards, sgs.Sanguosha:getCard(id))
    end
    self:sortByKeepValue(cards)
    return cards[1] and cards[1]:getEffectiveId() or -1
end

sgs.ai_use_priority["#junxing_card"] = 3.2
sgs.ai_use_priority.junxing_card = 3.2
sgs.ai_use_value["#junxing_card"] = 5
sgs.ai_use_value.junxing_card = 5
sgs.ai_card_intention["#junxing_card"] = 60
sgs.ai_card_intention.junxing_card = function(self, card, from, tos)
    local target = tos[1]
    if target then sgs.updateIntention(from, target, target:faceUp() and 60 or -40, card) end
end

sgs.canghai_yuce_damage = sgs.canghai_yuce_damage or {}
sgs.ai_skill_invoke.yuce = function(self, data)
    local damage = data:toDamage()
    if not damage.from then return false end
    if self:isFriend(damage.from) and not self:isWeak()
        and (self:needDamagedEffects(self.player, damage.from)
            or self:needToLoseHp(self.player, damage.from)) then
        return false
    end

    local type_count = { [sgs.Card_TypeBasic] = 1, [sgs.Card_TypeTrick] = 0, [sgs.Card_TypeEquip] = 0 }
    for _, card in sgs.qlist(damage.from:getHandcards()) do
        type_count[card:getTypeId()] = (type_count[card:getTypeId()] or 0) + 1
    end
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    local chosen, best_count
    for _, card in ipairs(cards) do
        local count = type_count[card:getTypeId()] or 0
        if not chosen or count > best_count then
            chosen, best_count = card, count
        end
    end
    self.yuce_canghai_card = chosen and chosen:getEffectiveId() or nil
    sgs.canghai_yuce_damage[damage.from:objectName()] = {
        target = self.player:objectName(),
        damage = damage.damage,
    }
    return true
end

sgs.ai_skill_cardchosen.yuce = function(self, who, flags, method, disable_list)
    local id = self.yuce_canghai_card
    self.yuce_canghai_card = nil
    if id then return id end
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    return cards[1] and cards[1]:getEffectiveId() or -1
end

sgs.ai_skill_askforag.yuce = function(self, card_ids)
    local info = sgs.canghai_yuce_damage[self.player:objectName()]
    sgs.canghai_yuce_damage[self.player:objectName()] = nil
    local target = info and self.room:findPlayer(info.target) or nil
    if not target or not self:isEnemy(target) then return -1 end

    local cards = {}
    for _, id in ipairs(card_ids) do
        table.insert(cards, sgs.Sanguosha:getCard(id))
    end
    self:sortByKeepValue(cards)
    local card = cards[1]
    if not card then return -1 end
    if target:getHp() <= (info.damage or 1) or self:getKeepValue(card) <= 4 then
        return card:getEffectiveId()
    end
    return -1
end

-- 许靖
local function canghai_xuming_path_info(self, target, direction)
    local friends, weak_friends, others = 0, 0, 0
    local current
    if direction == "counterclockwise" then
        current = self.player:getNextAlive()
        while current:objectName() ~= target:objectName() do
            if self:isFriend(current) then
                friends = friends + 1
                if self:isWeak(current) then weak_friends = weak_friends + 1 end
            else
                others = others + 1
            end
            current = current:getNextAlive()
            if current:objectName() == self.player:objectName() then break end
        end
    else
        current = target:getNextAlive()
        while current:objectName() ~= self.player:objectName() do
            if self:isFriend(current) then
                friends = friends + 1
                if self:isWeak(current) then weak_friends = weak_friends + 1 end
            else
                others = others + 1
            end
            current = current:getNextAlive()
            if current:objectName() == target:objectName() then break end
        end
    end
    return { friends = friends, weak_friends = weak_friends, others = others }
end

local function canghai_xuming_target(self, card)
    local empty = sgs.SPlayerList()
    local best, best_rank
    for _, target in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if card:targetFilter(empty, target, self.player)
            and self:trickIsEffective(card, target, self.player) then
            for _, direction in ipairs({ "clockwise", "counterclockwise" }) do
                local path = canghai_xuming_path_info(self, target, direction)
                local tier
                if path.others == 0 and path.friends > 0 then
                    tier = 2
                elseif path.others == 0 and path.friends == 0 then
                    tier = 1
                end
                if tier then
                    local target_value = 0
                    if self:isFriend(target) then
                        target_value = self:isWeak(target) and 4 or 2
                    elseif self:isEnemy(target) then
                        target_value = target:hasShownSkills(sgs.cardneed_skill) and -3 or -1
                    end
                    local rank = tier * 1000 + path.friends * 50
                        + path.weak_friends * 10 + target_value
                    if not best_rank or rank > best_rank then
                        best = { target = target, direction = direction, path = path }
                        best_rank = rank
                    end
                end
            end
        end
    end
    return best
end

local function canghai_xuming_card(self)
    if self.player:hasFlag("xuming_used") then return nil end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByUseValue(cards, true)
    local best
    for _, card in ipairs(cards) do
        if card:isKindOf("TrickCard") and not card:isKindOf("ExNihilo") then
            local card_str = ("befriend_attacking:xuming[%s:%s]=%d&xuming"):format(
                card:getSuitString(), card:getNumberString(), card:getEffectiveId())
            local virtual = sgs.Card_Parse(card_str)
            local route = canghai_xuming_target(self, virtual)
            if route then
                local cost = self:getUseValue(card)
                local score = 7 + route.path.friends * 1.5
                    + route.path.weak_friends - cost * 0.45
                if card:isKindOf("BefriendAttacking") then score = score + 3 end
                if self:getOverflow() > 0 then score = score + 1 end
                if not best or score > best.score then
                    best = {
                        card = virtual,
                        target = route.target,
                        direction = route.direction,
                        score = score,
                    }
                end
            end
        end
    end
    if not best or best.score < 2 then return nil end
    return best
end

local xuming_canghai_skill = {}
xuming_canghai_skill.name = "xuming"
table.insert(sgs.ai_skills, xuming_canghai_skill)
xuming_canghai_skill.getTurnUseCard = function(self)
    local plan = canghai_xuming_card(self)
    if not plan then return end
    self.xuming_canghai_plan = plan
    self.xuming_canghai_target = plan.target
    return plan.card
end

local canghai_original_use_befriend_attacking = SmartAI.useCardBefriendAttacking
function SmartAI:useCardBefriendAttacking(card, use)
    if card:getSkillName() ~= "xuming" then
        return canghai_original_use_befriend_attacking(self, card, use)
    end
    local plan = self.xuming_canghai_plan or canghai_xuming_card(self)
    if not plan or not plan.target then return end
    local selected = sgs.SPlayerList()
    if not card:targetFilter(selected, plan.target, self.player)
        or not self:trickIsEffective(card, plan.target, self.player) then
        return
    end
    use.card = card
    if use.to then use.to:append(plan.target) end
    self.xuming_canghai_target = plan.target
end

table.insert(sgs.ai_choicemade_filter.cardUsed, function(self, player, use)
    if not use.card or use.card:getSkillName() ~= "xuming" or use.to:isEmpty() then return end
    local ai = sgs.ais[player:objectName()]
    if ai then ai.xuming_canghai_target = use.to:first() end
end)

sgs.ai_skill_choice.xuming_direction = function(self, choices, data)
    local target = self.xuming_canghai_target
    self.xuming_canghai_target = nil
    local plan = self.xuming_canghai_plan
    self.xuming_canghai_plan = nil
    if plan and target and plan.target:objectName() == target:objectName() then
        return plan.direction
    end
    if not target then return "clockwise" end
    local route = canghai_xuming_target(self, sgs.cloneCard("befriend_attacking"))
    if route and route.target:objectName() == target:objectName() then return route.direction end
    local clockwise = canghai_xuming_path_info(self, target, "clockwise")
    local counterclockwise = canghai_xuming_path_info(self, target, "counterclockwise")
    if counterclockwise.others ~= clockwise.others then
        return counterclockwise.others < clockwise.others and "counterclockwise" or "clockwise"
    end
    return counterclockwise.friends > clockwise.friends and "counterclockwise" or "clockwise"
end

sgs.ai_use_priority.xuming = sgs.ai_use_priority.BefriendAttacking or 9.28
sgs.ai_use_value.xuming = sgs.ai_use_value.BefriendAttacking or 10

sgs.ai_skill_choice.jingde = function(self, choices, data)
    local items = choices:split("+")
    local damage = data:toDamage()
    local source = damage.from
    local own_head = table.contains(items, "self_show_head_general")
    local own_deputy = table.contains(items, "self_show_deputy_general")
    local source_head = table.contains(items, "source_show_head_general")
    local source_deputy = table.contains(items, "source_show_deputy_general")

    local function own_choice()
        if own_head and self.player:inHeadSkills("jingde") then return "self_show_head_general" end
        if own_deputy and self.player:inDeputySkills("jingde") then return "self_show_deputy_general" end
        if own_head then return "self_show_head_general" end
        if own_deputy then return "self_show_deputy_general" end
    end

    if source and self:isEnemy(source) and not self:willShowForDefence() then
        if source_deputy then return "source_show_deputy_general" end
        if source_head then return "source_show_head_general" end
    end
    local choice = own_choice()
    if choice then return choice end
    if source and self:isEnemy(source) then
        if source_deputy then return "source_show_deputy_general" end
        if source_head then return "source_show_head_general" end
    end
    if source_head then return "source_show_head_general" end
    if source_deputy then return "source_show_deputy_general" end
    return items[1]
end

-- 张昌蒲
local function canghai_xingshen_recover_target(self)
    local targets = {}
    for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if player:isWounded() and self:isFriend(player) then
            table.insert(targets, player)
        end
    end
    if #targets == 0 then return nil end
    self:sort(targets, "hp")
    return targets[1]
end

sgs.ai_skill_choice.xingshen = function(self, choices, data)
    local items = choices:split("+")
    local can_discard = table.contains(items, "discard")
    local damage = data and data:toDamage() or nil
    local damage_card = damage and damage.card or nil
    local recover_target = canghai_xingshen_recover_target(self)
    self.xingshen_canghai_discard = nil

    if not damage_card or not recover_target then return "draw" end

    local same_suit, other_suit = {}, {}
    for _, card in sgs.qlist(self.player:getHandcards()) do
        if card:getSuit() == damage_card:getSuit() then
            table.insert(same_suit, card)
        else
            table.insert(other_suit, card)
        end
    end
    self:sortByKeepValue(same_suit)
    self:sortByKeepValue(other_suit)

    if can_discard and #same_suit == 1 then
        local card = same_suit[1]
        if not card:isKindOf("Peach") or recover_target:getHp() <= 1
            or self:getKeepValue(card) <= 4 then
            self.xingshen_canghai_discard = card:getEffectiveId()
            return "discard"
        end
    elseif can_discard and #same_suit == 0 and recover_target:getHp() <= 1
        and other_suit[1] and self:getKeepValue(other_suit[1]) <= 3.5 then
        self.xingshen_canghai_discard = other_suit[1]:getEffectiveId()
        return "discard"
    end
    return "draw"
end

sgs.ai_skill_discard.xingshen = function(self, discard_num, min_num, optional, include_equip)
    local id = self.xingshen_canghai_discard
    self.xingshen_canghai_discard = nil
    if id then return { id } end
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    return cards[1] and { cards[1]:getEffectiveId() } or {}
end

sgs.ai_skill_playerchosen.xingshen = function(self, targets)
    local friends = {}
    for _, target in sgs.qlist(targets) do
        if self:isFriend(target) then table.insert(friends, target) end
    end
    if #friends == 0 then return nil end
    self:sort(friends, "hp")
    return friends[1]
end

sgs.ai_playerchosen_intention.xingshen = -80

local function canghai_yanjiao_target(self)
    local best, best_score
    for _, target in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if target:getKingdom() == self.player:getKingdom()
            and target:getRole() ~= "careerist" and self.player:getRole() ~= "careerist"
            and self:isFriend(target) then
            local effective = self:damageIsEffective(target, sgs.DamageStruct_Normal, self.player)
            if not effective or target:getHp() > 1 then
                local score = 4
                if not effective then
                    score = score + 4
                else
                    score = score - 2
                    if self:needDamagedEffects(target, self.player) then score = score + 4 end
                    if self:needToLoseHp(target, self.player) then score = score + 3 end
                    if self:isWeak(target) then score = score - 3 end
                end
                if target:getHandcardNum() <= 1 then score = score + 1.5 end
                if target:hasShownSkills(sgs.cardneed_skill) then score = score + 1 end
                if not best_score or score > best_score then
                    best, best_score = target, score
                end
            end
        end
    end
    if not best or best_score < 2 then return nil end
    return best
end

local yanjiao_canghai_skill = {}
yanjiao_canghai_skill.name = "yanjiao"
table.insert(sgs.ai_skills, yanjiao_canghai_skill)
yanjiao_canghai_skill.getTurnUseCard = function(self)
    if self.player:hasUsed("#yanjiaoCard") then return end
    local target = canghai_yanjiao_target(self)
    if not target then return end
    self.yanjiao_canghai_target = target
    return sgs.Card_Parse("@yanjiaoCard=.&yanjiao")
end

sgs.ai_skill_use_func["#yanjiaoCard"] = function(card, use, self)
    local target = self.yanjiao_canghai_target or canghai_yanjiao_target(self)
    self.yanjiao_canghai_target = nil
    if not target then return end
    use.card = card
    if use.to then use.to:append(target) end
end
sgs.ai_skill_use_func.yanjiaoCard = sgs.ai_skill_use_func["#yanjiaoCard"]

sgs.ai_use_priority["#yanjiaoCard"] = 6
sgs.ai_use_priority.yanjiaoCard = 6
sgs.ai_use_value["#yanjiaoCard"] = 7
sgs.ai_use_value.yanjiaoCard = 7
sgs.ai_card_intention["#yanjiaoCard"] = -35
sgs.ai_card_intention.yanjiaoCard = -35

-- 钟会
local function canghai_fushu_damage_value(self, source, target)
    if not self:damageIsEffective(target, sgs.DamageStruct_Normal, source) then
        return self:isFriend(target) and 2 or -1
    end
    if self:isEnemy(target) then
        local value = 4
        if target:getHp() <= 1 then value = value + 5 end
        if self:isWeak(target) then value = value + 2 end
        if self:needDamagedEffects(target, source) then value = value - 3 end
        if self:needToLoseHp(target, source) then value = value - 2 end
        return value
    elseif self:isFriend(target) then
        local value = -5
        if self:needDamagedEffects(target, source) then value = value + 5 end
        if self:needToLoseHp(target, source) then value = value + 4 end
        if self:isWeak(target) then value = value - 4 end
        return value
    end
    return -1
end

local function canghai_fushu_plan(self)
    if self.player:hasUsed("#fushu") then return nil end
    local best
    for _, target in sgs.qlist(self.room:getAlivePlayers()) do
        if target:hasShownOneGeneral() then
            local different, same = {}, {}
            for _, player in sgs.qlist(self.room:getOtherPlayers(target)) do
                if player:isFriendWith(target) then
                    table.insert(same, player)
                elseif player:hasShownOneGeneral() then
                    table.insert(different, player)
                end
            end
            if #different > 0 then
                local score = self:isFriend(target) and 6 or (self:isEnemy(target) and -4 or 0)
                score = score + (self:isFriend(target) and -1 or 1.5)
                if target:objectName() == self.player:objectName() then score = score + 2 end
                if target:getHandcardNum() <= 1 and self:isFriend(target) then score = score + 1 end

                local victim, victim_value
                if #same == 0 then
                    score = score + 4
                else
                    for _, candidate in ipairs(same) do
                        local value = canghai_fushu_damage_value(self, target, candidate)
                        if not victim_value or value > victim_value then
                            victim, victim_value = candidate, value
                        end
                    end
                    score = score + (victim_value or -5)
                end
                if not best or score > best.score then
                    best = { target = target, victim = victim, score = score }
                end
            end
        end
    end
    if not best or best.score < 3 then return nil end
    return best
end

local fushu_canghai_skill = {}
fushu_canghai_skill.name = "fushu"
table.insert(sgs.ai_skills, fushu_canghai_skill)
fushu_canghai_skill.getTurnUseCard = function(self)
    local plan = canghai_fushu_plan(self)
    if not plan then return end
    self.fushu_canghai_plan = plan
    return sgs.Card_Parse("@fushu=.&fushu")
end

sgs.canghai_fushu_context = sgs.canghai_fushu_context or nil
sgs.ai_skill_use_func["#fushu"] = function(card, use, self)
    local plan = self.fushu_canghai_plan or canghai_fushu_plan(self)
    self.fushu_canghai_plan = nil
    if not plan then return end
    use.card = card
    if use.to then use.to:append(plan.target) end
    sgs.canghai_fushu_context = {
        source = self.player:objectName(),
        target = plan.target:objectName(),
        victim = plan.victim and plan.victim:objectName() or nil,
    }
end
sgs.ai_skill_use_func.fushu = sgs.ai_skill_use_func["#fushu"]

sgs.ai_skill_playerchosen.fushu = function(self, targets)
    local context = sgs.canghai_fushu_context
    local initial = context and self.room:findPlayer(context.target) or nil
    local is_damage_choice = initial ~= nil
    if is_damage_choice then
        for _, target in sgs.qlist(targets) do
            if not target:isFriendWith(initial) then
                is_damage_choice = false
                break
            end
        end
    end

    if is_damage_choice then
        if context.victim then
            for _, target in sgs.qlist(targets) do
                if target:objectName() == context.victim then
                    sgs.canghai_fushu_context = nil
                    return target
                end
            end
        end
        local target = sgs.ai_skill_playerchosen.damage(self, targets)
        sgs.canghai_fushu_context = nil
        return target
    end

    local candidates = sgs.QList2Table(targets)
    self:sort(candidates, "handcard")
    for _, target in ipairs(candidates) do
        if self:isFriend(target) then return target end
    end
    for _, target in ipairs(candidates) do
        if self:isEnemy(target) and self:needKongcheng(target) then return target end
    end
    for _, target in ipairs(candidates) do
        if self:isEnemy(target) and not target:hasShownSkills(sgs.cardneed_skill) then return target end
    end
    return candidates[1]
end

sgs.ai_use_priority["#fushu"] = 8.5
sgs.ai_use_priority.fushu = 8.5
sgs.ai_use_value["#fushu"] = 8
sgs.ai_use_value.fushu = 8
sgs.ai_card_intention.fushu = function(self, card, from, tos)
    local target = tos[1]
    if target then sgs.updateIntention(from, target, self:isFriend(target) and -30 or 30, card) end
end
