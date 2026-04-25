VillageRimProjectile = {
    vx = 1.0,
    vy = 0.0,
    speed = 0.06,
    damage = 2,
    radius = 0.20,
    life = 75,
    launched = false,
    destroyed = false,

    OnStart = function(self)
        self.transform = self.actor:GetComponent("Transform")
        self.sprite = self.actor:GetComponent("SpriteRenderer")
        self:UpdateSprite()
    end,

    OnUpdate = function(self)
        if self.destroyed or not self.launched or self.transform == nil then
            return
        end

        self.life = self.life - 1
        self.transform.x = self.transform.x + self.vx * self.speed
        self.transform.y = self.transform.y + self.vy * self.speed
        self:UpdateSprite()

        if self.life <= 0 or math.abs(self.transform.x) > 3.35 or
            math.abs(self.transform.y) > 1.9 then
            self:DestroySelf()
            return
        end

        local enemies = Actor.FindAll("enemy")
        for index = 1, #enemies do
            local enemy = enemies[index]:GetComponent("VillageRimEnemy")
            if enemy ~= nil and enemy:IsAlive() then
                local distance = VillageRimShared.Distance(
                                     self.transform.x, self.transform.y,
                                     enemy:GetPositionX(), enemy:GetPositionY())
                if distance <= self.radius + enemy:GetHitRadius() then
                    enemy:TakeDamage(self.damage, self.vx * 0.10,
                                     self.vy * 0.10)
                    self:DestroySelf()
                    return
                end
            end
        end
    end,

    Launch = function(self, x, y, vx, vy, damage, speed)
        if self.transform == nil then
            self.transform = self.actor:GetComponent("Transform")
        end
        local nx, ny, length = VillageRimShared.Normalize(vx or 1.0, vy or 0.0)
        if length <= 0.0 then
            nx = 1.0
            ny = 0.0
        end
        self.vx = nx
        self.vy = ny
        self.damage = damage or self.damage
        self.speed = speed or self.speed
        self.launched = true
        self.life = 75
        if self.transform ~= nil then
            self.transform.x = x or 0.0
            self.transform.y = y or 0.0
        end
        self:UpdateSprite()
    end,

    UpdateSprite = function(self)
        if self.sprite == nil then
            return
        end

        local row, flip = VillageRimShared.StandardDirectionRow(self.vx, self.vy)
        local column = (math.floor(Application.GetFrame() / 4) % 12) + 1
        self.sprite.sprite = "Arrow"
        self.sprite:SetSpriteCell(row, column)
        self.sprite.scale_x = 1.15 * flip
        self.sprite.scale_y = 1.15
        self.sprite.sorting_order =
            VillageRimShared.SortOrder(self.transform and self.transform.y or 0.0,
                                       180)
        self.sprite.auto_sorting_order = false
    end,

    DestroySelf = function(self)
        if self.destroyed then
            return
        end
        self.destroyed = true
        Actor.Destroy(self.actor)
    end
}
