local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Material: 3 Ciberso LUZ/OSC
	c:EnableReviveLimit()
	aux.AddFusionProcMixN(c,true,true,s.matfilter,3)
	
	-- Invocación solo por Fusión
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(aux.fuslimit)
	c:RegisterEffect(e0)

	-- Protección: No puede ser destruido por efectos del oponente
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetValue(aux.indoval)
	c:RegisterEffect(e1)
	
	-- Efecto de Control (Destruir/Negar/Devolver)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id) -- Se ajustará en el Operation con Flags
	e2:SetTarget(s.target)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
	
	-- Verificar materiales al fusionar
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_MATERIAL_CHECK)
	e3:SetValue(s.matcheck)
	c:RegisterEffect(e3)
	e2:SetLabelObject(e3)
end

s.listed_names={49933816}

function s.matfilter(c,fc,sumtype,tp)
	return c:IsRace(RACE_CYBERSE,fc,sumtype,tp) and (c:IsAttribute(ATTRIBUTE_LIGHT,fc,sumtype,tp) or c:IsAttribute(ATTRIBUTE_DARK,fc,sumtype,tp))
end

function s.matcheck(e,c)
	local g=c:GetMaterial()
	local ct=0
	if g:IsExists(Card.IsCode,1,nil,49933816) then
		local g2=g:Filter(Card.ListsCode,nil,49933816)
		if #g2>=2 then ct=1 end
	end
	e:SetLabel(ct)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsOnField() end
	-- Manejo de Count Limit Dinámico (1 o 3 veces)
	local c=e:GetHandler()
	local max_uses = e:GetLabelObject():GetLabel()==1 and 3 or 1
	if chk==0 then 
		return c:GetFlagEffect(id)<max_uses 
		and Duel.IsExistingTarget(nil,tp,0,LOCATION_ONFIELD,1,nil) 
	end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,nil,tp,0,LOCATION_ONFIELD,1,1,nil)
	c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	
	local op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2),aux.Stringid(id,3))
	
	if op==0 then -- Destruir
		Duel.Destroy(tc,REASON_EFFECT)
	elseif op==1 then -- Negar
		local c=e:GetHandler()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e2)
	else -- Devolver a la mano
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end
