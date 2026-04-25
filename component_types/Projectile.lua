Projectile = {
    vx = 1.0,
    vy = 0.0,
    speed = 0.06,
    damage = 2,
    radius = 0.20,
    life = 75,
    projectile_kind = "arrow",
    team = "player",
    reflected = false,
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

        local min_x, max_x, min_y, max_y =
            Shared.GetStageBounds(Scene.GetCurrent())
        if self.life <= 0 or self.transform.x < min_x - 0.45 or
            self.transform.x > max_x + 0.45 or
            self.transform.y < min_y - 0.45 or
            self.transform.y > max_y + 0.45 then
            self:DestroySelf()
            return
        end

        if self.projectile_kind == "sword_wave" then
            self:UpdateSwordWaveCollision()
            return
        end

        local enemies = Actor.FindAll("enemy")
        for index = 1, #enemies do
            local enemy = enemies[index]:GetComponent("Enemy")
            if enemy ~= nil and enemy:IsAlive() then
                local distance = Shared.Distance(
                                     self.transform.x, self.transform.y,
                                     enemy:GetPositionX(), enemy:GetPositionY())
                if distance <= self.radius + enemy:GetHitRadius() then
                    -- Arrows are piercing damage feedback only; sword hits own knockback.
                    enemy:TakeDamage(self.damage, 0.0, 0.0)
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
        local nx, ny, length = Shared.Normalize(vx or 1.0, vy or 0.0)
        if length <= 0.0 then
            nx = 1.0
            ny = 0.0
        end
        self.vx = nx
        self.vy = ny
        self.damage = damage or self.damage
        self.speed = speed or self.speed
        self.projectile_kind = "arrow"
        self.team = "player"
        self.reflected = false
        self.radius = 0.20
        self.launched = true
        self.life = 75
        if self.transform ~= nil then
            self.transform.x = x or 0.0
            self.transform.y = y or 0.0
            self.transform.rotation = self:DirectionToRotation(nx, ny)
        end
        self:UpdateSprite()
    end,

    LaunchSwordWave = function(self, x, y, vx, vy, damage, speed)
        if self.transform == nil then
            self.transform = self.actor:GetComponent("Transform")
        end
        local nx, ny, length = Shared.Normalize(vx or 1.0, vy or 0.0)
        if length <= 0.0 then
            nx = 1.0
            ny = 0.0
        end
        self.vx = nx
        self.vy = ny
        self.damage = damage or 2
        self.speed = speed or 0.045
        self.projectile_kind = "sword_wave"
        self.team = "enemy"
        self.reflected = false
        self.radius = 0.28
        self.launched = true
        self.life = 120
        if self.transform ~= nil then
            self.transform.x = x or 0.0
            self.transform.y = y or 0.0
            self.transform.rotation = self:DirectionToRotation(nx, ny)
        end
        self:UpdateSprite()
    end,

    UpdateSwordWaveCollision = function(self)
        if self.team == "enemy" then
            local player = Shared.GetPlayer()
            if player == nil or not player:IsAlive() then
                return
            end

            local distance = Shared.Distance(self.transform.x,
                                             self.transform.y,
                                             player:GetPositionX(),
                                             player:GetPositionY())
            -- Shield parry is centered on the player's body, not projected ahead.
            if player:IsShieldActive() and
                distance <= self.radius + player:GetShieldRadius() then
                self:ReflectFromPlayer(player)
                return
            end

            if distance <= self.radius + player:GetHitRadius() then
                player:TakeDamage(self.damage, self.vx, self.vy)
                self:DestroySelf()
            end
            return
        end

        -- Reflected sword waves only hurt the boss, never other enemies.
        local enemies = Actor.FindAll("enemy")
        for index = 1, #enemies do
            local enemy = enemies[index]:GetComponent("Enemy")
            if enemy ~= nil and enemy:IsAlive() and enemy:IsBoss() then
                local distance = Shared.Distance(
                                     self.transform.x, self.transform.y,
                                     enemy:GetPositionX(), enemy:GetPositionY())
                if distance <= self.radius + enemy:GetHitRadius() then
                    enemy:TakeDamage(self.damage + 1, self.vx * 0.24,
                                     self.vy * 0.24)
                    self:DestroySelf()
                    return
                end
            end
        end
    end,

    ReflectFromPlayer = function(self, player)
        self.vx = -self.vx
        self.vy = -self.vy
        self.team = "player"
        self.reflected = true
        self.life = 95
        -- Nudge reflected waves away from the player so they do not parry twice.
        if self.transform ~= nil and player ~= nil then
            self.transform.x = player:GetPositionX() + self.vx * 0.34
            self.transform.y = player:GetPositionY() + self.vy * 0.34
            self.transform.rotation = self:DirectionToRotation(self.vx, self.vy)
        end
        Shared.PlaySfx(14, {"shieldblock"}, 92)
        self:UpdateSprite()
    end,

    DirectionToRotation = function(self, vx, vy)
        if self.projectile_kind == "sword_wave" then
            -- YellowFIRE [3,4] faces right, so zero degrees means +X.
            return math.deg(math.atan(vy, vx))
        end
        -- Arrow.png [1,1] points down. Rotate that one sprite toward velocity.
        return math.deg(math.atan(vy, vx)) - 90.0
    end,

    UpdateSprite = function(self)
        if self.sprite == nil then
            return
        end

        if self.projectile_kind == "sword_wave" then
            self.sprite.sprite = "Enemies/GoblinSwordSaint/YellowFIRE"
            self.sprite:SetSpriteCell(3, 4)
            self.sprite.scale_x = 0.74
            self.sprite.scale_y = 0.74
        else
            self.sprite.sprite = "Arrow"
            self.sprite:SetSpriteCell(1, 1)
            self.sprite.scale_x = 1.15
            self.sprite.scale_y = 1.15
        end
        self.sprite.sorting_order =
            Shared.SortOrder(self.transform and self.transform.y or 0.0,
                                       180)
        self.sprite.auto_sorting_order = false
        if self.transform ~= nil then
            self.transform.rotation = self:DirectionToRotation(self.vx, self.vy)
        end
    end,

    DestroySelf = function(self)
        if self.destroyed then
            return
        end
        self.destroyed = true
        Actor.Destroy(self.actor)
    end
}
