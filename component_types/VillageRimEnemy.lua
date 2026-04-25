VillageRimEnemy = {
    enemy_kind = "slime",
    health = 1,
    max_health = 1,
    attack_timer = 0,
    attack_cooldown = 0,
    retarget_timer = 0,
    target_kind = "altar",
    alive = true,

    OnStart = function(self)
        self.transform = self.actor:GetComponent("Transform")
        self.sprite = self.actor:GetComponent("SpriteRenderer")
        self:SetKind(self.enemy_kind)
        self.health_visuals =
            VillageRimShared.CreateHealthVisuals(math.ceil(self.max_health / 2))
    end,

    OnUpdate = function(self)
        if not self.alive or self.transform == nil then
            return
        end

        if self.attack_cooldown > 0 then
            self.attack_cooldown = self.attack_cooldown - 1
        end
        if self.attack_timer > 0 then
            self.attack_timer = self.attack_timer - 1
        end

        local target = self:ResolveTarget()
        local move_x = 0.0
        local move_y = 0.0
        local face_x = 0.0
        local face_y = 1.0
        if target ~= nil and target:IsAlive() then
            local dx = target:GetPositionX() - self.transform.x
            local dy = target:GetPositionY() - self.transform.y
            face_x = dx
            face_y = dy
            local nx, ny, distance = VillageRimShared.Normalize(dx, dy)
            if distance <= (self.def.attack_range or 0.35) then
                self:Attack(target)
            else
                move_x = nx
                move_y = ny
                self.transform.x = self.transform.x + nx * self.def.speed
                self.transform.y = self.transform.y + ny * self.def.speed
            end
        end

        self:UpdateSprite(move_x, move_y, face_x, face_y)
        self:UpdateHealth()
    end,

    OnDestroy = function(self)
        VillageRimShared.DestroyHealthVisuals(self.health_visuals)
    end,

    SetKind = function(self, kind)
        self.enemy_kind = kind or "slime"
        self.def = VillageRimShared.enemy_defs[self.enemy_kind] or
                       VillageRimShared.enemy_defs.slime
        self.max_health = self.def.max_hp
        self.health = self.def.max_hp
        self.alive = true
        self.target_kind = self.def.target == "random" and "altar" or
                               self.def.target
    end,

    ResolveTarget = function(self)
        if self.def.target == "random" then
            self.retarget_timer = self.retarget_timer - 1
            if self.retarget_timer <= 0 then
                if math.random(1, 100) <= 45 then
                    self.target_kind = "player"
                else
                    self.target_kind = "altar"
                end
                self.retarget_timer = math.random(75, 145)
            end
        else
            self.target_kind = self.def.target
        end

        if self.target_kind == "player" then
            local player = VillageRimShared.GetPlayer()
            if player ~= nil and player:IsAlive() then
                return player
            end
        end

        return VillageRimShared.GetAltar()
    end,

    Attack = function(self, target)
        if self.attack_cooldown > 0 then
            return
        end
        self.attack_cooldown = self.def.attack_cooldown or 55
        self.attack_timer = 18
        target:TakeDamage(self.def.damage or 1)
    end,

    TakeDamage = function(self, amount, knockback_x, knockback_y)
        if not self.alive then
            return
        end

        self.health = math.max(0, self.health - (amount or 1))
        if self.transform ~= nil then
            self.transform.x = VillageRimShared.Clamp(
                                   self.transform.x + (knockback_x or 0.0),
                                   -3.1, 3.1)
            self.transform.y = VillageRimShared.Clamp(
                                   self.transform.y + (knockback_y or 0.0),
                                   -1.6, 1.6)
        end

        if self.health <= 0 then
            self.alive = false
            VillageRimShared.DestroyHealthVisuals(self.health_visuals)
            self.health_visuals = nil
            Actor.Destroy(self.actor)
        end
    end,

    UpdateSprite = function(self, move_x, move_y, face_x, face_y)
        if self.sprite == nil then
            return
        end

        if math.abs(move_x) > 0.0001 or math.abs(move_y) > 0.0001 then
            face_x = move_x
            face_y = move_y
        end

        local row, flip = VillageRimShared.DirectionRow(self.def.direction,
                                                        face_x, face_y)
        local image = self.def.walk
        local columns = self.def.columns or 4
        if self.attack_timer > 0 then
            image = self.def.attack
        elseif math.abs(move_x) <= 0.0001 and math.abs(move_y) <= 0.0001 then
            image = self.def.idle
            columns = math.min(columns, 4)
        end

        local column = (math.floor(Application.GetFrame() / 8) % columns) + 1
        self.sprite.sprite = image
        self.sprite:SetSpriteCell(row, column)
        self.sprite.scale_x = self.def.scale * flip
        self.sprite.scale_y = self.def.scale
        self.sprite.sorting_order =
            VillageRimShared.SortOrder(self.transform.y, 70)
        self.sprite.auto_sorting_order = false
    end,

    UpdateHealth = function(self)
        VillageRimShared.UpdateHealthVisuals(
            self.health_visuals, self.transform.x, self.transform.y - 0.38,
            self.health, self.max_health, 0.52,
            VillageRimShared.SortOrder(self.transform.y, 340))
    end,

    IsAlive = function(self)
        return self.alive
    end,

    GetPositionX = function(self)
        return self.transform and self.transform.x or 0.0
    end,

    GetPositionY = function(self)
        return self.transform and self.transform.y or 0.0
    end,

    GetHitRadius = function(self)
        return self.def and self.def.hit_radius or 0.25
    end
}
