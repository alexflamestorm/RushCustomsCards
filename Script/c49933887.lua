local s,id=GetID()
function s.initial_effect(c)
	-- Equipar
	aux.AddEquipProcedure(c,nil,s.eqfilter)
	
	-- Aumento de ATK
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_EQUIP)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetCondition(s.con)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)
	
	-- Ataques Adicionales
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_EQUIP)
	e2:SetCode(EFFECT_EXTRA_ATTACK)
	e2:SetCondition(s.con)
	e2:SetValue(s.atkcount)
	c:RegisterEffect(e2)
	
	-- Restricción de ataque directo
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_EQUIP)
	e3:SetCode(EFFECT_CANNOT_DIRECT_ATTACK)
	e3:SetCondition(s.con)
	c:RegisterEffect(e3)
end

-- Filtro: Solo Dragones LUZ u OSCURIDAD
function s.eqfilter(c)
	return c:IsRace(RACE_DRAGON) and (c:IsAttribute(ATTRIBUTE_LIGHT) or c:IsAttribute(ATTRIBUTE_DARK))
end

-- Condición: Controlar 2+ monstruos con el mismo nivel que el equipado
function s.con(e)
	local ec=e:GetHandler():GetEquipTarget()
	if not ec or ec:GetLevel()<=0 then return false end
	local g=Duel.GetMatchingGroup(Card.IsFaceup,e:GetHandlerPlayer(),LOCATION_MZONE,0,nil)
	return g:IsExists(Card.IsLevel,2,nil,ec:GetLevel())
end

-- Valor de ATK: Suma del ATK de otros con el mismo nombre
function s.atkval(e,c)
	local ec=e:GetHandler():GetEquipTarget()
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,ec)
	return g:Filter(Card.IsCode,nil,ec:GetCode()):Sum(Card.GetAttack)
end

-- Cantidad de ataques: 1 por cada otro monstruo con el mismo nombre
function s.atkcount(e,c)
	local ec=e:GetHandler():GetEquipTarget()
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,ec)
	return g:FilterCount(Card.IsCode,nil,ec:GetCode())
end