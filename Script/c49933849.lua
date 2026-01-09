
local s,id=GetID()
function s.initial_effect(c)
	-- Activar desde la mano
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_TRAP_ACTIVATE_FROM_HAND)
	e1:SetCondition(s.handcon)
	c:RegisterEffect(e1)
	
	-- Efecto principal: Robo y Reajuste
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DRAW+CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_ACTIVATE)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_DESTROYED)
	e2:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e2:SetCondition(s.condition)
	e2:SetTarget(s.target)
	e2:SetOperation(s.activate)
	c:RegisterEffect(e2)
end

-- Condición para activar desde la mano
function s.handcon(e)
	local tp=e:GetHandlerPlayer()
	local g=Duel.GetMatchingGroup(Card.IsType,tp,LOCATION_GRAVE,0,nil,TYPE_MONSTER)
	return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0 
		and #g>0 and g:FilterCount(Card.IsRace,nil,RACE_CYBERSE)==#g
end

-- Condición de activación (Destrucción de Ciberso LUZ/OSC)
function s.cfilter(c,tp)
	return c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_MZONE)
		and c:IsAttribute(ATTRIBUTE_LIGHT+ATTRIBUTE_DARK) and c:IsRace(RACE_CYBERSE)
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end

-- Target: Calcular cuántos robar
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=eg:FilterCount(s.cfilter,nil,tp)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,ct) end
	Duel.SetTargetParam(ct)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,ct)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,ct,tp,LOCATION_HAND)
end

-- Operación: Draw y Shuffle
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetChainInfo(0,CHAININFO_TARGET_PARAM)
	if Duel.Draw(tp,ct,REASON_EFFECT)==ct then
		Duel.ShuffleHand(tp)
		Duel.BreakEffect()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local g=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,LOCATION_HAND,0,ct,ct,nil)
		if #g>0 then
			Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		end
	end
end