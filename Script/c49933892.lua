local s,id=GetID()
function s.initial_effect(c)
	-- Invocación por Fusión
	c:EnableReviveLimit()
	aux.AddFusionProcMix(c,true,true,49933858,s.matfilter) -- 10000063 = Ray Strike Dragon

	-- Invocación Especial alternativa
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCountLimit(1,id+SUMMON_ID)
	e1:SetCondition(s.altcon)
	e1:SetTarget(s.alttg)
	e1:SetOperation(s.altop)
	c:RegisterEffect(e1)

	-- Daño de penetración (Piercing)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_PIERCE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.piercetg)
	c:RegisterEffect(e2)

	-- Reciclar Magias/Trampas
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id)
	e3:SetTarget(s.settg)
	e3:SetOperation(s.setop)
	c:RegisterEffect(e3)
end

-- Filtros y Auxiliares
function s.matfilter(c,fc,sumtype,tp)
	return (c:GetCode()>=49933851 and c:GetCode()<=49933906) or c:IsSetCard(0x871)
end

function s.altfilter(c,tp)
	return c:IsAttribute(ATTRIBUTE_WATER) and c:IsRace(RACE_DRAGON) and Duel.GetMZoneCount(tp,c)>0
end

function s.altcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,49933885),tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingMatchingCard(s.altfilter,tp,LOCATION_MZONE,0,1,nil,tp)
end

function s.alttg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=Duel.GetMatchingGroup(s.altfilter,tp,LOCATION_MZONE,0,nil,tp)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
		local sg=g:Select(tp,1,1,nil)
		if #sg>0 then
			sg:KeepAlive()
			e:SetLabelObject(sg)
			return true
		end
	end
	return false
end

function s.altop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.Release(g,REASON_COST)
	g:DeleteGroup()
end

-- Lógica de Piercing
function s.piercetg(e,c)
	return c:IsAttribute(ATTRIBUTE_WATER) and c:IsRace(RACE_DRAGON)
end

-- Lógica de Setear Dragonic
function s.setfilter(c)
	return (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)) 
		and (c:IsSetCard(0x872) or c:IsCode(49933866,49933867,49933868,49933872,49933873,49933876,49933877,49933879,49933884,49933888,49933890,49933893,49933894,49933895,49933896,49933897))
		and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.setfilter),tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
		local sg=g:Select(tp,1,2,nil)
		Duel.SSet(tp,sg)
	end
end