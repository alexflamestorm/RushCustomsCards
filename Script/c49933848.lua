local s,id=GetID()
function s.initial_effect(c)
	-- Efecto 1: Enviar al GY y Destruir
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)
	
	-- Efecto 2: Reciclar y Robar
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,id)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.tdtg)
	e2:SetOperation(s.tdop)
	c:RegisterEffect(e2)
end

-- Lógica de Destrucción
function s.tgfilter1(c,tp)
	return c:IsRace(RACE_CYBERSE) and c:IsAbleToGrave()
		and Duel.IsExistingMatchingCard(s.tgfilter2,tp,LOCATION_DECK,0,1,nil,c:GetAttribute())
end
function s.tgfilter2(c,att)
	return c:IsRace(RACE_CYBERSE) and c:IsAttribute(att) and c:IsAbleToGrave()
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_MZONE) end
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter1,tp,LOCATION_HAND,0,1,nil,tp)
		and Duel.IsExistingTarget(nil,tp,0,LOCATION_MZONE,2,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,nil,tp,0,LOCATION_MZONE,2,2,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,2,tp,LOCATION_HAND+LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,2,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g1=Duel.SelectMatchingCard(tp,s.tgfilter1,tp,LOCATION_HAND,0,1,1,nil,tp)
	if #g1>0 then
		local att=g1:GetFirst():GetAttribute()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local g2=Duel.SelectMatchingCard(tp,s.tgfilter2,tp,LOCATION_DECK,0,1,1,nil,att)
		g1:Merge(g2)
		if Duel.SendtoGrave(g1,REASON_EFFECT)==2 then
			local tg=Duel.GetTargetCards(e)
			if #tg>0 then
				Duel.Destroy(tg,REASON_EFFECT)
			end
		end
	end
end

-- Lógica de Reciclaje
function s.tdfilter(c)
	return c:IsRace(RACE_CYBERSE) and c:IsAbleToDeck()
end
function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1)
		and Duel.IsExistingTarget(s.tdfilter,tp,LOCATION_GRAVE,0,2,nil) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.GetMatchingGroup(s.tdfilter,tp,LOCATION_GRAVE,0,nil)
	local g1=g:Select(tp,1,1,nil)
	local att=g1:GetFirst():GetAttribute()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g2=g:FilterSelect(tp,function(c) return c:IsAttribute(att) and c:GetCode()~=g1:GetFirst():GetCode() end,1,1,g1:GetFirst())
	g1:Merge(g2)
	Duel.SetTargetCard(g1)
	
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g1,2,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetTargetCards(e)
	if #tg==2 and Duel.SendtoDeck(tg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)==2 then
		Duel.ShuffleDeck(tp)
		Duel.BreakEffect()
		Duel.Draw(tp,1,REASON_EFFECT)
	end
end