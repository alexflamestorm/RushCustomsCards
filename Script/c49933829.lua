
local s,id=GetID()
function s.initial_effect(c)
	-- Invocación por Fusión (Estándar)
	c:EnableReviveLimit()
	aux.AddFusionProcMix(c,true,true,49933816,s.matfilter) -- 49933816 = Femtron

	-- Fusión de Contacto (Barajando desde Campo o GY)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.contactcon)
	e1:SetTarget(s.contacttg)
	e1:SetOperation(s.contactop)
	e1:SetValue(SUMMON_TYPE_SPECIAL)
	c:RegisterEffect(e1)

	-- Límite de Invocación Especial
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e2:SetCode(EFFECT_SPSUMMON_CONDITION)
	e2:SetValue(s.splimit)
	c:RegisterEffect(e2)

	-- Efecto de Robo (Pot of Greed para Trons)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_DRAW)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.drcon)
	e3:SetTarget(s.drtg)
	e3:SetOperation(s.drop)
	c:RegisterEffect(e3)
end

-- Filtros de Materiales
function s.matfilter(c,fc,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_LIGHT+ATTRIBUTE_DARK) and c:IsRace(RACE_CYBERSE) 
		and c:IsLevelBelow(4)
end

function s.splimit(e,se,sp,st)
	return not e:GetHandler():IsLocation(LOCATION_EXTRA) or (st&SUMMON_TYPE_SPECIAL)==SUMMON_TYPE_SPECIAL or (st&SUMMON_TYPE_FUSION)==SUMMON_TYPE_FUSION
end

-- Lógica de Fusión de Contacto
function s.contactfilter(c,tp)
	return (c:IsCode(49933816) or s.matfilter(c)) and c:IsAbleToDeck()
end

function s.contactcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local g=Duel.GetMatchingGroup(s.contactfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	return g:IsExists(Card.IsCode,1,nil,49933816) -- Femtron
		and g:IsExists(s.matfilter,1,nil) -- El otro material
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and Duel.GetFlagEffect(tp,id)==0 -- Límite de una vez por turno
end

function s.contacttg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=Duel.GetMatchingGroup(s.contactfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	local g1=g:Filter(Card.IsCode,nil,49933816)
	local g2=g:Filter(s.matfilter,nil)
	
	if g1:IsExists(g2.IsContains,1,nil) then
		-- Si una carta cumple ambas condiciones, manejamos la selección
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local sg1=g1:Select(tp,1,1,nil)
		g2:RemoveCard(sg1:GetFirst())
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local sg2=g2:Select(tp,1,1,nil)
		sg1:Merge(sg2)
		sg1:KeepAlive()
		e:SetLabelObject(sg1)
		return true
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local sg1=g1:Select(tp,1,1,nil)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local sg2=g2:Select(tp,1,1,nil)
		sg1:Merge(sg2)
		sg1:KeepAlive()
		e:SetLabelObject(sg1)
		return true
	end
end

function s.contactop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	Duel.SendtoDeck(g,nil,SEQ_DECORATE,REASON_COST)
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
	g:DeleteGroup()
end

-- Lógica de Robo
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(function(c) return c:IsAttribute(ATTRIBUTE_LIGHT+ATTRIBUTE_DARK) and c:IsRace(RACE_CYBERSE) end,tp,LOCATION_GRAVE,0,nil)
	return g:GetClassCount(Card.GetCode)>=3
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(2)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	if Duel.Draw(p,d,REASON_EFFECT)==2 then
		-- Restricción de robo (Efecto persistente)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetCode(EFFECT_CANNOT_DRAW)
		e1:SetTargetRange(1,0)
		e1:SetTarget(s.drawlimit)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
end

function s.drawlimit(e,re,tp)
	if not re then return false end
	local rc=re:GetHandler()
	return not (rc:IsAttribute(ATTRIBUTE_LIGHT+ATTRIBUTE_DARK) and rc:IsRace(RACE_CYBERSE))
end