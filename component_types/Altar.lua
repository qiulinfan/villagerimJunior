Altar = {
    max_health = 12,
    health = 12,
    stage_name = "",
    alive = true,

    OnStart = function(self)
        self.transform = self.actor:GetComponent("Transform")
        self.sprite = self.actor:GetComponent("SpriteRenderer")
        self.health = self.max_health
        self.alive = true
        self.is_victory_display = Scene.GetCurrent() == "victory"
        if not self.is_victory_display then
            self.health_visuals =
                Shared.CreateHealthVisuals(math.ceil(self.max_health / 2))
        end
        self:RefreshSprite()
    end,

    OnUpdate = function(self)
        if self.transform == nil or self.is_victory_display then
            return
        end
        Shared.UpdateHealthVisuals(
            self.health_visuals, self.transform.x, self.transform.y - 0.58,
            self.health, self.max_health, 0.88,
            Shared.SortOrder(self.transform.y, 420))
    end,

    OnDestroy = function(self)
        Shared.DestroyHealthVisuals(self.health_visuals)
    end,

    SetStage = function(self, stage_name)
        self.stage_name = stage_name or ""
    end,

    RefreshSprite = function(self)
        if self.sprite == nil then
            return
        end
        if self.alive then
            self.sprite.sprite = "altar/altar"
        else
            self.sprite.sprite = "altar/altarBroken"
        end
        self.sprite.scale_x = 0.8
        self.sprite.scale_y = 0.8
        self.sprite.sorting_order =
            Shared.SortOrder(self.transform and self.transform.y or 0.0, 20)
        self.sprite.auto_sorting_order = false
    end,

    TakeDamage = function(self, amount)
        if not self.alive then
            return
        end
        self.health = math.max(0, self.health - (amount or 1))
        if self.health <= 0 then
            self.alive = false
            self:RefreshSprite()
            local director = Shared.GetDirector()
            if director ~= nil then
                director:NotifyAltarDestroyed()
            end
        end
    end,

    IsAlive = function(self)
        return self.alive
    end,

    GetPositionX = function(self)
        return self.transform and self.transform.x or 0.0
    end,

    GetPositionY = function(self)
        return self.transform and self.transform.y or 0.0
    end
}
