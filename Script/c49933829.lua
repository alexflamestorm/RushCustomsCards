
local s,id=GetID()
function s.initial_effect(c)
	-- Materiales: Femtron + 1 Cyberse LUZ/OSC Nivel 4 o menor
	c:EnableReviveLimit()
	aux.AddFusionProcMix(c,true,true,49933816,s.matfilter)
	
	-- Invocación por contacto (Barajando al Deck)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.sprcon)
	e1:SetTarget(s.sprtg)
	e1:SetOperation(s.sprop)
	c:RegisterEffect(e1)
	
	-- Efecto de Robo: Draw 2
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.drcon)
	e2:SetTarget(s.drtg)
	e2:SetOperation(s.drop)
	c:RegisterEffect(e2)
end

-- Filtro para material genérico
function s.matfilter(c,fc,sumtype,tp)
	return c:IsRace(RACE_CYBERSE,fc,sumtype,tp) and (c:IsAttribute(ATTRIBUTE_LIGHT,fc,sumtype,tp) or c:IsAttribute(ATTRIBUTE_DARK,fc,sumtype,tp))
		and c:IsLevelBelow(4)
end

-- Lógica de Invocación por Contacto
function s.sprfilter(c)
	return (c:IsFaceup() or c:IsLocation(LOCATION_GRAVE)) and c:IsAbleToDeckAsCost()
end
function s.sprcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local g1=Duel.GetMatchingGroup(s.sprfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	return g1:IsExists(Card.IsCode,1,nil,49933816) -- Femtron
		and g1:IsExists(s.matfilter,1,nil,nil,SUMMON_TYPE_SPECIAL,tp) -- El otro material
end
function s.sprtg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g1=Duel.GetMatchingGroup(s.sprfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	local g_fem=g1:Filter(Card.IsCode,nil,49933816)
	local g_other=g1:Filter(s.matfilter,nil,nil,SUMMON_TYPE_SPECIAL,tp)
	
	if g_fem:IsExists(aux.IsInGroup,1,nil,g_other) then
		-- Si una carta cumple ambos requisitos (como Dark Femtron), manejar selección
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local m1=g_fem:Select(tp,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local m2=g_other:Select(tp,1,1,m1)
	m1:Merge(m2)
	if #m1==2 then
		m1:KeepAlive()
		e:SetLabelObject(m1)
		return true
	end
	return false
end
function s.sprop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_COST)
	g:DeleteGroup()
end

-- Lógica de Robo
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsRace,tp,LOCATION_GRAVE,0,nil,RACE_CYBERSE)
	return g:GetClassCount(Card.GetCode)>=3
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.Draw(tp,2,REASON_EFFECT)==2 then
		-- Restricción: Solo Cyberse LUZ/OSC pueden hacerte robar
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetCode(EFFECT_CANNOT_DRAW)
		e1:SetTargetRange(1,0)
		e1:SetCondition(s.drawlimit)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
end
function s.drawlimit(e,re,tp)
	if not re then return false end
	local rc=re:GetHandler()
	return not (rc:IsRace(RACE_CYBERSE) and (rc:IsAttribute(ATTRIBUTE_LIGHT) or rc:IsAttribute(ATTRIBUTE_DARK)))
end