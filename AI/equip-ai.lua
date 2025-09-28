

sgs.ai_skill_invoke.anshajian_loseHp = function(self, data)  
	local damage = data:toDamage()  
	local damage_value = damage.damage  
	local current_hp = damage.to:getHp()  
	
    if self.player:isFriendWith(damage.to) then
    	if damage_value - current_hp >= 0 then  
	    	return true  
        else
            return false  
        end
    else
        -- 如果伤害值-体力值>2，则不发动  
        if damage_value - current_hp > 2 then  
            return false  
        else  
            -- 否则发动  
            return true  
        end
    end
    return true
end


sgs.ai_skill_invoke.Bileizhen = function(self, data)  
	local damage = data:toDamage()  
	local target = damage.to  
    if self.player:hasFlag("bilenzhen-attrack") then
        if self.player:isFriendWith(target) then
            return true
        else
            return false
        end
    elseif self.player:hasFlag("bilenzhen-immuse") then
        if (self:needDamagedEffects(target, self.player) or self:needToLoseHp()) then
            return false
        else
            return true
        end
    else--if self.player:hasFlag("bilenzhen-effect") then
        return true
    end
	-- 判断目标是否为同势力：同势力发动，不同势力不发动  
end  
  

sgs.ai_skill_choice.Bileizhen = function(self, choices, data)  
    local choice_table = choices:split("+")  
      
    -- 如果自己不健康则选择recover  
    if self:isWeak() or (self.player:isWounded() and self.player:getHp() < 2) then  
        if table.contains(choice_table, "recover") then  
            return "recover"  
        end  
    end  
      
    -- 如果自己健康且手牌数较少则选择draw  
    if not self:isWeak() and self.player:getHandcardNum() < 2 then  
        if table.contains(choice_table, "draw") then  
            return "draw"  
        end  
    end  
      
    -- 如果自己健康且手牌数>=5且手牌质量较高则选择play  
    if not self:isWeak() and self.player:getHandcardNum() >= 5 then  
        local good_cards = 0  
        local cards = self.player:getHandcards()  
        for _, card in sgs.qlist(cards) do  
            if self:getUseValue(card) > 3 or self:getKeepValue(card) > 3 then  
                good_cards = good_cards + 1  
            end  
        end  
          
        if good_cards >= 3 and table.contains(choice_table, "play") then  
            return "play"  
        end  
    end  
      
    -- 否则选择recover  
    if table.contains(choice_table, "recover") then  
        return "recover"  
    end  
      
    -- 如果没有recover选项，则选择第一个可用选项  
    return choice_table[1]  
end

sgs.ai_skill_invoke.kuangzhanshi = function(self, data)  
	local damage = data:toDamage()  
	local target = damage.to  
	  
	-- 判断目标是否为同势力：同势力不发动，不同势力发动  
	return not self.player:isFriendWith(target)  
end  

--[[
sgs.ai_skill_discard.shengfan = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("shengfan", 1, 1, false, true)
end
]]