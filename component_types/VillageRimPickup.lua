VillageRimPickup = {
    pickup_kind = "bow",
    bob_frame = 0,
    base_x = 0.0,
    base_y = 0.0,
    collected = false,

    OnStart = function(self)
        self.transform = self.actor:GetComponent("Transform")
        self.sprite = self.actor:GetComponent("SpriteRenderer")
        if self.transform ~= nil then
            self.base_x = self.transform.x
            self.base_y = self.transform.y
        end
        self:SetKind(self.pickup_kind)
    end,

    OnUpdate = function(self)
        if self.collected or self.transform == nil then
            return
        end

        self.bob_frame = self.bob_frame + 1
        self.transform.y = self.base_y + math.sin(self.bob_frame * 0.08) * 0.06
        self.transform.x = self.base_x

        local player = VillageRimShared.GetPlayer()
        if player ~= nil and player:IsAlive() then
            local distance = VillageRimShared.Distance(
                                 self.transform.x, self.transform.y,
                                 player:GetPositionX(), player:GetPositionY())
            if distance <= 0.42 then
                self:Collect(player)
            end
        end
    end,

    SetKind = function(self, kind)
        self.pickup_kind = kind or "bow"
        if self.sprite == nil then
            return
        end
        if self.pickup_kind == "shield" then
            self.sprite.sprite = "shield"
        else
            self.sprite.sprite = "bow"
        end
        self.sprite:SetSpriteCell(1, 1)
        self.sprite.scale_x = 0.85
        self.sprite.scale_y = 0.85
        self.sprite.sorting_order = 2400
        self.sprite.auto_sorting_order = false
    end,

    Place = function(self, x, y)
        if self.transform == nil then
            self.transform = self.actor:GetComponent("Transform")
        end
        self.base_x = x or 0.0
        self.base_y = y or 0.0
        if self.transform ~= nil then
            self.transform.x = self.base_x
            self.transform.y = self.base_y
        end
    end,

    Collect = function(self, player)
        self.collected = true
        VillageRimShared.PlaySfx(11, {"itemPickUp"}, 94)
        local state = VillageRimShared.GetRunState()
        if self.pickup_kind == "shield" then
            state.shield = true
            if player ~= nil then
                player:GrantShield()
            end
        else
            state.bow = true
            state.weapon = "bow"
            if player ~= nil then
                player:GrantBow()
            end
        end

        local director = VillageRimShared.GetDirector()
        if director ~= nil then
            director:NotifyPickupCollected(self.pickup_kind)
        end
        Actor.Destroy(self.actor)
    end
}
