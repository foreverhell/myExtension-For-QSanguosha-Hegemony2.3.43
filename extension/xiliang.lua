xiliang = sgs.Package("xiliang", sgs.Package_GeneralPack)





sgs.LoadTranslationTable{
    ["xiliang"] = "西凉工作室",
}

--建立武将
zhangchunhua = sgs.General(xiliang, "zhangchunhua", "wei", 3, false)
zhangchunhua:addCompanion("simayi")

caoang = sgs.General(xiliang, "caoang", "wei")
caoang:addCompanion("dianwei")


diy_xushu = sgs.General(xiliang, "diy_xushu", "shu")
diy_xushu:addCompanion("wolong")
diy_xushu:addCompanion("zhaoyun")
diy_xushu:setDeputyMaxHpAdjustedValue()

shitao = sgs.General(xiliang, "shitao", "shu")
shitao:addCompanion("wolong")
shitao:addCompanion("diy_xushu")
shitao:setHeadMaxHpAdjustedValue()

chengpu = sgs.General(xiliang, "chengpu", "wu")
chengpu:addCompanion("zhouyu")

guyong = sgs.General(xiliang, "guyong", "wu", 3)

gongsunzan = sgs.General(xiliang, "gongsunzan", "qun")
gongsunzan:setHeadMaxHpAdjustedValue()

chengyu = sgs.General(xiliang, "chengyu", "wei", 3)
chengyu:addCompanion("caopi")

guohuai = sgs.General(xiliang, "guohuai", "wei")
guohuai:addCompanion("zhanghe")

chendao = sgs.General(xiliang, "diy_chendao", "shu")
chendao:addCompanion("zhaoyun")

maliang = sgs.General(xiliang, "maliang", "shu", 3)
maliang:addCompanion("zhugeliang")


quancong = sgs.General(xiliang, "quancong", "wu")

chendeng = sgs.General(xiliang, "chendeng", "qun", 3)



yijibo = sgs.General(xiliang, "yijibo", "shu", 3)

sunhuan = sgs.General(xiliang, "sunhuan", "wu")
sunhuan:addCompanion("luxun")

zhangyi = sgs.General(xiliang, "zhangyi", "shu")
zhangyi:addCompanion("liaohua")

zhuhuan = sgs.General(xiliang, "zhuhuan", "wu")


















local skills = sgs.SkillList()


--[[******************
    建立一些通用内容
]]--******************
--建立空卡

MemptyCard = sgs.CreateSkillCard{
	name = "MemptyCard",
	target_fixed = true,
}
--建立table-qlist函数
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for _, x in ipairs(theTable) do
		result:append(x)
	end
	return result
end

listIndexOf = function(theqlist, theitem)
	local index = 0
	for _, item in sgs.qlist(theqlist) do
		if item == theitem then return index end
		index = index + 1
	end
end

CardList2Table = function(theqlist)
	local result = {}
	for _, item in sgs.qlist(theqlist) do
		table.insert(result, item:getId())
	end
	return result
end

--建立获取服务器玩家函数
function getServerPlayer(room, name)
	for _, p in sgs.qlist(room:getAllPlayers(true)) do
		if p:objectName() == name then return p end
	end
	return nil
end

function skillTriggerable(player, name)
	return player ~= nil and player:isAlive() and player:hasSkill(name)
end

getKingdoms = function(player, will_show)
	local n = 0
    local kingdom_set = {}
	local allplayers = player:getAliveSiblings()
	local same_kingdom = false
	if will_show and not player:hasShownOneGeneral() then
	    for _, p in sgs.qlist(allplayers) do
	        if player:willBeFriendWith(p) then
		        same_kingdom = true
				break
		    end
	    end
		if not same_kingdom then
	        n = n + 1
	    end
	end
	if not same_kingdom then
	    allplayers:append(player)
	end
	for _, p in sgs.qlist(allplayers) do
		if not p:hasShownOneGeneral() then
			continue
		end
		if p:getRole() == "careerist" then
		    n = n + 1
			continue
		end
		if not table.contains(kingdom_set, p:getKingdom()) then table.insert(kingdom_set, p:getKingdom()) end
	end
	return n + #kingdom_set
end




zhuhai = sgs.CreateTriggerSkill{
	name = "zhuhai" ,
	events = {sgs.EventPhaseStart} ,
	can_trigger = function(self, event, room, player, data)
		local skill_list = {}
		local name_list = {}
		if player and player:isAlive() and player:getPhase() == sgs.Player_Finish and player:getMark("Global_DamagePiont_Round") > 0 then
			local xushus = room:findPlayersBySkillName(self:objectName())
            for _, xushu in sgs.qlist(xushus) do
				if xushu:canSlash(player, false) then
					table.insert(skill_list, self:objectName())
					table.insert(name_list, xushu:objectName())
				end
			end
		end
		return table.concat(skill_list,"|"), table.concat(name_list,"|")
	end,
	on_cost = function(self, event, room, player, data, xushu)
		local source_data = sgs.QVariant()
		source_data:setValue(player)
		if xushu:askForSkillInvoke(self:objectName(), source_data) then
		    room:broadcastSkillInvoke(self:objectName(), xushu)
			return true
		end
	end,
    on_effect = function(self, event, room, player, data, xushu)
		room:askForUseSlashTo(xushu, player, "@zhuhai:" .. player:objectName(), false)
		return false
	end,
}

pozhen = sgs.CreateTriggerSkill{
	name = "pozhen" ,
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Limited,
	limit_mark = "@pozhen",
	on_record = function(self, event, room, player, data)
		if player:getPhase() == sgs.Player_NotActive then
			room:setPlayerMark(player, "##pozhen", 0)
		end
	end,
	can_trigger = function(self, event, room, player, data)
		local skill_list = {}
		local name_list = {}
		if player and player:isAlive() and player:getPhase() == sgs.Player_Start then
			local xushus = room:findPlayersBySkillName(self:objectName())
            for _, xushu in sgs.qlist(xushus) do
				if xushu ~= player and xushu:getMark("@pozhen") > 0 then
					table.insert(skill_list, self:objectName())
					table.insert(name_list, xushu:objectName())
				end
			end
		end
		return table.concat(skill_list,"|"), table.concat(name_list,"|")
	end,
	on_cost = function(self, event, room, player, data, xushu)
		local source_data = sgs.QVariant()
		source_data:setValue(player)
		if xushu:askForSkillInvoke(self:objectName(), source_data) then
		    room:broadcastSkillInvoke(self:objectName(), xushu)
			room:doAnimate(1, xushu:objectName(), player:objectName())
			room:doSuperLightbox("xushu", self:objectName())
            room:setPlayerMark(xushu, "@pozhen", 0)
			return true
		end
	end,
    on_effect = function(self, event, room, player, data, xushu)
		room:addPlayerMark(player, "##pozhen")
        room:setPlayerCardLimitation(player, "use,response,recast", ".|.|.|hand", true)

		local targets = sgs.SPlayerList()
		local other_players = room:getOtherPlayers(xushu)
		local all_players = room:getAlivePlayers()

		local can_discard = false

		for _, p in sgs.qlist(other_players) do
			local in_siege_relation = false

			for _, p2 in sgs.qlist(all_players) do
				if player:inSiegeRelation(p, p2) then
					in_siege_relation = true
					break
				end
			end

			if player:inFormationRalation(p) or in_siege_relation then
                targets:append(p)
                if not p:isNude() then
                    can_discard = true
				end
            end
		end

		if can_discard and room:askForChoice(xushu, "pozhen_discard", "yes+no", data, "@pozhen-discard::" .. player:objectName()) == "yes" then
			room:sortByActionOrder(targets)
            for _, p in sgs.qlist(targets) do
                if xushu:canDiscard(p, "he") then
                    room:throwCard(room:askForCardChosen(xushu, p, "he", self:objectName(), false, sgs.Card_MethodDiscard), p, xushu)
                end
            end

		end
		return false
	end,
}

jiancai = sgs.CreateTriggerSkill{
	name = "jiancai",
	events = {sgs.DamageInflicted, sgs.GeneralTransforming},
	relate_to_place = "deputy",
    can_trigger = function(self, event, room, player, data)
		local skill_list = {}
		local name_list = {}
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.damage < player:getHp() then
				return "", ""
			end
		end
		local xushus = room:findPlayersBySkillName(self:objectName())
        for _, xushu in sgs.qlist(xushus) do
			if xushu:isFriendWith(player) then
				table.insert(skill_list, self:objectName())
				table.insert(name_list, xushu:objectName())
			end
		end
		return table.concat(skill_list,"|"), table.concat(name_list,"|")

	end,
	on_cost = function(self, event, room, player, data, xushu)
		if event == sgs.DamageInflicted then
			xushu:setTag("JiancaiDamagedata", data)
			local invoke = xushu:askForSkillInvoke(self, sgs.QVariant("damage::" .. player:objectName()))
			xushu:removeTag("JiancaiDamagedata")
			if invoke then
				room:broadcastSkillInvoke(self:objectName(), xushu)
				room:doAnimate(1, xushu:objectName(), player:objectName())
				return true
			end
		end
		if event == sgs.GeneralTransforming then
			if xushu:askForSkillInvoke(self, sgs.QVariant("transform::" .. player:objectName())) then
				room:broadcastSkillInvoke(self:objectName(), xushu)
				room:doAnimate(1, xushu:objectName(), player:objectName())
				return true
			end
		end
		return false
	end,
    on_effect = function(self, event, room, player, data, xushu)
		if event == sgs.DamageInflicted then
			if xushu:canTransform() then
                room:transformDeputyGeneral(xushu)
			end
			local damage = data:toDamage()
			damage.damage = damage.damage - 1
			data:setValue(damage)
			if damage.damage < 1 then
				return true
			end
		end
		if event == sgs.GeneralTransforming then
			local count = data:toInt() + 2
			data:setValue(count)
		end
		return false
	end,
}

diy_xushu:addSkill(zhuhai)
diy_xushu:addSkill(pozhen)
diy_xushu:addSkill(jiancai)

sgs.LoadTranslationTable{
	["#diy_xushu"] = "化剑为犁",
	["diy_xushu"] = "徐庶",
	["illustrator:diy_xushu"] = "Zero",
	["designer:diy_xushu"] = "梦魇&老萌",
	["zhuhai"] = "诛害",
	[":zhuhai"] = "其他角色的结束阶段，若该角色于此回合内造成过伤害，你可以对其使用一张无距离限制的【杀】。",
	["pozhen"] = "破阵",
	[":pozhen"] = "限定技，其他角色的准备阶段，你可以令其本回合不可使用、打出或重铸手牌；若其处于队列或围攻关系中，你可依次弃置此队列或参与围攻关系的其他角色的一张牌。",
	["jiancai"] = "荐才",
	[":jiancai"] = "副将技，此武将牌上单独的阴阳鱼个数-1。与你势力相同的角色即将受到伤害而进入濒死状态时，你可以令此伤害-1，若如此做，你须变更副将；与你势力相同的角色变更副将时，你可令其额外获得两张备选武将牌。",

	["@zhuhai"] = "是否使用“诛害”，对%src使用【杀】",
	["@pozhen-discard"] = "破阵：是否弃置与%dest处于同一队列或围攻关系的角色的各一张牌",
	["jiancai:damage"] = "是否使用“荐才”，令%dest受到的伤害-1",
	["jiancai:transform"] = "是否使用“荐才”，令%dest变更时的备选武将数+2",

	["cv:diy_xushu"] = "一木",
	["$zhuhai1"] = "仗剑行天下，除恶当此时！",
	["$zhuhai2"] = "广元，速与某诛杀此贼！",
	["$pozhen1"] = "子龙将军自入生门，此阵必破！",
	["$pozhen2"] = "汝阵虽妙，吾必破之。",
	["$jiancai1"] = "老母手书来唤，庶不容不去。",
	["$jiancai2"] = "卧龙绝代奇才，使君何不求之？",
	["~diy_xushu"] = "愿诸公善事使君，勿效庶之无始终……",

}

dizaiSummonCard = sgs.CreateArraySummonCard{
	name = "dizai",
    mute = true,
}

dizaiVS = sgs.CreateArraySummonSkill{
	name = "dizai",
	array_summon_card = dizaiSummonCard,
}

dizai = sgs.CreateTriggerSkill{
	name = "dizai",
	is_battle_array = true,
	battle_array_type = sgs.Siege,
	view_as_skill = dizaiVS,
	events = {sgs.DamageCaused},
	can_preshow = false,
    can_trigger = function(self, event, room, player, data)
		if room:alivePlayerCount() < 4 then return "" end
		local damage = data:toDamage()
		if player and player:isAlive() and damage.to and damage.to:isAlive() and player:isAdjacentTo(damage.to) then
			if damage.card and damage.card:isKindOf("Slash") and not (damage.chain or damage.transfer) then
				local skill_list = {}
				local name_list = {}

				local skill_owners = room:findPlayersBySkillName(self:objectName())
				for _, skill_owner in sgs.qlist(skill_owners) do
					if skill_owner:hasShownSkill(self:objectName()) and player:inSiegeRelation(skill_owner, damage.to) then
						table.insert(skill_list, self:objectName())
						table.insert(name_list, skill_owner:objectName())
					end
				end
				return table.concat(skill_list,"|"), table.concat(name_list,"|")
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, skill_owner)
		if skill_owner and skill_owner:hasShownSkill(self:objectName()) then
			room:sendCompulsoryTriggerLog(skill_owner, self:objectName())
            room:broadcastSkillInvoke(self:objectName(), skill_owner)
			return true
		end
		return false
	end,
    on_effect = function(self, event, room, player, data, skill_owner)
		local damage = data:toDamage()
		local ally = skill_owner
		local enemy = damage.to

		if ally == player then
			for _, p in sgs.qlist(room:getOtherPlayers(skill_owner)) do
				if p:inSiegeRelation(skill_owner, enemy) then
					ally = p
					break
				end
			end
		end

		room:doBattleArrayAnimate(skill_owner, enemy)

		if room:askForDiscard(ally, "dizai_invoke", 1, 1, true, true, "@dizai_discard:" .. player:objectName() .. ":" .. enemy:objectName()) then
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
		return false
	end,
}


chendao:addSkill("wanglie")
chendao:addSkill(dizai)


sgs.LoadTranslationTable{
	["#diy_chendao"] = "白毦督",
	["diy_chendao"] = "陈到",
	["designer:diy_chendao"] = "梦魇狂朝",
	["illustrator:diy_chendao"] = "庄晓健",

	["dizai"] = "地载",
	[":dizai"] = "阵法技，若你是围攻角色，此围攻关系中的围攻角色使用【杀】即将对被围攻角色造成伤害时，另一名围攻角色可弃一张牌，令此伤害+1。",
	["@dizai_discard"] = "地载：是否弃置一张牌令%src对%dest造成的伤害+1",

	["$dizai1"] = "兵法云，久战不利，勿要贪功。",
	["$dizai2"] = "精锐之师，何人能挡？",
}

jutian = sgs.CreateTriggerSkill{
	name = "jutian",
	events = {sgs.Damage},
    can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) then
			local damage = data:toDamage()
			if damage.to and damage.to ~= player and damage.to:isAlive() then
				if not player:hasFlag("jutian1Used") then
					return self:objectName()
				end
				if not player:hasFlag("jutian2Used") then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:isFriendWith(damage.to) then
							return self:objectName()
						end
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		local damage = data:toDamage()
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if (not player:hasFlag("jutian1Used") and p:isFriendWith(player)) or
					(not player:hasFlag("jutian2Used") and damage.to and p:isFriendWith(damage.to)) then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local prompt = "@jutian"

			if not player:hasFlag("jutian1Used") then
				prompt = prompt .. "-fillhandcard"
			end
			if not player:hasFlag("jutian2Used") and damage.to then
				prompt = prompt .. "-discard::" .. damage.to:objectName()
			end

			local target = room:askForPlayerChosen(player, targets, self:objectName(), prompt, true, true)
		    if target then
				local d = sgs.QVariant()
		        d:setValue(target)
		        player:setTag("jutian_target", d)
				room:broadcastSkillInvoke(self:objectName(), player)
		        return true
			end
		end
		return false
	end,
    on_effect = function(self, event, room, player, data)
		local target = player:getTag("jutian_target"):toPlayer()
		player:removeTag("jutian_target")
		if target and target:isAlive() then
			local damage = data:toDamage()
			local choices = {}
			if not player:hasFlag("jutian1Used") and target:isFriendWith(player) then
				table.insert(choices, "fillhandcard")
			end
			if not player:hasFlag("jutian2Used") and damage.to and target:isFriendWith(damage.to) then
				table.insert(choices, "discard")
			end

			local d = sgs.QVariant()
			d:setValue(target)
			local damagedTarget = damage.to
			local choice = room:askForChoice(player, "jutian_choice", table.concat(choices,"+"), d, "@jutian-choice::".. target:objectName(), "fillhandcard+discard")
			if choice == "fillhandcard" then
				room:setPlayerFlag(player, "jutian1Used")
                target:fillHandCards(target:getMaxHp(), self:objectName())
			elseif choice == "discard" then
				room:setPlayerFlag(player, "jutian2Used")
				if target:getHandcardNum() > damagedTarget:getHp() then
                    local x = math.min(target:getHandcardNum() - damagedTarget:getHp(), 5)
                    room:askForDiscard(target, "jutian_discard", x, x)
                end
			end
		end
		return false
	end,
}

zhuhuan:addSkill(jutian)

sgs.LoadTranslationTable{
	["#zhuhuan"] = "气高护前",
	["zhuhuan"] = "朱桓",
	["illustrator:zhuhuan"] = "荧光笔",
	["designer:zhuhuan"] = "梦魇狂朝",
	["jutian"] = "拒天",
	[":jutian"] = "每回合每项限一次，当你对一名其他角色造成伤害后，你可选择一项：1.令一名与其势力相同的角色将手牌弃至该角色的体力值（最多弃置五张）；"..
		"2.令一名与你势力相同的角色将手牌摸至该角色的体力上限。",

	["@jutian-fillhandcard-discard"] = "是否使用“拒天”，选择令与你势力相同的角色补牌或令与%dest势力相同的角色弃牌",
	["@jutian-fillhandcard"] = "是否使用“拒天”，令与你势力相同的角色补牌",
	["@jutian-discard"] = "是否使用“拒天”，令与%dest势力相同的角色弃牌",

	["@jutian-choice"] = "拒天：选择令%dest执行的效果",
	["jutian_choice:fillhandcard"] = "将手牌补至体力上限",
	["jutian_choice:discard"] = "将手牌弃置至体力值",

    ["$jutian2"] = "予以小利，必有大获！",
	["$jutian1"] = "无名小卒，可敢再前进一步？！",
    ["~zhuhuan"] = "这巍巍巨城，吾竟无力撼动……" ,
}

guojue = sgs.CreateTriggerSkill{
	name = "guojue",
	events = {sgs.Dying},
	frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) then
			local dying = data:toDying()
			if dying.who and dying.who:isAlive() and dying.damage and dying.damage.from == player and not dying.who:isNude() then
				return self:objectName() .. "->" .. dying.who:objectName()
			end
		end
		return ""
	end,
    on_cost = function(self, event, room, skill_target, data, player)
		local d = sgs.QVariant()
		d:setValue(skill_target)
		if player:askForSkillInvoke(self:objectName(), d) then
			room:doAnimate(1, player:objectName(), skill_target:objectName())
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false

	end,
    on_effect = function(self, event, room, skill_target, data, player)
		if player:canDiscard(skill_target, "he") then
            local card_id = room:askForCardChosen(player, skill_target, "he", self:objectName(), false, sgs.Card_MethodDiscard)
            room:throwCard(card_id, skill_target, player)
        end
		return false
	end,
}

guojuecompulsory = sgs.CreateTriggerSkill{
	name = "#guojue-compulsory",
	events = {sgs.GeneralShowed},
	frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
		if player:cheakSkillLocation("guojue", data) and player:getMark("guojueUsed") == 0 then
            return self:objectName()
		end
		return ""
	end,
    on_cost = function(self, event, room, player, data)
		room:sendCompulsoryTriggerLog(player, "guojue")
        room:broadcastSkillInvoke("guojue", player)
        room:addPlayerMark(player, "guojueUsed")
        return true
	end,
    on_effect = function(self, event, room, player, data)
		local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "guojue_damage", "@guojue-damage")
        room:damage(sgs.DamageStruct("guojue", player, target))
		return false
	end,
}

shangshiCard = sgs.CreateSkillCard{
	name = "shangshiCard",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	about_to_use = function(self, room, cardUse)
		local source = cardUse.from
		local target = cardUse.to:first()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), "shangshi","")
		room:moveCardTo(self, target, sgs.Player_PlaceHand, reason)
	end
}

shangshigive = sgs.CreateViewAsSkill{
	name = "shangshigive",
	response_pattern = "@@shangshigive",
	view_filter = function(self, selected, to_select)
		return #selected < sgs.Self:getLostHp() and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == sgs.Self:getLostHp() then
			local card = shangshiCard:clone()
			for var=1,#cards do card:addSubcard(cards[var]) end
			return card
		end
	end,
}

shangshi = sgs.CreateMasochismSkill{
	name = "shangshi",
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and not player:isNude() then
			return self:objectName()
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end,
	on_damaged = function(self, player, damage)
		local room = player:getRoom()
		local choice = room:askForChoice(player, self:objectName(), "discard+givecard")
		local invoke = false
        if choice == "discard" then
			invoke = room:askForDiscard(player, "shangshi_discard", 1, 1, true, true, "@shangshi-discard")
        elseif choice == "givecard" then
            invoke = (room:askForUseCard(player, "@@shangshigive", "@shangshi-give:::"..player:getLostHp()) ~= nil)
        end
		if invoke and player:isAlive() then
			local x = player:getLostHp()
			if x > 0 then
				player:drawCards(x, self:objectName())
			end
		end
	end,
}

zhangchunhua:addSkill(guojue)
zhangchunhua:addSkill(guojuecompulsory)
zhangchunhua:addSkill(shangshi)

xiliang:insertRelatedSkills("guojue", "#guojue-compulsory")

if not sgs.Sanguosha:getSkill("shangshigive") then skills:append(shangshigive) end


sgs.LoadTranslationTable{
	["#zhangchunhua"] = "冷血皇后",
	["zhangchunhua"] = "张春华",
	["illustrator:zhangchunhua"] = "雪君S",
	["designer:zhangchunhua"] = "小狼甫心",
	["guojue"] = "果决",
	[":guojue"] = "当你首次明置此武将牌后，对一名其他角色造成1点伤害。当你令其他角色进入濒死状态时，你可弃置其一张牌。",
	["shangshi"] = "伤逝",
	[":shangshi"] = "当你受到伤害后，你可以弃一张牌，或将X张手牌交给一名其他角色，然后你摸X张牌（X为你已损失体力值）。",
	["@guojue-damage"] = "果决：选择一名其他角色对其造成1点伤害",

	["shangshi:givecard"] = "将手牌交给其他角色",
	["shangshi:discard"] = "弃置一张牌",
	["@shangshi-discard"] = "伤逝：选择一张牌弃置",
	["@shangshi-give"] = "伤逝：选择%arg张手牌交给其他角色",

	["$shangshi1"] = "无情者伤人，有情者自伤。",
	["$shangshi2"] = "自损八百，可伤敌一千！",
	["$guojue1"] = "你的死活与我何干？",
	["$guojue2"] = "无来无去，不悔不怨。",
	["~zhangchunhua"] = "怎能如此对我……",
}

shefuCard = sgs.CreateSkillCard{
	name = "shefuCard",
	will_throw = false,
	target_fixed = true,
	mute = true,
	handling_method = sgs.Card_MethodNone,
	extra_cost = function(self, room, card_use)
		room:broadcastSkillInvoke("shefu", 1, card_use.from)
		card_use.from:addToPile("ambush", card_use.card:getSubcards(), false)
	end
}

shefuVS = sgs.CreateOneCardViewAsSkill{
	name = "shefu",
	filter_pattern = ".|.|.|hand",
	view_as = function(self, originalcard)
		local skillcard = shefuCard:clone()
		skillcard:addSubcard(originalcard)
		skillcard:setSkillName(self:objectName())
		skillcard:setShowSkill(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#shefuCard")
	end
}

shefu = sgs.CreateTriggerSkill{
	name = "shefu",
	events = {sgs.CardUsed, sgs.CardResponded, sgs.EventLoseSkill},
	view_as_skill = shefuVS,
	on_record = function(self, event, room, player, data)
		if event == sgs.EventLoseSkill and data:toString():split(":")[1] == self:objectName() and player then
			player:clearOnePrivatePile("ambush")
		end
	end,
    can_trigger = function(self, event, room, player, data)
		if event == sgs.CardUsed or event == sgs.CardResponded then
			local card = nil
			if event == sgs.CardUsed then
				local use = data:toCardUse()
				if use.m_isHandcard then
					card = use.card
				end
			else
				local response = data:toCardResponse()
				if response.m_isUse and response.m_isHandcard then
					card = response.m_card
				end
			end
			if card and card:getTypeId() ~= sgs.Card_TypeSkill then
				local skill_list = {}
				local name_list = {}
				local skill_owners = room:findPlayersBySkillName(self:objectName())
				for _, skill_owner in sgs.qlist(skill_owners) do
					if skill_owner ~= player then
						for _, id in sgs.qlist(skill_owner:getPile("ambush")) do
							if card:sameCardNameWith(sgs.Sanguosha:getCard(id)) then
								table.insert(skill_list, self:objectName())
								table.insert(name_list, skill_owner:objectName())
								break
							end
						end
					end
				end
				return table.concat(skill_list,"|"), table.concat(name_list,"|")
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, ask_who)
		local card = nil
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			card = data:toCardResponse().m_card
		end
		if card then
			local pattern = "%" .. card:objectName()
			if card:isKindOf("Slash") then
				pattern = "Slash"
			elseif card:isKindOf("Nullification") then
				pattern = "Nullification"
			end
			pattern = pattern .. "|.|.|ambush"

			local prompt = "@shefu-invoke:" .. player:objectName() .. "::" .. card:objectName()

			ask_who:setTag("ShefuUsedata", data)
			local ints = room:askForExchange(ask_who, self:objectName(), 1, 0, prompt, "ambush", pattern)
			ask_who:removeTag("ShefuUsedata")

			if not ints:isEmpty() then
				local log1 = sgs.LogMessage()
				log1.type = "#InvokeSkill"
				log1.from = ask_who
				log1.arg = self:objectName()
				room:sendLog(log1)
				room:notifySkillInvoked(ask_who, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 2, ask_who)
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, ask_who:objectName(), "shefu", "")
				local move = sgs.CardsMoveStruct(ints, nil, sgs.Player_DiscardPile, reason)
				room:moveCardsAtomic(move, false)
				return true
			end
		end
		return false
	end,
    on_effect = function(self, event, room, player, data)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			local nullified_list = use.nullified_list
			table.insert(nullified_list, "_ALL_TARGETS")
			use.nullified_list = nullified_list
			data:setValue(use)
		elseif event == sgs.CardResponded then
			local response = data:toCardResponse()
			response.m_card:setTag("ResponseNegated", sgs.QVariant(true))
		end
		return false
	end,
}

shefucompulsory = sgs.CreatePhaseChangeSkill{
	name = "#shefu-compulsory",
	can_trigger = function(self, event, room, player)
		if skillTriggerable(player, "shefu") and player:getPhase() == sgs.Player_Start and player:getPile("ambush"):length() > 2 then
			return self:objectName()
		end
	end,
	on_cost = function(self, event, room, player)
		room:sendCompulsoryTriggerLog(player, "shefu")
		return true
	end,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		local x = player:getPile("ambush"):length() - 2
		if x > 0 then
			local to_throw = room:askForExchange(player, "shefu_remove", x, x, "@shefu-remove:::" .. tostring(x), "ambush")
			if not to_throw:isEmpty() then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, player:objectName(), "shefu", "")
				local move = sgs.CardsMoveStruct(to_throw, nil, sgs.Player_DiscardPile, reason)
				room:moveCardsAtomic(move, false)
			end
		end
		return false
	end,
}

benyu = sgs.CreateMasochismSkill{
	name = "benyu",
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) then
			local damage = data:toDamage()
			if damage.from and damage.from:isAlive() and damage.from:getHandcardNum() ~= player:getHandcardNum() then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		local damage = data:toDamage()
		if damage.from and damage.from:isAlive() then
			if damage.from:getHandcardNum() > player:getHandcardNum() then
				local source_data = sgs.QVariant()
				source_data:setValue(damage.from)
				if player:askForSkillInvoke(self:objectName(), source_data) then
					room:broadcastSkillInvoke(self:objectName(), player)
					room:doAnimate(1, player:objectName(), damage.from:objectName())
					player:setTag("benyu_effect", sgs.QVariant("select"))
					return true
				end
			elseif damage.from:getHandcardNum() < player:getHandcardNum() then
				local x = damage.from:getHandcardNum() + 1
				local prompt = "@benyu-invoke::" .. damage.from:objectName() .. ":" .. tostring(x)
				player:setTag("BenyuDamagedata", data)
				local invoke = room:askForDiscard(player, "benyu", 998, x, true, false, prompt, true)
				player:removeTag("BenyuDamagedata")
				if invoke then
					room:broadcastSkillInvoke(self:objectName(), player)
                    room:doAnimate(1, player:objectName(), damage.from:objectName())
					player:setTag("benyu_effect", sgs.QVariant("damage"))
					return true
				end
			end
		end
		return false
	end,
	on_damaged = function(self, player, damage)
		local room = player:getRoom()
		local effect_name = player:getTag("benyu_effect"):toString()
		player:removeTag("benyu_effect")
		if effect_name == "damage" then
			room:damage(sgs.DamageStruct(self:objectName(), player, damage.from, 1))
		elseif effect_name == "select" and player:isAlive() then
			local source_data = sgs.QVariant()
			source_data:setValue(damage.from)
			local choice = room:askForChoice(player, self:objectName(), "draw+discard", source_data, "@benyu-choose::" .. damage.from:objectName())
            if choice == "draw" then
                player:fillHandCards(math.min(damage.from:getHandcardNum(),5) , self:objectName())
            elseif choice == "discard" then
                local x = math.min(damage.from:getHandcardNum()-player:getHandcardNum(), 5)
                room:askForDiscard(damage.from, "benyu_discard", x, x)
            end
		end
	end,
}

chengyu:addSkill(shefu)
chengyu:addSkill(shefucompulsory)
chengyu:addSkill(benyu)

xiliang:insertRelatedSkills("shefu", "#shefu-compulsory")

sgs.LoadTranslationTable{
	["#chengyu"] = "泰山捧日",
	["chengyu"] = "程昱",
	["illustrator:chengyu"] = "Mr_Sleeping",
	["designer:chengyu"] = "梦魇狂朝",
	["shefu"] = "设伏",
	[":shefu"] = "出牌阶段限一次，你可将一张手牌置于你的武将牌上，称为“伏兵”。当其他角色使用了一张手牌时，你可弃置同牌名的“伏兵”，取消此牌。"..
		"准备阶段开始时，若“伏兵”数大于2，你将“伏兵”弃置至两张。",
	["benyu"] = "贲育",
	[":benyu"] = "当你受到伤害后，你可以选择一项：1.将手牌摸至与伤害来源手牌数相同（最多摸至五张）；2.令伤害来源将手牌数弃至于你手牌数相同（最多弃置五张）；"..
		"3.弃置大于伤害来源手牌数张手牌，然后对其造成1点伤害。",

	["ambush"] = "伏兵",
	["@shefu-invoke"] = "是否使用“设伏”，弃置一张同名的伏兵牌令%src使用的【%arg】无效",
	["@shefu-remove"] = "设伏：选择一张伏兵牌弃置",

	["@benyu-invoke"] = "是否使用“贲育”，弃置至少%arg张手牌对%dest造成1点伤害",
	["@benyu-choose"] = "贲育：选择补充手牌至与%dest相同，或令%dest弃置手牌至与你相同",
	["benyu:draw"] = "补充手牌",
	["benyu:discard"] = "令其弃牌",

    --程昱
    ["$shefu1"] = "圈套已设，埋伏已完，只等敌军进来！",
    ["$shefu2"] = "如此天网，谅你插翅也难逃！",
    ["$benyu2"] = "天下大乱，群雄并起，必有命世！",
    ["$benyu1"] = "曹公智略乃上天所授！",
    ["~chengyu"] = "此诚报效国家之时，吾却休矣！！" ,
}

jingce = sgs.CreateTriggerSkill{
	name = "jingce",
	events = {sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseChanging, sgs.CardFinished},
	on_record = function(self, event, room, player, data)
		if (event == sgs.CardUsed or event == sgs.CardResponded) and player:getPhase() == sgs.Player_Play then
			local card = nil
			if event == sgs.CardUsed then
				local use = data:toCardUse()
				card = use.card
			else
				local response = data:toCardResponse()
				if response.m_isUse then
					card = response.m_card
				end
			end
			if card and card:getTypeId() ~= sgs.Card_TypeSkill then
				room:addPlayerMark(player, "jingce_record")
				local x = player:getMark("jingce_record")
				if player:hasShownSkill(self:objectName()) then
					room:setPlayerMark(player, "#jingce", x)
				end
				card:setTag("JingceRecord", sgs.QVariant(x))
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
		    if change.from == sgs.Player_Play or change.to == sgs.Player_Play then
				room:setPlayerMark(player, "jingce_record", 0)
				room:setPlayerMark(player, "#jingce", 0)
			end
		end
	end,
    can_trigger = function(self, event, room, player, data)
		if event == sgs.CardFinished and skillTriggerable(player, self:objectName()) and player:getPhase() == sgs.Player_Play and player:hasShownOneGeneral() then
			local use = data:toCardUse()
			if use.card and use.card:getTypeId() ~= sgs.Card_TypeSkill and not use.card:isKindOf("ThreatenEmperor") then
				local x = use.card:getTag("JingceRecord"):toInt()
				if x == player:getHp() then
					local all_players = room:getAlivePlayers()
					local can_invoke = false
					for _, p in sgs.qlist(all_players) do
						if p:getHp() < 1 then
							return ""
						end
						if not player:isFriendWith(p) and p:hasShownOneGeneral() then
							can_invoke = true
						end
					end
					if can_invoke then
						return self:objectName()
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if not player:isFriendWith(p) and p:hasShownOneGeneral() then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, self:objectName(), "jingce-invoke", true, true)
		    if target then
				local d = sgs.QVariant()
		        d:setValue(target)
		        player:setTag("jingce_target", d)
				room:broadcastSkillInvoke(self:objectName(), player)
		        return true
			end
		end
		return false
	end,
    on_effect = function(self, event, room, player, data)
		local target = player:getTag("jingce_target"):toPlayer()
		player:removeTag("jingce_target")
		if target and target:isAlive() and player:isAlive() and not player:askCommandto(self:objectName(), target) then
            player:drawCards(2, self:objectName())
		end
		return false
	end,
}

guohuai:addSkill(jingce)

sgs.LoadTranslationTable{
	["#guohuai"] = "垂问秦雍",
	["guohuai"] = "郭淮",
	["designer:guohuai"] = "梦魇狂朝",
	["illustrator:guohuai"] = "DH",
	["jingce"] = "精策",
	[":jingce"] = "出牌阶段，当你使用了第X张牌后（X为你当前体力值），你可以令一名与你势力不同的角色执行军令，若其不执行，你摸两张牌。",
	["jingce-invoke"] = "是否使用“精策”，令一名与你势力不同的角色执行军令",

	["$jingce1"] = "方策精详，有备无患。",
	["$jingce2"] = "精兵拒敌，策守如山。",
	["~guohuai"] = "姜维小儿，竟然……",
}
--[[
mumengviewas = sgs.CreateOneCardViewAsSkill{
	name = "mumengviewas",
	response_or_use = true,
    response_pattern = "@@mumengviewas",
	view_filter = function(self, to_select)
		if to_select:isEquipped() or to_select:getSuit() ~= sgs.Card_Heart then return false end
		local card_name = sgs.Self:property("naman_name"):toString()
		local ex = sgs.Sanguosha:cloneCard(card_name, to_select:getSuit(), to_select:getNumber())
		ex:addSubcard(to_select:getId())
		ex:deleteLater()
		return ex:isAvailable(sgs.Self)
	end,
	view_as = function(self, card)
		local card_name = sgs.Self:property("naman_name"):toString()
		local ex = sgs.Sanguosha:cloneCard(card_name, card:getSuit(), card:getNumber())
		ex:addSubcard(card:getId())
		ex:setSkillName("_mumeng")
        return ex
	end,
}

mumengCard = sgs.CreateSkillCard{
	name = "mumengCard",
	target_fixed = true,
    on_use = function(self, room, source)
		local all_names = {"befriend_attacking", "fight_together"}
		local card_names = {}
		for _,c_name in pairs(all_names)do
			local ex = sgs.Sanguosha:cloneCard(c_name, sgs.Card_SuitToBeDecided, -1)
			ex:setSkillName("_mumeng")
			ex:setCanRecast(false)
			ex:deleteLater()
			if ex:isAvailable(source) then
				table.insert(card_names, c_name)
			end
		end
		if #card_names > 0 then
			local card_name = room:askForChoice(source, "naman", table.concat(card_names, "+"), sgs.QVariant(), "@mumeng-choose", "befriend_attacking+fight_together")
			room:setPlayerProperty(source, "naman_name", sgs.QVariant(card_name))
			room:askForUseCard(source, "@@mumengviewas", "@mumeng-usecard:::" .. card_name, -1, sgs.Card_MethodUse, false)
			room:setPlayerProperty(source, "naman_name", sgs.QVariant())
		end
	end
}


if not sgs.Sanguosha:getSkill("mumengviewas") then skills:append(mumengviewas) end

]]


mumeng = sgs.CreateOneCardViewAsSkill{
	name = "mumeng",
	filter_pattern = ".|heart|.|hand",
	view_as = function(self, to_select)
		local card_name = sgs.Self:getTag("mumeng"):toString()
		if card_name ~= "" then
			local card = sgs.Sanguosha:cloneCard(card_name)
			card:setCanRecast(false)
			card:addSubcard(to_select:getId())
			card:setSkillName("mumeng")
			card:setShowSkill("mumeng")
			return card
		end
	end,
    enabled_at_play = function(self, player)
		return player:usedTimes("ViewAsSkill_mumengCard") == 0
	end,
	vs_card_names = function(self, selected)
		if #selected == 1 then
			return "befriend_attacking+fight_together"
		end
		return ""
	end,
}

naman = sgs.CreateTriggerSkill{
	name = "naman",
	events = {sgs.TargetChoosing},
    can_trigger = function(self, event, room, player, data)
		if event == sgs.TargetChoosing and player and player:isAlive() then
			local use = data:toCardUse()
			if use.card and use.card:getTypeId() ~= sgs.Card_TypeSkill and use.card:isBlack() and room:getUseAliveTargets(use):length() > 1 then
				local skill_list = {}
				local name_list = {}
				local skill_owners = room:findPlayersBySkillName(self:objectName())
				for _, skill_owner in sgs.qlist(skill_owners) do
					if skillTriggerable(skill_owner, self:objectName()) and player ~= skill_owner then
						table.insert(skill_list, self:objectName())
						table.insert(name_list, skill_owner:objectName())
					end
				end
				return table.concat(skill_list,"|"), table.concat(name_list,"|")
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, skill_owner)
		if skill_owner:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), skill_owner)
			return true
		end
		return false
	end,
    on_effect = function(self, event, room, player, data, skill_owner)
		local judge = sgs.JudgeStruct()
		judge.pattern = ".|spade"
		judge.good = false
		judge.who = skill_owner
		judge.reason = self:objectName()
		room:judge(judge)
		if judge:isGood() and skill_owner:isAlive() then
			local use = data:toCardUse()
			local targets = room:getUseExtraTargets(use, false)
			for _, p in sgs.qlist(use.to) do
				if p:isAlive() then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				local prompt = "@naman-target:" .. player:objectName() .. "::" .. use.card:objectName()
				skill_owner:setTag("NamanUsedata", data)
				local target = room:askForPlayerChosen(skill_owner, targets, "naman_target", prompt)
				skill_owner:removeTag("NamanUsedata")
				room:doAnimate(1, skill_owner:objectName(), target:objectName())
				if use.to:contains(target) then
					sgs.Room_cancelTarget(use, target)
				else
					use.to:append(target)
					room:sortByActionOrder(use.to)
				end
				data:setValue(use)
			end
		end
		return false
	end,
}

maliang:addSkill(mumeng)
maliang:addSkill(naman)

sgs.LoadTranslationTable{
	["#maliang"] = "白眉令士",
	["maliang"] = "马良",
	["designer:maliang"] = "梦魇狂朝",
	["illustrator:maliang"] = "biou09",
	["mumeng"] = "穆盟",
	[":mumeng"] = "出牌阶段限一次，你的红桃手牌可作为【远交近攻】或【勠力同心】使用。",
	["naman"] = "纳蛮",
	[":naman"] = "当有其他角色使用黑色牌指定多个目标时，你可进行一次判定，若不为黑桃，你可令这张牌增加或减少一个目标。",

	["@mumeng-choose"] = "穆盟：选择要转化使用的卡牌名称",
	["@mumeng-usecard"] = "穆盟：选择一张红桃手牌转化为【%arg】使用",
	["@naman-target"] = "纳蛮：选择为%src使用的【%arg】增加或减少一个目标",

	["$mumeng1"] = "暴戾之气，伤人害己。",
    ["$mumeng2"] = "休要再起战事。",
    ["$naman2"] = "慢着，让我来！",
    ["$naman1"] = "弃暗投明，光耀门楣！",
    ["~maliang"] = "皇叔为何不听我之言……" ,
}

dingke = sgs.CreateTriggerSkill{
	name = "dingke",
	events = {sgs.CardsMoveOneTime},
    can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and not player:hasFlag("DingkeUsed") then
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					local reasonx = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					if reasonx ~= sgs.CardMoveReason_S_REASON_USE and reasonx ~= sgs.CardMoveReason_S_REASON_RESPONSE then
						if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then
							if move.from and move.from:isAlive() and move.from:getPhase() == sgs.Player_NotActive and player:isFriendWith(move.from) then
								if not current:isKongcheng() or (move.from:objectName() ~= player:objectName() and not player:isKongcheng()) then
									return self:objectName()
								end
							end
						end
					end
				end
			end
		end
		return ""
	end,
    on_cost = function(self, event, room, player, data)
		local current = room:getCurrent()
		if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
			local targets = sgs.SPlayerList()
			if not current:isKongcheng() then
				targets:append(current)
			end
			local move_datas = data:toList()
			for _, move_data in sgs.qlist(move_datas) do
				local move = move_data:toMoveOneTime()
				local reasonx = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
				if reasonx ~= sgs.CardMoveReason_S_REASON_USE and reasonx ~= sgs.CardMoveReason_S_REASON_RESPONSE then
					if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then
						if move.from and move.from:isAlive() and move.from:getPhase() == sgs.Player_NotActive and player:isFriendWith(move.from) then
							if move.from:objectName() ~= player:objectName() and not player:isKongcheng() then
								local move_from = getServerPlayer(room, move.from:objectName())
								if move_from then
									targets:append(move_from)
								end
							end
						end
					end
				end
			end
			if not targets:isEmpty() then
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "dingke-invoke::" .. current:objectName(), true, true)
				if target then
					local d = sgs.QVariant()
					d:setValue(target)
					player:setTag("dingke_target", d)
					player:setFlags("DingkeUsed")
					room:broadcastSkillInvoke(self:objectName(), player)
					return true
				end
			end
		end
		return false
	end,
    on_effect = function(self, event, room, player, data)
		local target = player:getTag("dingke_target"):toPlayer()
		player:removeTag("dingke_targetdingke_target")
		if target and target:isAlive() then
            if target:getPhase() ~= sgs.Player_NotActive then
				room:askForDiscard(target, "dingke_discard", 1, 1)
                if player:isAlive() and player:getMark("@halfmaxhp") < player:getMaxHp() then
                    room:addPlayerMark(player, "@halfmaxhp")
				end
			elseif player:isAlive() and not player:isKongcheng() then
				target:setFlags("DingkeTarget")
                local result = room:askForExchange(player, "dingke_give", 1, 1, "@dingke-give::" .. target:objectName(), "", ".|.|.|hand")
                target:setFlags("-DingkeTarget")
				if not result:isEmpty() then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), self:objectName(), "")
					local move = sgs.CardsMoveStruct(result, target, sgs.Player_PlaceHand, reason)
					room:moveCardsAtomic(move, false)
					if player:isAlive() and player:getMark("@halfmaxhp") < player:getMaxHp() then
						room:addPlayerMark(player, "@halfmaxhp")
					end
				end
			end
		end
		return false
	end,
}

jiyuan = sgs.CreateTriggerSkill{
	name = "jiyuan",
	events = {sgs.CardsMoveOneTime, sgs.Dying},
    can_trigger = function(self, event, room, player, data)
		local dying = data:toDying()
		if skillTriggerable(player, self:objectName()) then
			if event == sgs.CardsMoveOneTime then
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					if move.reason.m_skillName == "dingke" and move.from:objectName() == player:objectName() and move.to and move.to:isAlive() then
						return self:objectName() .. "->" .. move.to:objectName()
					end
				end
			elseif dying.who and dying.who:isAlive() then
				return self:objectName() .. "->" .. dying.who:objectName() --self对dying.who发动技能
			end
		end
		return ""
	end,
    on_cost = function(self, event, room, skill_target, data, player)
		local d = sgs.QVariant()
		d:setValue(skill_target)
		if player:askForSkillInvoke(self:objectName(), d) then
			room:doAnimate(1, player:objectName(), skill_target:objectName())
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
		
	end,
    on_effect = function(self, event, room, skill_target, data, player)
		skill_target:drawCards(1, self:objectName())
		return false
	end,
}

yijibo:addSkill(dingke)
yijibo:addSkill(jiyuan)

sgs.LoadTranslationTable{
	["#yijibo"] = "见礼于世",
	["yijibo"] = "伊籍",
	["illustrator:yijibo"] = "DH",
	["designer:yijibo"] = "梦魇狂朝",
	["dingke"] = "定科",
	[":dingke"] = "每回合限一次，当一名与你势力相同的角色于其回合外不因使用或打出而失去牌后，你可选择一项：1.交给其一张手牌，2.令当前回合者弃置一张手牌。"..
		"然后若你的阴阳鱼标记数少于体力上限，你获得一个阴阳鱼标记。",
	["jiyuan"] = "急援",
	[":jiyuan"] = "当一名角色进入濒死状态时，或你通过“定科”交给一名其他角色牌时，你可令其摸一张牌。",

	["dingke-invoke"] = "是否使用“定科”，选%dest令其弃一张手牌，或选一名失去牌的角色交给其一张手牌",
	["@dingke-give"] = "定科：选择一张手牌交给%dest",

	["$dingke1"] = "一拜一起，未足为劳。",
	["$dingke2"] = "识言观行，方能雍容风仪",
	["$jiyuan1"] = "公若辞，必遭蔡瑁之害矣！",
	["$jiyuan2"] = "情势危急，还请速行！",
	["~yijibo"] = "未能……救得刘公脱险……",
}

kangrui = sgs.CreateTriggerSkill{
	name = "kangrui",
	events = {sgs.EventPhaseChanging, sgs.ConfirmDamage, sgs.TargetChoosing},
	on_record = function(self, event, room, player, data)
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:getSkillName() == self:objectName() then
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		elseif event == sgs.EventPhaseChanging then
			local all_players = room:getAlivePlayers()
			for _, p in sgs.qlist(all_players) do
				room:setPlayerMark(p, "##kangrui", 0)
				p:setFlags("-kangruiUsed")
			end
		end
	end,
    can_trigger = function(self, event, room, player, data)
		if event == sgs.TargetChoosing and player and player:isAlive() and player:getPhase() == sgs.Player_Play then
			local use = data:toCardUse()
			if use.card and use.card:getTypeId() ~= sgs.Card_TypeSkill and use.to:length() == 1 and not use.to:contains(player) then
				local skill_list = {}
				local name_list = {}
				local skill_owners = room:findPlayersBySkillName(self:objectName())
				for _, skill_owner in sgs.qlist(skill_owners) do
					if skillTriggerable(skill_owner, self:objectName()) and player:isFriendWith(skill_owner) and not skill_owner:hasFlag("kangruiUsed") then
						table.insert(skill_list, self:objectName())
						table.insert(name_list, skill_owner:objectName())
					end
				end
				return table.concat(skill_list,"|"), table.concat(name_list,"|")
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, skill_owner)
		local use = data:toCardUse()
        if use.to:length() ~= 1 then return false end
        local target = use.to:first()
        local prompt = "prompt:" .. player:objectName() .. ":" .. target:objectName() .. ":" .. use.card:objectName()

		player:setTag("KangruiUsedata", data)
		local invoke = skill_owner:askForSkillInvoke(self, sgs.QVariant(prompt))
		player:removeTag("KangruiUsedata")
		if invoke then
			room:broadcastSkillInvoke(self:objectName(), skill_owner)
            skill_owner:setFlags("kangruiUsed")
			return true
		end
		return false
	end,
    on_effect = function(self, event, room, player, data, skill_owner)
		local use = data:toCardUse()
        if use.to:length() ~= 1 then return false end
        local target = use.to:first()
		sgs.Room_cancelTarget(use, target)
		data:setValue(use)
		local choices = {"fillhandcards"}
		local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		duel:setSkillName("_kangrui")
		if not target:isCardLimited(duel, sgs.Card_MethodUse) and not target:isProhibited(player, duel) then
			local all_safe = true
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHp() < 1 then
					all_safe = false
					break
				end
			end
			if all_safe then
				table.insert(choices, "useduel")
			end
		end
		local d = sgs.QVariant()
		d:setValue(target)
		local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), d, "@kangrui-choose::" .. target:objectName(), "fillhandcards+useduel")
		if choice == "fillhandcards" then
			player:fillHandCards(player:getHp(), self:objectName())
            room:addPlayerMark(player, "##kangrui")
		elseif choice == "useduel" then
			room:useCard(sgs.CardUseStruct(duel, target, player), false)
		end
		return false
	end,
}

kangruiprohibit = sgs.CreateProhibitSkill{
	name = "#kangrui-prohibit" ,
	is_prohibited = function(self, from, to, card)
		if from and from:getMark("##kangrui") > 0 and card:getTypeId() ~= sgs.Card_TypeSkill then
			return (to and from ~= to)
		end
		return false
	end
}

zhangyi:addSkill(kangrui)
zhangyi:addSkill(kangruiprohibit)

xiliang:insertRelatedSkills("kangrui", "#kangrui-prohibit")

sgs.LoadTranslationTable{
	["#zhangyi"] = "铮虎",
	["zhangyi"] = "张翼",
	["illustrator:zhangyi"] = "影紫C",
	["designer:zhangyi"] = "梦魇狂朝",
	["kangrui"] = "亢锐",
	[":kangrui"] = "与你势力相同的角色的出牌阶段限一次，当其使用牌仅指定一名其以外的角色为目标时，你可取消之，令其选择一项："..
		"1. 将手牌补至体力值，然后本阶段其使用牌不可指定其他角色为目标；"..
		"2. 视为目标角色对其使用一张【决斗】，且该牌造成的伤害+1。",

	["kangrui:prompt"] = "是否使用“亢锐”，取消%src对%dest使用的【%arg】",
	["@kangrui-choose"] = "亢锐：选择将手牌补至体力上限，或视为%dest对你使用【决斗】",
	["kangrui:fillhandcards"] = "补充手牌",
	["kangrui:useduel"] = "被使用决斗",

	["$kangrui1"] = "尔等魍魉，愿试吾剑之利乎？",
	["$kangrui2"] = "诸军鼓励，克复中原，指日可待！",
	["~zhangyi"] = "伯约不见，疲惫之国力乎……",
}



lifuCard = sgs.CreateSkillCard{
	name = "lifuCard",
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
    on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		room:askForDiscard(target, "lifu_discard", 2, 2, false, true)

		if source:isAlive() and target:isAlive() then
			local ids = room:getNCards(1)
			local card = sgs.Sanguosha:getCard(ids:first())
			room:fillAG(ids, source)
			room:askForSkillInvoke(source, "lifu_view", sgs.QVariant("prompt::" .. target:objectName() .. ":" .. card:objectName()), false)
			room:clearAG(source)

			source:setFlags("Global_GongxinOperator")
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEWGIVE, source:objectName(), target:objectName(), "lifu", "")
			room:moveCardTo(card, target, sgs.Player_PlaceHand, reason)
			source:setFlags("-Global_GongxinOperator")

		end
	end,
}

lifu = sgs.CreateZeroCardViewAsSkill{
	name = "lifu",
	view_as = function(self)
		local skillcard = lifuCard:clone()
		skillcard:setSkillName(self:objectName())
		skillcard:setShowSkill(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lifuCard")
	end,
}

yanzhong = sgs.CreatePhaseChangeSkill{
	name = "yanzhong",
	can_trigger = function(self, event, room, player)
		if skillTriggerable(player, self:objectName()) and player:getPhase() == sgs.Player_Finish then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not player:isKongcheng() then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player)
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if not player:isKongcheng() then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, self:objectName(), "@yanzhong", true, true)
		    if target then
				local d = sgs.QVariant()
		        d:setValue(target)
		        player:setTag("yanzhong_target", d)
				room:broadcastSkillInvoke(self:objectName(), player)
		        return true
			end
		end
		return false
	end,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		local target = player:getTag("yanzhong_target"):toPlayer()
		player:removeTag("yanzhong_target")

		if player:isAlive() and target and target:isAlive() and player:canDiscard(target, "h") then
			local suit = room:askForSuit(player, self:objectName())

			local log = sgs.LogMessage()
			log.type = "#ChooseSuit"
			log.from = player
			log.arg = sgs.Card_Suit2String(suit)
			room:sendLog(log)

			local to_throw = room:askForCardChosen(player, target, "h", self:objectName(), false, sgs.Card_MethodDiscard)

			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, player:objectName(), target:objectName(), self:objectName(), "")

			local dis_move = sgs.CardsMoveStruct(to_throw, nil, sgs.Player_DiscardPile, reason)

			local data = room:moveCardsSub(dis_move, true)

			local same_suit = false
			local not_same_suit = false

			local move_datas = data:toList()
			for _, move_data in sgs.qlist(move_datas) do
				local move = move_data:toMoveOneTime()
				if move.from:objectName() == target:objectName() and move.reason.m_reason == sgs.CardMoveReason_S_REASON_DISMANTLE then
					local i = 0
					for _, card_str in pairs(move.cards)do
						local card = sgs.Card_Parse(card_str)
						if card and (move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) == sgs.Player_PlaceEquip) then
							if card:getSuit() == suit then
								same_suit = true
							else
								not_same_suit = true
							end
						end
						i = i + 1
					end
				end
			end

			if same_suit then
				if suit == sgs.Card_Heart then
					room:recover(player, sgs.RecoverStruct())
				end
				if suit == sgs.Card_Diamond then
					player:drawCards(1, self:objectName())
					if player:isChained() then
						room:setPlayerProperty(player, "chained", sgs.QVariant(false))
					end
				end
				if suit == sgs.Card_Spade then
					room:loseHp(target)
				end
				if suit == sgs.Card_Club and player:isAlive() and target:isAlive() and not target:isNude() then
					local cards = room:askForExchange(target, "yuancong_give", 1, 1, "@yanzhong-give:" .. player:objectName())
					if not cards:isEmpty() then
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, target:objectName(), player:objectName(), self:objectName(), "")
						local move = sgs.CardsMoveStruct(cards, player, sgs.Player_PlaceHand, reason)
						room:moveCardsAtomic(move, false)
					end
				end
			end
			if not_same_suit then
				room:askForDiscard(player, "yanzhong_discard", 1, 1, false, true)
			end
		end

	end,
}

guyong:addSkill(lifu)
guyong:addSkill(yanzhong)

sgs.LoadTranslationTable{
	["#guyong"] = "庙堂的玉磬",
	["guyong"] = "顾雍",
	["designer:guyong"] = "锦帆游侠_甘",
	["illustrator:guyong"] = "sky",
	["lifu"] = "礼辅",
	[":lifu"] = "出牌阶段限一次，你可选择一名角色弃置两张牌，然后你观看牌堆顶的一张牌并你将此牌交给该角色。",
	["yanzhong"] = "言中",
	[":yanzhong"] = "结束阶段开始时，你可以选择一个花色并弃置一名其他角色的一张手牌，若你选择的花色与弃置的牌花色相同："..
		"红桃-你回复1点体力；方块-你摸一张牌并重置武将牌；黑桃-其失去1点体力；梅花-其交给你一张牌； 若不同，你弃置一张牌。 ",
	["lifu_view:prompt"] = "礼辅：观看即将交给%dest的【%arg】",
	["@yanzhong"] = "是否使用“言中”，选择一名有手牌的其他角色",
	["@yanzhong-give"] = "言中：选择一张牌交给%src",

    ["$lifu2"] = "审时度势，乃容万变。",
    ["$lifu1"]= "此须斟酌一二。",
    ["$yanzhong1"] = "公正无私，秉持如一。",
    ["$yanzhong2"] = "诸君看仔细了。",
    ["~guyong"] = "病躯渐重，国事难安……" ,
}

huxun = sgs.CreateTriggerSkill{
	name = "huxun",
	events = {sgs.EventPhaseChanging, sgs.Dying},
	on_record = function(self, event, room, player, data)
		if event == sgs.Dying then
			local dying = data:toDying()
			if dying.who ~= player and dying.damage and dying.damage.from == player then
				room:setPlayerFlag(player, "GlobalDyingCaused")
			end
		end
	end,
    can_trigger = function(self, event, room, player, data)
		local skill_list = {}
		local name_list = {}
		if event == sgs.EventPhaseChanging then
		    local change = data:toPhaseChange()
		    if change.to == sgs.Player_NotActive then
			    local skill_owners = room:findPlayersBySkillName(self:objectName())
				for _, skill_owner in sgs.qlist(skill_owners) do
					if skillTriggerable(skill_owner, self:objectName()) and skill_owner:hasFlag("GlobalDyingCaused") then
						table.insert(skill_list, self:objectName())
						table.insert(name_list, skill_owner:objectName())
					end
				end
		    end
		end
		return table.concat(skill_list,"|"), table.concat(name_list,"|")
	end,
    on_cost = function(self, event, room, current, data, player)
		if player:askForSkillInvoke(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false

	end,
    on_effect = function(self, event, room, current, data, player)
		local choices = {"movecard"}

		local can_recover = false
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getMaxHp() >= player:getMaxHp() then
				can_recover = true
				break
			end
		end
		if can_recover then
			table.insert(choices, "gainmaxhp")
		end

        local choice = room:askForChoice(player, self:objectName(), table.concat(choices,"+"), data, "", "gainmaxhp+movecard")
		if choice == "gainmaxhp" then
			local log = sgs.LogMessage()
			log.type = "#GainMaxHp"
			log.from = player
			log.arg = "1"
			room:sendLog(log)
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover)
		elseif choice == "movecard" then
			room:askForQiaobian(player, room:getAlivePlayers(), self:objectName(), "@huxun-move", true, true)
		end
	end,
}

yuancongusecard = sgs.CreateOneCardViewAsSkill{
	name = "yuancongusecard",
	response_pattern = "@@yuancongusecard",
	response_or_use = true,
	view_filter = function(self, to_select)
		return to_select:isAvailable(sgs.Self) and not to_select:isEquipped()
	end,
    view_as = function(self, originalCard)
		return originalCard
	end,
}

yuancong = sgs.CreateTriggerSkill{
	name = "yuancong",
    can_trigger = function(self, event, room, player, data)
		return ""
	end,
    on_cost = function(self, event, room, player, data)
		return false
	end,
}

yuancongother = sgs.CreateTriggerSkill{
	name = "#yuancong-other",
	events = {sgs.EventPhaseEnd},
	frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:getPhase() == sgs.Player_Play and not player:isNude() and 
		player:getMark("Global_DamageTimes_Phase") == 0 then
			local skill_list = {}
			local name_list = {}
			local skill_owners = room:findPlayersBySkillName("yuancong")
			for _, skill_owner in sgs.qlist(skill_owners) do
				if skillTriggerable(skill_owner, "yuancong") and skill_owner:hasShownSkill("yuancong") and 
				player:isFriendWith(skill_owner) then
					table.insert(skill_list, self:objectName())
					table.insert(name_list, skill_owner:objectName())
				end
			end
			return table.concat(skill_list,"|"), table.concat(name_list,"|")
		end
		return ""
	end,
    on_cost = function(self, event, room, player, data, skill_owner)
		if player == skill_owner or not skill_owner:isAlive() then return false end
		local cards = room:askForExchange(player, "yuancong_give", 1, 0, "@yuancong:" .. skill_owner:objectName())
		if not cards:isEmpty() then
			local log = sgs.LogMessage()
			log.type = "#InvokeOthersSkill"
			log.from = player
			log.to:append(skill_owner)
			log.arg = "yuancong"
			room:sendLog(log)
			room:broadcastSkillInvoke("yuancong", skill_owner)
            room:notifySkillInvoked(skill_owner, "yuancong")
			room:doAnimate(1, player:objectName(), skill_owner:objectName())

			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), skill_owner:objectName(), "yuancong", "")
		    local move = sgs.CardsMoveStruct(cards, skill_owner, sgs.Player_PlaceHand, reason)
		    room:moveCardsAtomic(move, false)

			return true
		end
		return false
	end,
    on_effect = function(self, event, room, player, data, skill_owner)
		if skill_owner:isAlive() then
			room:askForUseCard(skill_owner, "@@yuancongusecard", "@yuancong-usecard", -1, sgs.Card_MethodUse, false)
		end
		return false
	end,
}

chengpu:addSkill(huxun)
chengpu:addSkill(yuancong)
chengpu:addSkill(yuancongother)

xiliang:insertRelatedSkills("yuancong", "#yuancong-other")

if not sgs.Sanguosha:getSkill("yuancongusecard") then skills:append(yuancongusecard) end


sgs.LoadTranslationTable{
	["#chengpu"] = "虎首",
	["chengpu"] = "程普",
	["illustrator:chengpu"] = "Zero",
	["designer:chengpu"] = "梦魇狂朝",
	["huxun"] = "虎勋",
	[":huxun"] = "一名角色的回合结束时，若你在本回合内令其他角色进入过濒死状态，你可选择一项: 1. 增加1点体力上限并回复1点体力（若你体力上限为场上唯一最高则不可选择此项) ；2. 移动场上的一张牌。",
	["yuancong"] = "元从",
	[":yuancong"] = "与你势力相同的其他角色出牌阶段结束时，若其此阶段未造成过伤害，其可交给你一张牌，然后你可使用一张牌。",

	["huxun:gainmaxhp"] = "加体力上限",
	["huxun:movecard"] = "移动一张牌",
	["@huxun-move"] = "虎勋：你可以移动场上的一张牌",
	["@yuancong"] = "是否使用%src的“元从”",
	["@yuancong-usecard"] = "元从：你可以使用一张牌",

	["cv:chengpu"] = "天舞延云",
	["$huxun1"] = "某必报三世之恩遇，誓保孙氏之基业！",
	["$huxun2"] = "满腔热血，洒遍了六郡之土！",
	["$yuancong1"] = "取我长矛，老夫今日再奋身一战！",
	["$yuancong2"] = "若无诸君勠力，某安得尺寸之功？",
	["~chengpu"] = "汝等叛逆之贼，安敢索命于我！啊……",
}

qinzhong = sgs.CreateTriggerSkill{
	name = "qinzhong" ,
	events = {sgs.EventPhaseStart},
	relate_to_place = "deputy",
	
	can_trigger = function(self, event, room, player, data)
		--[[if skillTriggerable(player, self:objectName()) and event == sgs.EventPhaseStart then --and event ~= sgs.Player_NotActive then
			if (player:hasShownGeneral1() or player:hasShownGeneral2()) and player:getRole() ~= "careerist" and player:getPhase() == sgs.Player_RoundStart then
				--local change = data:toPhaseChange()
				--if change.to == sgs.Player_RoundStart then 
					return self:objectName()
				--end
			end
		end
		return ""]]--
		if not player or player:isDead() then return "" end  
        if not player:hasSkill(self:objectName()) then return "" end  
        if player:getPhase() ~= sgs.Player_Start then return "" end
		return self:objectName()
	end,
	
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self:objectName()) then
			local same_kingdom_players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do  --获得其他同势力角色
				if p:hasShownOneGeneral() and p:isAlive() and p:getKingdom() == player:getKingdom() and p:objectName() ~= player:objectName() and p:getRole() ~= "careerist" then
					same_kingdom_players:append(p)
				end
			end
		
			if not same_kingdom_players:isEmpty() then
				if player:askForSkillInvoke(self:objectName()) then
					room:broadcastSkillInvoke("qinzhong", player)
					return true
				end
			end
		end
		return false
	end,
	
	on_effect = function(self, event, room, player, data)
		local same_kingdom_players = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do  --获得其他同势力角色
            if p:hasShownOneGeneral() and p:isAlive() and (p:getKingdom() == player:getKingdom() and p:objectName() ~= player:objectName() and p:getRole() ~= "careerist") then
				same_kingdom_players:append(p)
			end
		end
		if not same_kingdom_players:isEmpty() then
			local dePlayer = room:askForPlayerChosen(player, same_kingdom_players, self:objectName(), "@qinzhong-invoke", true ,true)
			local playerName = player:getActualGeneral2Name()
			room:changePlayerGeneral2(player, dePlayer:getActualGeneral2Name())
			room:changePlayerGeneral2(dePlayer, playerName)
		end
	end

}

zhaofu = sgs.CreateTriggerSkill{
	name = "zhaofu" ,

}
quancong:addSkill(qinzhong)
quancong:addSkill(zhaofu)

sgs.LoadTranslationTable{
	["#quancong"] = "慕势耀族",
	["quancong"] = "全琮",
	["designer:quancong"] = "锦帆游侠_甘",
	["illustrator:quancong"] = "小小鸡仔",
	["qinzhong"] = "亲重",
	[":qinzhong"] = "副将技，回合开始时，你可以和一名与你势力相同的其他角色交换副将。",
	["zhaofu"] = "招附",
	[":zhaofu"] = "出牌阶段开始时，若场上不足三个“赏”，你可以弃置一张牌，令一名其他角色获得一个“赏”标记。"..
		"当有“赏”的角色使用基本牌或普通锦囊牌结算完成后，你可弃置其一个“赏”，当前阶段结束后，视为你使用了一张此牌。",

	["reward"] = "赏",

	["@qinzhong-invoke"] = "与一名势力相同的角色交换副将",
	["@zhaofu1"] = "是否使用“招附”，弃置一张牌令一名角色获得“赏”",
	["zhaofu:prompt"] = "是否使用“招附”，视为使用【%arg】",
	["@zhaofu2"] = "是否使用“招附”，视为使用【%arg】",

	["cv:quancong"] = "水苍玉",
	["$qinzhong1"] = "功成而不居，以明臣节，以为士范。",
	["$qinzhong2"] = "伏惟至尊累加宠用，臣诚惶诚恐！",
	["$zhaofu1"] = "市米渔利，有何所急？所急扶危济难也。",
	["$zhaofu2"] = "远近英才，皆入吾之网罘矣！",
	["~quancong"] = "名贵一时，忠诚一世，吾生已无憾矣……",
}

qushi = sgs.CreateTriggerSkill{
	name = "qushi",
	events = {sgs.CardFinished, sgs.EventPhaseChanging, sgs.SlashMissed},
	frequency = sgs.Skill_Compulsory,
	on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from == sgs.Player_Play then
				room:setPlayerMark(player, "#qushi", 0)
			end
		end
		if event == sgs.SlashMissed then
			local effect = data:toSlashEffect()
			if effect.slash then
				room:setCardFlag(effect.slash, "GlobalSlashMissed")
			end
		end
	end,
    can_trigger = function(self, event, room, player, data)
		if event == sgs.CardFinished and skillTriggerable(player, self:objectName()) and player:getPhase() == sgs.Player_Play then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.card:hasFlag("GlobalSlashMissed") then
				return self:objectName()
			end
		end
		return ""
	end,
    on_cost = function(self, event, room, player, data)
		local invoke = false
		if player:hasShownSkill(self:objectName()) then
			invoke = true
			room:sendCompulsoryTriggerLog(player, self:objectName())
		else
		    invoke = player:askForSkillInvoke(self, data)
		end
		if invoke then
			room:broadcastSkillInvoke(self:objectName(), player)
            return true
		end
		return false
	end,
    on_effect = function(self, event, room, player, data)
        room:addPlayerMark(player, "#qushi")
        return false
	end,
}

qushitarget = sgs.CreateTargetModSkill{
	name = "#qushi-target",
	pattern = "Slash",
	residue_func = function(self, player)
		return player:getMark("#qushi")
	end,
	extra_target_func = function(self, player)
		return player:getMark("#qushi")
	end,
}

yanxingSummonCard = sgs.CreateArraySummonCard{
	name = "yanxing",
    mute = true,
}

yanxingVS = sgs.CreateArraySummonSkill{
	name = "yanxing",
	array_summon_card = yanxingSummonCard,
}

yanxing = sgs.CreateTriggerSkill{
	name = "yanxing",
	is_battle_array = true,
	battle_array_type = sgs.Formation,
	view_as_skill = yanxingVS,
	can_preshow = false,
    can_trigger = function(self,event,room,player,data)
		return ""
	end,
}

yanxingdistance = sgs.CreateDistanceSkill{
	name = "#yanxing-distance" ,
	correct_func = function(self, from, to)
		local sib = from:getAliveSiblings()
		sib:append(from)
		local teammates = from:getFormation()
		if sib:length() < 4 or teammates:length() < 2 then return 0 end
		local x = 0
		for _, p in sgs.qlist(teammates) do
			if p:hasShownSkill("yanxing") then
				x = x - teammates:length() + 1
			end
		end
		return x
	end
}

yicong = sgs.CreateTriggerSkill{
	name = "yicong",
	relate_to_place = "head",
    can_trigger = function(self, event, room, player, data)
		return ""
	end,
    on_cost = function(self, event, room, player, data)
		return false
	end,
}

yicongother = sgs.CreateTriggerSkill{
	name = "#yicong-other",
	events = {sgs.CardFinished},
	frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.card:hasFlag("GlobalSlashMissed") and room:isAllOnPlace(use.card, sgs.Player_PlaceTable) then
				local skill_list = {}
				local name_list = {}
				local skill_owners = room:findPlayersBySkillName("yicong")
				for _, skill_owner in sgs.qlist(skill_owners) do
					if skillTriggerable(skill_owner, "yicong") and skill_owner:hasShownSkill("yicong") and player:isFriendWith(skill_owner) and player ~= skill_owner then
						table.insert(skill_list, self:objectName())
						table.insert(name_list, skill_owner:objectName())
					end
				end
				return table.concat(skill_list,"|"), table.concat(name_list,"|")
			end
		end
		return ""
	end,
    on_cost = function(self, event, room, player, data, skill_owner)
		if room:askForChoice(player, "yicong", "yes+no", data, "@yicong-choose:" .. skill_owner:objectName()) == "yes" then
			local log = sgs.LogMessage()
			log.type = "#InvokeOthersSkill"
			log.from = player
			log.to:append(skill_owner)
			log.arg = "yicong"
			room:sendLog(log)
			room:broadcastSkillInvoke("yicong", skill_owner)
            room:notifySkillInvoked(skill_owner, "yicong")
			return true
		end
		return false
	end,
    on_effect = function(self, event, room, player, data, skill_owner)
		local use = data:toCardUse()
		if use.card and room:isAllOnPlace(use.card, sgs.Player_PlaceTable) then
			skill_owner:obtainCard(use.card)
		end
		return false
	end,
}


gongsunzan:addSkill(qushi)
gongsunzan:addSkill(qushitarget)
gongsunzan:addSkill(yanxing)
gongsunzan:addSkill(yanxingdistance)
gongsunzan:addSkill(yicong)
gongsunzan:addSkill(yicongother)

xiliang:insertRelatedSkills("qushi", "#qushi-target")
xiliang:insertRelatedSkills("yanxing", "#yanxing-distance")
xiliang:insertRelatedSkills("yicong", "#yicong-other")


sgs.LoadTranslationTable{
	["#gongsunzan"] = "白马将军",
	["gongsunzan"] = "公孙瓒",
	["illustrator:gongsunzan"] = "匠人绘",
	["designer:gongsunzan"] = "梦魇狂朝",
	["qushi"] = "驱矢",
	[":qushi"] = "锁定技，出牌阶段你可使用【杀】的次数+X，你使用【杀】可以多选择X个目标（X为本阶段你使用过且被抵消过的【杀】的张数）。",
	["yanxing"] = "雁行",
	[":yanxing"] = "阵法技，每有一名与你处于同一队列的其他角色，你所在队列的角色计算与其以外的角色的距离时便-1。",
	["yicong"] = "义从",
	[":yicong"] = "主将技，此武将牌上单独的阴阳鱼个数-1。当与你势力相同的其他角色使用【杀】结算完成后，若此牌被抵消过，其可以将此【杀】交给你。",
	["@yicong-choose"] = "是否发动%src的“义从”，令其获得你使用的【杀】",

	["$yicong1"] = "众甲纵列，有进无退。",
	["$yicong2"] = "秣马厉兵，枕戈待战。",
    ["$qushi1"] = "以轻骑游勇，突袭敌军后援。",
	["$qushi2"] = "轻车锐骑，急断敌后！",
    ["~gongsunzan"] = "皇图霸业梦，付之一炬中……" ,
}

haokui = sgs.CreatePhaseChangeSkill{
	name = "haokui",
	on_record = function(self, event, room, player, data)
		if player:getPhase() == sgs.Player_NotActive then
			room:setPlayerMark(player, "##haokui", 0)
		end
	end,
	can_trigger = function(self, event, room, player)
		if skillTriggerable(player, self:objectName()) and player:getPhase() == sgs.Player_Play then
			return self:objectName()
		end
		return ""
	end,
	on_cost = function(self, event, room, player)
		if player:askForSkillInvoke(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName(), player)
            return true
		end
		return false
	end,
	on_phasechange = function(self, player)
		player:drawCards(2, self:objectName())
		player:getRoom():addPlayerMark(player, "##haokui")
		return false
	end,
}

haokuieffect = sgs.CreateTriggerSkill{
	name = "#haokui-effect",
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
    can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or player:getMark("##haokui") == 0 or player:getPhase() ~= sgs.Player_Discard then return "" end
		if event == sgs.CardsMoveOneTime then
			local move_datas = data:toList()
			for _, move_data in sgs.qlist(move_datas) do
				local move = move_data:toMoveOneTime()
				if move.to_place == sgs.Player_DiscardPile then
					for _, id in sgs.qlist(move.card_ids) do
						if room:getCardPlace(id) == sgs.Player_DiscardPile then
							return self:objectName()
						end
					end
				end
			end
		end
		if event == sgs.EventPhaseEnd and not player:hasFlag("haokuiInvoked") then
			return self:objectName()
		end
		return ""
	end,
    on_cost = function(self, event, room, player, data)
		return true
	end,
    on_effect = function(self, event, room, player, data)
        if event == sgs.CardsMoveOneTime then
			local ids = {}
			local move_datas = data:toList()
			for _, move_data in sgs.qlist(move_datas) do
				local move = move_data:toMoveOneTime()
				if move.to_place == sgs.Player_DiscardPile then
					for _, id in sgs.qlist(move.card_ids) do
						if room:getCardPlace(id) == sgs.Player_DiscardPile then
							table.insert(ids, id)
						end
					end
				end
			end
			if #ids > 0 then
				local all_players = room:getAlivePlayers()
				local to_choose = sgs.SPlayerList()
				for _, p in sgs.qlist(all_players) do
				    if not p:isFriendWith(player) and p:isBigKingdomPlayer() then
						to_choose:append(p)
					end
			    end
				if to_choose:isEmpty() then
					local x = 0
					for _, p in sgs.qlist(all_players) do
						if not p:isFriendWith(player) and p:getHp() >= x then
							if p:getHp() > x then
								x = p:getHp()
								to_choose = sgs.SPlayerList()
							end
							to_choose:append(p)
						end
					end

				end
				if not to_choose:isEmpty() then
					local to = room:askForPlayerChosen(player, to_choose, "haokui_give", "@haokui-give")
					if to then
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), to:objectName(), "haokui","")
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _, id in ipairs(ids) do
							dummy:addSubcard(id)
						end
						room:obtainCard(to, dummy, reason)
						room:setPlayerFlag(player, "haokuiInvoked")
					end
				end
			end
		end
		if event == sgs.EventPhaseEnd then
			if player:getGeneral():ownSkill("haokui") and player:hasShownAllGenerals() then
                if room:askForChoice(player, "haokui_hide", "yes+no", data, "@haokui-hide1") == "yes" then
                    player:hideGeneral()
                end
            end
			if player:getGeneral2() and player:getGeneral2():ownSkill("haokui") and player:hasShownAllGenerals() then
                if room:askForChoice(player, "haokui_hide", "yes+no", data, "@haokui-hide2") == "yes" then
                    player:hideGeneral(false)
                end
            end
			if player:getMark("haokuitransformUsed") == 0 then
				local all_players = room:getAlivePlayers()
				local to_choose = sgs.SPlayerList()
				for _, p in sgs.qlist(all_players) do
				    if p:isFriendWith(player) and p:canTransform() then
						to_choose:append(p)
					end
			    end
				if not to_choose:isEmpty() then
					local to = room:askForPlayerChosen(player, to_choose, "haokui_transform", "@haokui-transform", true)
                    if to and room:askForChoice(to, "transform_haokui", "yes+no", data, "@transform-ask:::haokui") == "yes" then
                        room:addPlayerMark(player, "haokuitransformUsed")
                        room:transformDeputyGeneral(to)
					end
				end
			end
		end
        return false
	end,
}

xushi = sgs.CreateTriggerSkill{
	name = "xushi",
	events = {sgs.TargetConfirming},
    can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and not player:hasShownSkill(self:objectName()) then
			local use = data:toCardUse()
			if use.card:getTypeId() ~= sgs.Card_TypeSkill and use.from ~= player and use.to:contains(player) then
				for _,p in sgs.qlist(use.to) do
				    if p ~= player then
						return ""
					end
				end
				return self:objectName()
			end
		end
		return ""
	end,
    on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName(), player)
            return true
		end
		return false
	end,
    on_effect = function(self, event, room, player, data)
        local use = data:toCardUse()
        sgs.Room_cancelTarget(use, player)
		data:setValue(use)
		if use.from and use.from:isAlive() then
			room:askForDiscard(use.from, "xushi_discard", 1, 1, false, true)
		end
        return false
	end,
}

chendeng:addSkill(haokui)
chendeng:addSkill(haokuieffect)
chendeng:addSkill(xushi)
xiliang:insertRelatedSkills("haokui", "#haokui-effect")

sgs.LoadTranslationTable{
	["#chendeng"] = "湖海豪气",
	["chendeng"] = "陈登",
	["illustrator:chendeng"] = "鬼画府",
	["designer:chendeng"] = "梦魇狂朝",
	["haokui"] = "豪魁",
	[":haokui"] = "出牌阶段开始时，你可摸两张牌。若如此做，在此回合的弃牌阶段：当有牌置入弃牌堆时，你将这些牌交给一名其他势力角色（优先大势力，其次体力值最高的角色）；"..
		"若没有牌进入弃牌堆，你可暗置该武将牌，然后令一名与你势力相同的角色变更副将。",
	["xushi"] = "虚实",
	[":xushi"] = "当其他角色使用的牌仅指定了你为目标时，若该武将牌处于暗置状态，你可明置此武将牌，取消之。然后令其弃置一张牌。",

	["@haokui-give"] = "豪魁：令一名角色获得置入弃牌堆的牌",
	["@haokui-transform"] = "豪魁：可选择一名与你势力相同的角色，令其变更",
	["@haokui-hide1"] = "豪魁：选择是否暗置主将的武将牌",
	["@haokui-hide2"] = "豪魁：选择是否暗置副将的武将牌",
	["@xushi-discard"] = "虚实：是否弃置%dest一张牌",

	["$haokui1"] = "筹划水利农务，只为徐州百姓。",
	["$haokui2"] = "养耆育孤，视民如伤，以丰定徐州。",
    ["$xushi1"] = "孰为虎，孰为鹰，于吾都如棋子。",
	["$xushi2"] = "料断叩图，施策以阻。",
    ["~chendeng"] = "元化不在，吾命如此……" ,
}

jiange = sgs.CreateOneCardViewAsSkill{
	name = "jiange",
	response_or_use = true,
	view_filter = function(self, card)
		if card:getTypeId() == sgs.Card_TypeBasic then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(card:getEffectiveId())
			slash:deleteLater()
			return slash:isAvailable(sgs.Self)
		end
		return true
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:addSubcard(card:getId())
		slash:setSkillName(self:objectName())
		slash:setShowSkill(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end
}

qianxueselect = sgs.CreateViewAsSkill{
	name = "qianxueselect",
	expand_pile = "#qianxue",
	response_pattern = "@@qianxueselect",
	view_filter = function(self, selected, to_select)
		if #selected < sgs.Self:getMark("qianxuecount") then
			local ids = sgs.Self:getPile("#qianxue")
			if not ids:contains(to_select:getId()) then return false end
			if to_select:getTypeId() == sgs.Card_TypeBasic then
				for _, id in sgs.qlist(ids) do
					local c2 = sgs.Sanguosha:getCard(id)
					if c2:getTypeId() ~= sgs.Card_TypeBasic and not table.contains(selected, c2) then
						return false
					end
				end
			end
			return true
		end
		return false
	end,
    view_as = function(self, cards)
		if #cards == 0 then return nil end
		for _,card in ipairs(cards) do
			if card:getTypeId() == sgs.Card_TypeBasic then
				local ids = sgs.Self:getPile("#qianxue")
				for _, id in sgs.qlist(ids) do
					local c2 = sgs.Sanguosha:getCard(id)
					if c2:getTypeId() ~= sgs.Card_TypeBasic and not table.contains(cards, c2) then
						return nil
					end
				end
				break
			end
		end

		local skillcard = MemptyCard:clone()
		for _,card in ipairs(cards) do
			skillcard:addSubcard(card)
		end
		return skillcard
	end,
}

qianxue = sgs.CreateTriggerSkill{
	name = "qianxue",
	events = {sgs.EventPhaseChanging, sgs.ConfirmMoveCards},
	relate_to_place = "head",
	on_record = function(self, event, room, player, data)
		if event == sgs.ConfirmMoveCards then
			local move_datas = data:toList()
			local handcards = CardList2Table(player:getHandcards())
			local equips = CardList2Table(player:getEquips())
			local delayedtricks = CardList2Table(player:getJudgingArea())
			local h_cheak = (#handcards > 0)
			local e_cheak = (#equips > 0)
			local j_cheak = (#delayedtricks > 0)
			for _, move_data in sgs.qlist(move_datas) do
				local move = move_data:toMoveOneTime()
				for _, id in sgs.qlist(move.card_ids) do
					table.removeOne(handcards, id)
					table.removeOne(equips, id)
					table.removeOne(delayedtricks, id)
				end
			end
			if h_cheak and #handcards == 0 then
				room:setPlayerFlag(player, "GlobalLoseAllHandCards")
			end
			if e_cheak and #equips == 0 then
				room:setPlayerFlag(player, "GlobalLoseAllEquips")
			end
			if j_cheak and #delayedtricks == 0 then
				room:setPlayerFlag(player, "GlobalLoseAllDelayedTricks")
			end
		end
	end,
    can_trigger = function(self, event, room, player, data)
		local skill_list = {}
		local name_list = {}
		if event == sgs.EventPhaseChanging then
		    local change = data:toPhaseChange()
		    if change.to == sgs.Player_NotActive then
			    local discardpile = room:getTag("GlobalRoundDisCardPile"):toList()
				local can_trigger_cheak = false
				for _, card_data in sgs.qlist(discardpile) do
					local card_id = card_data:toInt()
					if room:getCardPlace(card_id) == sgs.Player_DiscardPile and not sgs.Sanguosha:getCard(card_id):isKindOf("ThreatenEmperor") then
						can_trigger_cheak = true
						break
					end
				end
				if can_trigger_cheak then
					local skill_owners = room:findPlayersBySkillName(self:objectName())
					for _, skill_owner in sgs.qlist(skill_owners) do
						if skillTriggerable(skill_owner, self:objectName()) and (skill_owner:hasFlag("GlobalLoseAllHandCards") or
						        skill_owner:hasFlag("GlobalLoseAllEquips") or skill_owner:hasFlag("GlobalLoseAllDelayedTricks")) then
							table.insert(skill_list, self:objectName())
							table.insert(name_list, skill_owner:objectName())
						end
					end
				end
		    end
		end
		return table.concat(skill_list,"|"), table.concat(name_list,"|")
	end,
    on_cost = function(self, event, room, p, data, player)
		local x = 0
		if player:hasFlag("GlobalLoseAllHandCards") then
			x = x + 1
		end
		if player:hasFlag("GlobalLoseAllEquips") then
			x = x + 1
		end
		if player:hasFlag("GlobalLoseAllDelayedTricks") then
			x = x + 1
		end
		if player:askForSkillInvoke(self:objectName(), sgs.QVariant("invoke:::" .. tostring(x))) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false

	end,
    on_effect = function(self, event, room, p, data, player)
		local x = 0
		if player:hasFlag("GlobalLoseAllHandCards") then
			x = x + 1
		end
		if player:hasFlag("GlobalLoseAllEquips") then
			x = x + 1
		end
		if player:hasFlag("GlobalLoseAllDelayedTricks") then
			x = x + 1
		end
		if x == 0 then return false end
		local cards = sgs.IntList()
		local discardpile = room:getTag("GlobalRoundDisCardPile"):toList()
		for _, card_data in sgs.qlist(discardpile) do
			local card_id = card_data:toInt()
			if room:getCardPlace(card_id) == sgs.Player_DiscardPile and not sgs.Sanguosha:getCard(card_id):isKindOf("ThreatenEmperor") then
				cards:append(card_id)
			end
		end
		if cards:isEmpty() then return false end
		room:setPlayerMark(player, "qianxuecount", x)
        room:notifyMoveToPile(player, cards, "qianxue", sgs.Player_PlaceTable, true, true)
        local to_get = room:askForCard(player, "@@qianxueselect", "@qianxue-select:::" .. tostring(x), data, sgs.Card_MethodNone)
        room:setPlayerMark(player, "qianxuecount", 0)
        room:notifyMoveToPile(player, cards, "qianxue", sgs.Player_PlaceTable, false, false)

        if to_get:subcardsLength() > 0 then
            room:obtainCard(player, to_get, true)
        end

	end,
}

zhuhu = sgs.CreateTriggerSkill{
	name = "zhuhu",
	events = {sgs.DeathFinished, sgs.GeneralTransformed},
	frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
		local skill_list = {}
		local name_list = {}
		
		if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end

		local zhuhuTriggerable = function(splayer)
			if skillTriggerable(splayer, "zhuhu") then return false end
			--if splayer:getActualGeneral1():ownSkill("zhuhu") then --为什么要判断是否双势力武将？
				--return not splayer:getActualGeneral2():isDoubleKingdoms()
			--end 
			if splayer:getActualGeneral2():ownSkill("zhuhu") then return false end
			return true
		end

		if event == sgs.DeathFinished and (not zhuhuTriggerable(player)) then
		    local death = data:toDeath()
			if death.who and death.who:isFriendWith(player) then
				table.insert(skill_list, self:objectName())
				table.insert(name_list, player:objectName())
		    end
		elseif event == sgs.GeneralTransformed then
			local skill_owners = room:findPlayersBySkillName(self:objectName())
			for _, skill_owner in sgs.qlist(skill_owners) do
				if not zhuhuTriggerable(skill_owner) and skill_owner:isFriendWith(player) then
					table.insert(skill_list, self:objectName())
					table.insert(name_list, player:objectName())
				end
			end

		end
		return table.concat(skill_list,"|"), table.concat(name_list,"|")
	end,
    on_cost = function(self, event, room, p, data, player)
		local invoke = false
		if player:hasShownSkill(self:objectName()) then
			invoke = true
			room:sendCompulsoryTriggerLog(player, self:objectName())
		else
		    invoke = player:askForSkillInvoke(self, data)
		end
		if invoke then
			room:broadcastSkillInvoke(self:objectName(), player)
            return true
		end
		return false
	end,
    on_effect = function(self, event, room, p, data, player)
		if player:getActualGeneral1():ownSkill("zhuhu") then
            room:exchangeHeadAndDeputyGeneral(player)
			room:setPlayerProperty(player, "chained", sgs.QVariant(false))
        elseif player:getActualGeneral2():ownSkill("zhuhu") then --and player:isChained() then
            room:setPlayerProperty(player, "chained", sgs.QVariant(false))
		end
		if player:canTransform() then
			room:transformDeputyGeneral(player)
		end
	end,
}

shitao:addSkill(jiange)
shitao:addSkill(qianxue)
shitao:addSkill(zhuhu)

if not sgs.Sanguosha:getSkill("qianxueselect") then skills:append(qianxueselect) end

sgs.LoadTranslationTable{
	["#shitao"] = "同进共退",
	["shitao"] = "石韬",
	["illustrator:shitao"] = "佚名",
	["designer:shitao"] = "梦魇狂朝",
	["jiange"] = "剑歌",
	[":jiange"] = "你可以将一张非基本牌当作【杀】使用或打出。",
	["qianxue"] = "潜学",
	[":qianxue"] = "主将技，此武将牌上单独的阴阳鱼个数-1。你每有一个区域失去过所有牌，一名角色的回合结束时你可从弃牌堆中获得一张本回合进入弃牌堆的牌，且须优先选择非基本牌。",
	["zhuhu"] = "逐鹄",
	[":zhuhu"] = "锁定技，与你势力相同的角色变更副将或死亡后，若此牌不为副将，你须交换主副将；若为副将，则重置武将牌。然后你变更副将。",
	["qianxue:invoke"] = "是否使用“潜学”，获得至多%arg张本回合进入弃牌堆的牌（优先选择非基本牌）",
	["@qianxue-select"] = "潜学：选择获得至多%arg张本回合进入弃牌堆的牌（优先选择非基本牌）",
	["#qianxue"] = "潜学",

	["cv:shitao"] = "水苍玉",
	["$jiange1"] = "剑者，决也，断也。",
	["$jiange2"] = "吾志不好千里才，唯愿斩尽百里凶！",
	["$qianxue1"] = "今日所学未酣，当再破一卷！",
	["$qianxue2"] = "元直，这一篇何解？",
	["$zhuhu1"] = "元直既去，某且告辞。",
	["$zhuhu2"] = "丧乱既平，既安且宁。虽有兄弟，不如友生？",
	["~shitao"] = "与子同仇，与子偕作，与子偕行！",
}

xiaolian = sgs.CreateTriggerSkill{
	name = "xiaolian",
	can_preshow = false,
    can_trigger = function(self, event, room, player, data)
		return ""
	end,
    on_cost = function(self, event, room, player, data)
		return false
	end,
}

xiaoliancompulsory = sgs.CreateTriggerSkill{
	name = "#xiaolian-compulsory",
	events = {sgs.GeneralShowed, sgs.GeneralRemoved},
	frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
		if event == sgs.GeneralShowed then
			if player:cheakSkillLocation("xiaolian", data) and player:getMark("xiaolianUsed") == 0 then
                return self:objectName()
			end
		end
		if event == sgs.GeneralRemoved then
			local remove_data = data:toString():split(":")
			if #remove_data == 2 and table.contains(remove_data[2]:split("+"), "xiaolian") then
                return self:objectName()
			end
		end
		return ""
	end,
    on_cost = function(self, event, room, player, data)
		room:sendCompulsoryTriggerLog(player, "xiaolian")
        room:broadcastSkillInvoke("xiaolian", player)
        if event == sgs.GeneralShowed then
            room:addPlayerMark(player, "xiaolianUsed")
		end
        return true
	end,
    on_effect = function(self, event, room, player, data)
		if event == sgs.GeneralShowed then
			room:askForQiaobian(player, room:getAlivePlayers(), "xiaolian", "@xiaolian-move", true, false)
		end
		if event == sgs.GeneralRemoved then
			local friends = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if player:isFriendWith(p) then
					friends:append(p)
				end
			end
			if not friends:isEmpty() then
				room:sortByActionOrder(friends)
				for _, p in sgs.qlist(friends) do
					if p:isAlive() then
						p:drawCards(1, "xiaolian")
					end
				end
			end
		end
	end,
}

kangkai = sgs.CreateTriggerSkill{
	name = "kangkai",
	events = {sgs.TargetConfirmed},
    can_trigger = function(self, event, room, player, data)
		local skill_list = {}
		local name_list = {}
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") then
			local skill_owners = room:findPlayersBySkillName(self:objectName())
			for _, skill_owner in sgs.qlist(skill_owners) do
				if skillTriggerable(skill_owner, self:objectName()) and skill_owner:isFriendWith(player) and skill_owner:ownSkill(self:objectName()) then
					table.insert(skill_list, self:objectName())
					table.insert(name_list, skill_owner:objectName())
				end
			end
		end
		return table.concat(skill_list,"|"), table.concat(name_list,"|")
	end,
    on_cost = function(self, event, room, target, data, player)
		local source_data = sgs.QVariant()
		source_data:setValue(target)
		if player:askForSkillInvoke(self:objectName(), source_data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			player:removeGeneral(player:inHeadSkills(self:objectName()))
			return true
		end
		return false

	end,
    on_effect = function(self, event, room, player, data, source)
		if source:isDead() then return false end
		local target = room:askForPlayerChosen(source, room:getAlivePlayers(), "kangkai_target", "@kangkai-target")
		if target then
			room:acquireSkill(target, "feiying_caoang", true, false)
            room:addPlayerMark(target, "##kangkai")
			if target ~= source then
				local recover = sgs.RecoverStruct()
				recover.who = source
				room:recover(target, recover)
				if target:isChained() then
					room:setPlayerProperty(target, "chained", sgs.QVariant(false))
				end
			end
		end
	end,
}

feiying_caoang = sgs.CreateDistanceSkill{
	name = "feiying_caoang" ,
	correct_func = function(self, from, to)
		if to:hasShownSkill(self) then
			return 1
		end
		return 0
	end
}


caoang:addSkill(xiaolian)
caoang:addSkill(xiaoliancompulsory)
xiliang:insertRelatedSkills("xiaolian", "#xiaolian-compulsory")
caoang:addSkill(kangkai)

if not sgs.Sanguosha:getSkill("feiying_caoang") then skills:append(feiying_caoang) end

sgs.LoadTranslationTable{
	["#caoang"] = "孝战生死",
	["caoang"] = "曹昂",
	["illustrator:caoang"] = "Zero",
	["designer:caoang"] = "梦魇狂朝",
	["xiaolian"] = "孝廉",
	[":xiaolian"] = "当你首次明置此武将牌时，你可以移动场上一张装备牌；当你移除此武将牌时，与你势力相同的角色各摸一张牌。",
	["kangkai"] = "慷忾",
	[":kangkai"] = "当一名与你势力相同的角色成为【杀】的目标后，你可以移除此武将牌。若如此做，你可令一名角色获得技能“飞影”。然后若非你获得“飞影”，该角色回复1点体力并重置武将牌。",
	["feiying_caoang"] = "飞影",
	["@kangkai-target"] = "慷忾：选择一名角色获得“飞影”",
	["@xiaolian-move"] = "孝廉：你可以移动场上的一张装备牌",

	--曹昂
	["$xiaolian1"] = "典将军，比比看谁杀敌更多！",
	["$xiaolian2"] = "尔等叛贼，来一个，我杀一个！",
	["$kangkai1"] = "父亲上马，孩儿随后便来。",
	["$kangkai2"] = "父亲快走，有我殿后！",
	["~caoang"] = "父亲，安全就好……",
}

nizhan = sgs.CreateTriggerSkill{
	name = "nizhan",
	events = {sgs.EventPhaseChanging, sgs.ConfirmMoveCards},
	on_record = function(self, event, room, player, data)
		if event == sgs.ConfirmMoveCards then
			local move_datas = data:toList()
			local handcards = CardList2Table(player:getHandcards())
			local h_cheak = (#handcards > 0)
			for _, move_data in sgs.qlist(move_datas) do
				local move = move_data:toMoveOneTime()
				for _, id in sgs.qlist(move.card_ids) do
					table.removeOne(handcards, id)
				end
			end
			if h_cheak and #handcards == 0 then
				room:setPlayerFlag(player, "GlobalLoseAllHandCards")
			end
		end
	end,
    can_trigger = function(self, event, room, player, data)
		local skill_list = {}
		local name_list = {}
		if event == sgs.EventPhaseChanging and player and player:isAlive() then
		    local change = data:toPhaseChange()
		    if change.to == sgs.Player_NotActive then
				local skill_owners = room:findPlayersBySkillName(self:objectName())
				for _, skill_owner in sgs.qlist(skill_owners) do
					if skillTriggerable(skill_owner, self:objectName()) and player ~= skill_owner and
							(skill_owner:hasFlag("GlobalLoseAllHandCards") or skill_owner:getCardUsedTimes("Jink+Nullification") > 0) then
						table.insert(skill_list, self:objectName())
						table.insert(name_list, skill_owner:objectName())
					end
				end
		    end
		end
		return table.concat(skill_list,"|"), table.concat(name_list,"|")
	end,
    on_cost = function(self, event, room, target, data, player)
		local source_data = sgs.QVariant()
		source_data:setValue(target)
		if player:askForSkillInvoke(self:objectName(), source_data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false

	end,
    on_effect = function(self, event, room, target, data, player)
		local choices = {}
		if player:canSlash(target, false) then
			table.insert(choices, "slash")
		end
		if player:canGetCard(target, "he") then
			table.insert(choices, "extraction")
		end
		if #choices == 0 then return false end
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices,"+"), data, "@nizhan-choose::" .. target:objectName(), "extraction+slash")
		if choice == "extraction" then
			local card_id = room:askForCardChosen(player, target, "he", self:objectName(), false, sgs.Card_MethodGet)
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
			room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
		elseif choice == "slash" then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("_nizhan")
			room:useCard(sgs.CardUseStruct(slash, player, target), false)
		end
	end,
}

nizhaneffect = sgs.CreateTriggerSkill{
	name = "#nizhan-effect",
	events = {sgs.TargetChosen},
	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() then return "" end
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and use.card:getSkillName() == "nizhan" then
			local target = use.to:at(use.index)
			if target and target:isAlive() then
				return self:objectName() .. ":" .. target:objectName()
			end
		end
	end,
    on_cost = function(self, event, room, target, data, player)
		return true
	end,
	on_effect = function(self, event, room, target, data, player)
		local use = data:toCardUse()

		local log = sgs.LogMessage()
		log.type = "#NizhanEffect"
		log.from = player
		log.to:append(target)
		room:sendLog(log)

		target:addQinggangTag(use.card)

		return false
	end,
}

sunhuan:addSkill(nizhan)
sunhuan:addSkill(nizhaneffect)
xiliang:insertRelatedSkills("nizhan", "#nizhan-effect")

sgs.LoadTranslationTable{
	["#sunhuan"] = "宗室颜渊",
	["sunhuan"] = "孙桓",
	["illustrator:sunhuan"] = "Thinking",
	["designer:sunhuan"] = "梦魇狂朝",
	["nizhan"] = "逆斩",
	[":nizhan"] = "其他角色的回合结束时 ，若你在此回合抵消过牌，或失去过最后的手牌，则你可以选择一项:1.获得其一张牌;2.视为你对其使用了一张无视防具的【杀】。",

	["@nizhan-choose"] = "逆斩：选择对%dest执行的效果",
	["nizhan:extraction"] = "获得其一张牌",
	["nizhan:slash"] = "视为对其使用杀",

	["#NizhanEffect"] = "%from 令 %to 的防具技能无效",

	["cv:sunhuan"] = "寂镜Jnrio",
    ["$nizhan1"] = "诸位莫急，守住此城即为大功一件！",
	["$nizhan2"] = "玄德公，战场上还识得我么？！",
    ["~sunhuan"] = "此坞未就，桓愧对主公………" ,

}


sgs.Sanguosha:addSkills(skills)

dongbai = sgs.General(xiliang, "dongbai", "qun", 3, false)  

lianzhu = sgs.CreateViewAsSkill{  
    name = "lianzhu",  
    n = 1,  
    view_filter = function(self, selected, to_select)  
        return #selected == 0 --and not to_select:isEquipped()  
    end,  
    view_as = function(self, cards)  
        if #cards == 1 then  
            local card = LianzhuCard:clone()  
            card:addSubcard(cards[1])  
            card:setSkillName(self:objectName())  
            card:setShowSkill(self:objectName())  
            return card  
        end  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#LianzhuCard")  
    end  
}  
  
-- 连诛卡牌类  
LianzhuCard = sgs.CreateSkillCard{  
    name = "LianzhuCard",  
    target_fixed = false,  
    will_throw = false,  
    handling_method = sgs.Card_MethodNone,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        local card_id = self:getSubcards():first()  
        local card = sgs.Sanguosha:getCard(card_id)  
          
        -- 展示并交给目标角色  
        room:showCard(source, card_id)  
        room:obtainCard(target, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), "lianzhu", ""))  
          
        -- 若该牌为黑色  
        if card:isBlack() then  
            local choices = {"lianzhu_draw", "lianzhu_discard"}  
            local choice = room:askForChoice(target, "lianzhu", table.concat(choices, "+"))  
              
            if choice == "lianzhu_draw" then  
                -- 你摸2张牌  
                room:drawCards(source, 2, "lianzhu")  
            else  
                -- 其弃置2张牌  
                room:askForDiscard(target, "lianzhu", 2, 2, false, true)  
            end  
        end  
    end  
}  
  
-- 技能2：黠慧  
xiahui = sgs.CreateMaxCardsSkill{  
    name = "xiahui",  
    frequency = sgs.Skill_Compulsory,  
    extra_func = function(self, target)  
        if target:hasSkill(self:objectName()) then  
            local black_count = 0  
            local cards = target:getHandcards()  
            for _, card in sgs.qlist(cards) do  
                if card:isBlack() then  
                    black_count = black_count + 1  
                end  
            end  
            return black_count  
        end  
        return 0  
    end  
}  
  
-- 添加技能到武将  
dongbai:addSkill(lianzhu)  
dongbai:addSkill(xiahui)
sgs.LoadTranslationTable{
["dongbai"] = "董白",  
["#dongbai"] = "魔女",  
["lianzhu"] = "连诛",  
[":lianzhu"] = "出牌阶段限一次，你可以展示并交给一名其他角色一张牌，若该牌为黑色，其选择：1.你摸两张牌；2.其弃置两张牌。",  
["xiahui"] = "黠慧",  
[":xiahui"] = "锁定技，你的黑色牌不计入手牌上限。",  
["LianzhuCard"] = "连诛",  
["lianzhu_draw"] = "令其摸两张牌",  
["lianzhu_discard"] = "弃置两张牌",  
["@lianzhu-card"] = "连诛：选择要交给目标角色的牌"
}
guanning = sgs.General(xiliang, "guanning", "qun", 3)  

qinggong = sgs.CreateTriggerSkill{  
    name = "qinggong",  
    events = {sgs.EventPhaseChanging},  
    frequency = sgs.Skill_NotFrequent,  
      
    can_trigger = function(self, event, room, player, data)  
		local change = data:toPhaseChange()
        if player and player:hasSkill(self:objectName()) and change.to == sgs.Player_Discard then  
            return self:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local targets = {}  
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
            table.insert(targets, p:objectName())  
        end  
          
        if #targets == 0 then return false end  
          
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player),   
            self:objectName(), "@qinggong-discard", true, true)  
          
        if not target then return false end  
          
        -- 令目标角色弃置自己两张牌  
		if target:canDiscard(player, "he") then
			room:throwCard(room:askForCardChosen(target, player, "he", self:objectName(), false, sgs.Card_MethodDiscard), player, target)
		end
		if target:canDiscard(player, "he") then
			room:throwCard(room:askForCardChosen(target, player, "he", self:objectName(), false, sgs.Card_MethodDiscard), player, target)
		end  
          
        -- 跳过弃牌阶段  
        player:skip(sgs.Player_Discard)  
          
        -- 可以令一名角色明置一张武将牌  
        local all_players = room:getAlivePlayers()  
        local can_show = sgs.SPlayerList() 
        for _, p in sgs.qlist(all_players) do  
            if not p:hasShownAllGenerals() then  
                can_show:append(p)
            end  
        end  
          
        if not can_show:isEmpty() then  
            local show_target = room:askForPlayerChosen(player, can_show,   
                self:objectName(), "@qinggong-show", true, true)  
            if show_target then  
                local choices = {}  
                if not show_target:hasShownGeneral1() then  
                    table.insert(choices, "head_general")  
                end  
                if not show_target:hasShownGeneral2() then  
                    table.insert(choices, "deputy_general")  
                end  
                  
                if #choices > 0 then  
                    local choice = room:askForChoice(show_target, self:objectName(), table.concat(choices, "+"))  
                    if choice == "head_general" then  
                        show_target:showGeneral(true)  
                    else  
                        show_target:showGeneral(false)  
                    end  
                end  
            end  
        end  
          
        return false  
    end  
}  
  
-- 尚雅技能实现  
shangya = sgs.CreateTriggerSkill{  
    name = "shangya",  
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},  
    frequency = sgs.Skill_NotFrequent,  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
        if event == sgs.EventPhaseStart then  
            if player:getPhase() == sgs.Player_Start and player:hasShownAllGenerals() then  
                -- 检查是否有其他角色有暗置武将牌  
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                    if not p:hasShownAllGenerals() and not p:isKongcheng() then  
                        return self:objectName()  
                    end  
                end  
            end  
        end  

        if skillTriggerable(player, self:objectName()) then
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					local reasonx = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					--if reasonx ~= sgs.CardMoveReason_S_REASON_USE and reasonx ~= sgs.CardMoveReason_S_REASON_RESPONSE then
					if reasonx == sgs.CardMoveReason_S_REASON_DISCARD then
                        if move.from_places:contains(sgs.Player_PlaceHand) then
							if move.from and move.from:isAlive() and move.from:objectName()==player:objectName() then
								return self:objectName()
							end
						end
					end
				end
			end
		end          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return room:askForSkillInvoke(player, self:objectName(), data)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then  
            -- 弃置每名有暗置武将牌的角色各1张手牌  
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                if not p:hasShownAllGenerals() and not p:isKongcheng() then  
                    local card_id = room:askForCardChosen(player, p, "h", self:objectName())  
                    room:throwCard(card_id, p, player)  
                end  
            end  
        end  
        if event == sgs.CardsMoveOneTime then  
            local all_shown = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getAllPlayers()) do  
                if p:hasShownAllGenerals() then  
                    all_shown:append(p)
                end  
            end  
              
            if all_shown:isEmpty() then return false end
            target = room:askForPlayerChosen(player, all_shown,   
                    self:objectName(), "@shangya-draw", true, true)  
              
            if target then  
                -- 目标摸2张牌  
                target:drawCards(2)  
                  
                -- 暗置其一张武将牌  
                local choices = {}  
                if target:hasShownGeneral1() then  
                    table.insert(choices, "head_general")  
                end  
                if target:hasShownGeneral2() then  
                    table.insert(choices, "deputy_general")  
                end  
                  
                if #choices > 0 then  
                    local choice = room:askForChoice(player, self:objectName() .. "_hide",   
                        table.concat(choices, "+"))  
                    if choice == "head_general" then  
                        target:hideGeneral(true)  
                    else  
                        target:hideGeneral(false)  
                    end  
                end  
            end  
        end
        return false  
    end  
}  
  
guanning:addSkill(qinggong)  
guanning:addSkill(shangya)
sgs.LoadTranslationTable{
    ["#guanning"] = "高洁的隐士",  
    ["guanning"] = "管宁",  
    ["qinggong"] = "清躬",  
    [":qinggong"] = "弃牌阶段开始时，你可以令一名其他角色弃置你两张牌，你跳过弃牌阶段，然后你可以令一名角色明置一张武将牌。",  
    ["shangya"] = "尚雅",  
    [":shangya"] = "准备阶段，若你没有暗置的武将牌，你可以弃置每名有暗置武将牌的角色各1张手牌；当你因弃置而失去手牌后，你可以令一名武将牌均明置的角色摸2张牌，然后暗置其1张武将",  
    ["@qinggong-discard"] = "你可以发动'清躬'，令一名其他角色弃置你两张牌",  
    ["@qinggong-show"] = "你可以令一名角色明置一张武将牌",  
    ["@shangya-draw"] = "你可以发动'尚雅'，令一名武将牌均明置的角色摸2张牌",  
    ["@shangya-discard"] = "你可以发动'尚雅'，弃置有暗置武将牌的角色各1张手牌",  
    ["~qinggong"] = "选择一名其他角色→点击确定",  
    ["~shangya"] = "选择一名武将牌均明置的角色→点击确定",
}

zhugeguo = sgs.General(xiliang, "zhugeguo", "shu", 3, false)  
qidao = sgs.CreateTriggerSkill{
	name = "qidao",
	events = {sgs.CardUsed},
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) then
			local use = data:toCardUse()
			if (use.card:isKindOf("EquipCard") or use.card:isKindOf("TrickCard")) and use.from == player then
				return self:objectName()
			end
		end
		return false
	end,

	on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(), data) then
            return true
        end
		return false
	end,

	on_effect = function(self, event, room, player, data)
        local use = data:toCardUse()  
          
        -- 弃置一张牌并记录弃置牌的类型  
        local discarded_card = nil
        if not player:isNude() then  
            --[[
            local card_id = room:askForCardChosen(player, player, "he", self:objectName(), false, sgs.Card_MethodDiscard)  
            if card_id ~= -1 then  
                discarded_card = sgs.Sanguosha:getCard(card_id)  
                room:throwCard(card_id, player, player) 
                -- 摸一张牌  
                room:drawCards(player, 1, self:objectName())   
            end  
            ]]
            discarded_card = room:askForCard(player, ".|.|.|hand,equipped", "@qidao-discard", data, sgs.Card_MethodDiscard)  
            if discarded_card then  
                -- 摸一张牌  
                room:drawCards(player, 1, self:objectName())  
            end  
        end  
          
        -- 检查是否需要额外摸牌（基于弃置的牌类型）  
        if use.card and discarded_card then  
            if use.card:isKindOf("EquipCard") and discarded_card:isKindOf("TrickCard") then  
                -- 使用装备牌时弃置锦囊牌，额外摸1张牌  
                player:drawCards(1, self:objectName())  
            elseif use.card:isKindOf("TrickCard") and discarded_card:isKindOf("EquipCard") then  
                -- 使用锦囊牌时弃置装备牌，额外摸1张牌  
                player:drawCards(1, self:objectName())  
            end  
        end  
		return false
	end
}

-- 羽化技能  
yuhua = sgs.CreateTriggerSkill{  
    name = "yuhua",  
    events = {sgs.CardsMoveOneTime},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) then
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					local reasonx = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					if reasonx == sgs.CardMoveReason_S_REASON_DISCARD then
						if move.from and move.from:isAlive() and move.from:objectName()==player:objectName() then
							for _,card_id in sgs.qlist(move.card_ids) do
								local card = sgs.Sanguosha:getCard(card_id)  
								local card_type = card:getTypeId()
								-- 回合内失去装备牌
								if move.from:getPhase() ~= sgs.Player_NotActive and card_type == sgs.Card_TypeEquip then  
									return self:objectName()
								-- 回合外失去锦囊牌  
								elseif move.from:getPhase() == sgs.Player_NotActive and card_type == sgs.Card_TypeTrick then  
									return self:objectName()
								end
							end
						end
					end
				end
			end
		end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)            
        return player:askForSkillInvoke(self:objectName(), data) 
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local move_datas = data:toList()
        for _, move_data in sgs.qlist(move_datas) do
            local move = move_data:toMoveOneTime()
            if move.from and move.from:isAlive() and move.from:objectName()==player:objectName() then
                for _,card_id in sgs.qlist(move.card_ids) do
                    local card = sgs.Sanguosha:getCard(card_id)  
                    local card_type = card:getTypeId()
                    local should_give = false
                    -- 回合内失去装备牌
                    if move.from:getPhase() ~= sgs.Player_NotActive and card_type == sgs.Card_TypeEquip then  
                        should_give = true
                    -- 回合外失去锦囊牌  
                    elseif move.from:getPhase() == sgs.Player_NotActive and card_type == sgs.Card_TypeTrick then  
                        should_give = true
                    end
                    if should_give then
                        local targets = sgs.SPlayerList()  
                        for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                            targets:append(p)  
                        end  
                        
                        if not targets:isEmpty() then  
                            local target = room:askForPlayerChosen(player, targets, self:objectName())  
                            if target then  
                                target:obtainCard(card)  
                            end  
                        end  
                    end
                end 
            end
        end          
        return false  
    end  
}  
  
zhugeguo:addSkill(qidao)  
zhugeguo:addSkill(yuhua) 

sgs.LoadTranslationTable{
    ["#zhugeguo"] = "蜀汉公主",  
    ["zhugeguo"] = "诸葛果",  
    ["qidao"] = "祈祷",  
    [":qidao"] = "每当你使用1张装备牌时，你可以弃置1张牌并摸一张牌，若弃置的牌为锦囊牌，你摸一张牌；每当你使用1张锦囊牌时，你可以弃置1张牌并摸一张牌，若弃置的牌为装备牌，你摸一张牌。",  
    ["yuhua"] = "羽化",  
    [":yuhua"] = "你回合内失去装备牌或回合外失去锦囊牌时，可以将其交给一名其他角色。",  
    ["@qidao-discard"] = "你可以弃置一张牌发动‘祈祷’",  
    ["@yuhua-give"] = "你可以发动‘羽化’，将此牌交给一名其他角色",  
    ["~yuhua"] = "选择一名其他角色→点击确定",
}
zhugezhan = sgs.General(xiliang, "zhugezhan", "shu", 3)  
zuilun = sgs.CreateTriggerSkill{  
    name = "zuilun",  
    frequency = sgs.Skill_Compulsory,  
    events = {sgs.EventPhaseEnd},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data) -- 锁定技，无需询问  
    end,  
    on_effect = function(self, event, room, player, data)  
        -- 观星牌堆顶3张牌  
        local guanxing = room:getNCards(3)  
        room:askForGuanxing(player, guanxing, sgs.Room_GuanxingUpOnly)  --Room_GuanxingBothSides
          
        -- 计算X值  
        local x = 0  
          
        -- 条件1：与你势力相同的其他角色数>1  
        local same_kingdom_count = 0  
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
            if player:isFriendWith(p) then  --p:getKingdom() == player:getKingdom() --需要考虑野心家的情况
                same_kingdom_count = same_kingdom_count + 1  
            end  
        end  
        if same_kingdom_count > 1 then  
            x = x + 1  
        end  
          
        -- 条件2：本回合你造成的伤害数>1  
        local damage_count = player:getMark("@zuilun_damage_count")  
        room:setPlayerMark(player,"@zuilun_damage_count",0)
        if damage_count > 1 then  
            x = x + 1  
        end  
          
        -- 条件3：你已失去的体力数>1  
        local lost_hp = player:getMaxHp() - player:getHp()  
        if lost_hp > 1 then  
            x = x + 1  
        end  
          
        if x > 0 then  
            -- 摸X张牌  
            room:drawCards(player, x, self:objectName())  
        else  
            -- X=0时，选择一名其他角色，你与其各失去一点体力  
            local targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                targets:append(p)  
            end  
              
            if not targets:isEmpty() then  
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@zuilun-choose")  
                room:loseHp(player, 1)  
                room:loseHp(target, 1)  
            end  
        end  
          
        return false  
    end  
}  
  
-- 记录伤害数的辅助技能  
zuilun_record = sgs.CreateTriggerSkill{  
    name = "#zuilun-record",  
    events = {sgs.Damage},  
    can_trigger = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        if damage.from and damage.from:isAlive() and damage.from:hasSkill("zuilun") then  
            local from = damage.from  
        	local current_count = from:getMark("@zuilun_damage_count")  
        	room:setPlayerMark(from, "@zuilun_damage_count", current_count + damage.damage)
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
  
-- 技能2：父荫  
fuyin = sgs.CreateTriggerSkill{  
    name = "fuyin",  
    frequency = sgs.Skill_Compulsory,  
    events = {sgs.TargetConfirming},  
    can_trigger = function(self, event, room, player, data)
        local owner = room:findPlayerBySkillName(self:objectName())
        if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then return "" end
        local use = data:toCardUse()
        if (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) and use.to:contains(owner) then  
            if not owner:hasFlag("fuyin_used") then  
                return self:objectName(), owner:objectName()
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        return ask_who:hasShownSkill(self:objectName()) or ask_who:askForSkillInvoke(self:objectName(),data) -- 锁定技，无需询问  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local use = data:toCardUse()  
        if use.from and use.from:getHandcardNum() > ask_who:getHandcardNum() then  
            -- 取消目标  
            local new_targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(use.to) do  
                if p:objectName() ~= ask_who:objectName() then  
                    new_targets:append(p)  
                end  
            end  
            use.to = new_targets  
            data:setValue(use)  
              
            -- 标记本回合已使用  
            room:setPlayerFlag(player, "fuyin_used")  
        end  
        return false  
    end  
}  
  
-- 添加技能到武将  
zhugezhan:addSkill(zuilun)  
zhugezhan:addSkill(zuilun_record)  
zhugezhan:addSkill(fuyin)  

sgs.LoadTranslationTable{
["zhugezhan"] = "诸葛瞻",  
["#zhugezhan"] = "蜀汉忠臣",  
["zuilun"] = "罪论",  
[":zuilun"] = "锁定技，结束阶段，你观看牌堆顶3张牌并以任意顺序放回牌堆顶，然后你摸X张牌，X为满足以下条件的数量：①与你势力相同的其他角色数>1；②本回合你造成的伤害数>1；③你已失去的体力数>1。若X=0，你选择一名其他角色，你与其各失去一点体力。",  
["fuyin"] = "父荫",  
[":fuyin"] = "锁定技，你每回合首次成为【杀】或【决斗】的目标后，若使用者的手牌数大于你，取消之。",  
["@zuilun-choose"] = "罪论：选择一名其他角色，你与其各失去一点体力",
}
return {xiliang}
