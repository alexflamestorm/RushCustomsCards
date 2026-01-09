local s,id=GetID()
function s.initial_effect(c)
	-- Invocación Especial (Mano o Cementerio)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	
	-- Efecto de Empuje (Piercing y Ataque Extra)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetCost(s.cost)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
end

-- Filtros para la Invocación Especial
function s.spfilter1(c)
	return c:IsLevel(9) and (c:IsAttack(2500) or c:IsDefense(2500))
end
function s.spfilter2(c)
	return c:IsRace(RACE_FIEND)
end

function s.spcon(e,c,tp)
	if c==nil then return true end
	local g1=Duel.GetMatchingGroup(s.spfilter1,tp,LOCATION_MZONE,0,nil)
	local g2=Duel.GetMatchingGroup(s.spfilter2,tp,LOCATION_MZONE,0,nil)
	return (Duel.GetLocationCount(tp,LOCATION_MZONE)>-1 and #g1>0) 
		or (Duel.GetLocationCount(tp,LOCATION_MZONE)>-2 and #g2>1)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g1=Duel.GetMatchingGroup(s.spfilter1,tp,LOCATION_MZONE,0,nil)
	local g2=Duel.GetMatchingGroup(s.spfilter2,tp,LOCATION_MZONE,0,nil)
	local b1= #g1>0
	local b2= #g2>1
	local op=0
	if b1 and b2 then op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
	elseif b1 then op=0
	else op=1 end
	
	if op==0 then
		local sg=g1:Select(tp,1,1,nil)
		if #sg>0 then
			sg:KeepAlive()
			e:SetLabelObject(sg)
			return true
		end
	else
		local sg=g2:Select(tp,2,2,nil)
		if #sg>0 then
			sg:KeepAlive()
			e:SetLabelObject(sg)
			return true
		end
	end
	return false
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=e:GetLabelObject()
	Duel.Release(g,REASON_COST)
	g:DeleteGroup()
end

-- Costo del efecto
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,500) end
	Duel.PayLPCost(tp,500)
end

-- Aplicación de efectos de batalla
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	-- Daño de penetración para TODOS tus monstruos
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_PIERCE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsControler,tp))
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	
	-- Ataque adicional para Demonios (Fiend)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_EXTRA_ATTACK)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(aux.TargetBoolFunction(Card.IsRace,RACE_FIEND))
	e2:SetValue(1)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
	
	-- Nota visual para el jugador
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e3:SetDescription(aux.Stringid(id,3)) -- "Infligiendo daño de penetración y ataques extra"
	e3:SetTargetRange(1,0)
	e3:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e3,tp)
end