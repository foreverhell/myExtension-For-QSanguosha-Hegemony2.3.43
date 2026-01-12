
--锁定技：
sgs.ai_skill_invoke.pingyuan = true
sgs.ai_skill_invoke.kuangzhan = true
sgs.ai_skill_invoke.wushengSlash = true
sgs.ai_skill_invoke.zunwang = true
sgs.ai_skill_invoke.zhubei = true
sgs.ai_skill_invoke.jiuxian_draw = true
sgs.ai_skill_invoke.jiuxian_immune = true
sgs.ai_skill_invoke.dihui = true
sgs.ai_skill_invoke.yonge = true
sgs.ai_skill_invoke.tuoying = true
sgs.ai_skill_invoke.qizong = true
sgs.ai_skill_invoke.shenli = true
sgs.ai_skill_invoke.gaiguo = true
sgs.ai_skill_invoke.mengdie = true
sgs.ai_skill_invoke.xiaoyaoTurned = true
sgs.ai_skill_invoke.tianpeng = true
sgs.ai_skill_invoke.caoshu = true
sgs.ai_skill_invoke.jingsuan = true
sgs.ai_skill_invoke.zhishangtanbing = function(self, data)
    local damage = data:toDamage()
    return damage.to ~= self.player
end
--弃别人牌，优先弃价值高的
sgs.ai_skill_cardchosen.shixin = sgs.ai_skill_cardchosen.jieqizhi
sgs.ai_skill_cardchosen.zishu = sgs.ai_skill_cardchosen.jieqizhi
--弃自己牌：逻辑里optional=true是为了让玩家可以自由选择，ai里希望它选的时候令optional=false
sgs.ai_skill_discard.weifu = function(self, discard_num, min_num, optional, include_equip)
    return self:askForDiscard("dummy_reason", discard_num, min_num, false, include_equip)
end
--太极
sgs.ai_skill_invoke.taiji = function(self, data)
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if self.player:canSlash(p, true) and not self.player:isFriendWith(p) then
            return true
        end
    end
    return false
end
sgs.ai_skill_playerchosen.taiji = sgs.ai_skill_playerchosen.luaqinzheng
sgs.ai_skill_playerchosen.beide = sgs.ai_skill_playerchosen.luaqinzheng

--遗计类：举荐，射日，落笔
sgs.ai_skill_askforyiji.jujianAsk = sgs.ai_skill_askforyiji.yiji
sgs.ai_skill_askforyiji.sheriAsk = sgs.ai_skill_askforyiji.yiji
sgs.ai_skill_askforyiji.luobiAsk = sgs.ai_skill_askforyiji.yiji
