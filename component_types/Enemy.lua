Enemy = {
    enemy_kind = "slime",
    health = 1,
    max_health = 1,
    attack_timer = 0,
    attack_cooldown = 0,
    retarget_timer = 0,
    special_cooldown = 0,
    stun_timer = 0,
    target_kind = "altar",
    alive = true,

    OnStart = function(self)
        self.transform = self.actor:GetComponent("Transform")
        self.sprite = self.actor:GetComponent("SpriteRenderer")
        local min_x, max_x, min_y, max_y =
            Shared.GetStageBounds(Scene.GetCurrent())
        self.min_x = min_x
        self.max_x = max_x
        self.min_y = min_y
        self.max_y = max_y
        self:SetKind(self.enemy_kind)
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
        if self.special_cooldown > 0 then
            self.special_cooldown = self.special_cooldown - 1
        end
        if self.stun_timer > 0 then
            self.stun_timer = self.stun_timer - 1
            self:UpdateSprite(0.0, 0.0, self.last_face_x or 0.0,
                              self.last_face_y or 1.0)
            self:UpdateHealthDisplay()
            return
        end

        local target = self:ResolveTarget()
        local move_x = 0.0
        local move_y = 0.0
        local face_x = 0.0
        local face_y = 1.0
        local target_distance = 999.0
        if target ~= nil and target:IsAlive() then
            local dx = target:GetPositionX() - self.transform.x
            local dy = target:GetPositionY() - self.transform.y
            face_x = dx
            face_y = dy
            local nx, ny, distance = Shared.Normalize(dx, dy)
            target_distance = distance
            if distance <= (self.def.attack_range or 0.35) then
                self:Attack(target)
            else
                move_x = nx
                move_y = ny
                self.transform.x = Shared.Clamp(
                                       self.transform.x + nx * self.def.speed,
                                       self.min_x + self:GetHitRadius(),
                                       self.max_x - self:GetHitRadius())
                self.transform.y = Shared.Clamp(
                                       self.transform.y + ny * self.def.speed,
                                       self.min_y + self:GetHitRadius(),
                                       self.max_y - self:GetHitRadius())
            end
        end

        self:MaybeUseSpecial(target, face_x, face_y, target_distance)
        self:UpdateSprite(move_x, move_y, face_x, face_y)
        self:UpdateHealthDisplay()
    end,

    OnDestroy = function(self)
        Shared.DestroyHealthVisuals(self.boss_health_visuals)
    end,

    SetKind = function(self, kind)
        self.enemy_kind = kind or "slime"
        self.def = Shared.enemy_defs[self.enemy_kind] or
                       Shared.enemy_defs.slime
        self.max_health = self.def.max_hp
        self.health = self.def.max_hp
        self.alive = true
        self.stun_timer = 0
        self.target_kind = self.def.target == "random" and "altar" or
                               self.def.target
        Shared.DestroyHealthVisuals(self.boss_health_visuals)
        self.boss_health_visuals = nil
        if self.def.is_boss then
            self.boss_health_visuals =
                Shared.CreateHealthVisuals(math.ceil(self.max_health / 2))
        end
        self.special_cooldown = math.random(
                                    self.def.special_initial_cooldown_min or
                                        80,
                                    self.def.special_initial_cooldown_max or
                                        130)
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
            local player = Shared.GetPlayer()
            if player ~= nil and player:IsAlive() then
                return player
            end
        end

        return Shared.GetAltar()
    end,

    Attack = function(self, target)
        if self.attack_cooldown > 0 then
            return
        end
        self.attack_cooldown = self.def.attack_cooldown or 55
        self.attack_timer = 18
        local dx = target:GetPositionX() - self.transform.x
        local dy = target:GetPositionY() - self.transform.y
        local nx, ny = Shared.Normalize(dx, dy)
        if self.def.is_boss and target.IsShieldActive ~= nil and
            target:IsShieldActive() then
            -- Boss melee can be parried too, but this parry stuns instead of
            -- reflecting damage back into the enemy.
            self:Stun(60)
            Shared.PlaySfx(14, {"shieldblock"}, 92)
            return
        end
        target:TakeDamage(self.def.damage or 1, nx, ny)
    end,

    Stun = function(self, frames)
        self.stun_timer = math.max(self.stun_timer or 0, frames or 30)
        self.attack_timer = 0
        self.attack_cooldown = math.max(self.attack_cooldown or 0, 18)
    end,

    MaybeUseSpecial = function(self, target, face_x, face_y, distance)
        if self.def.special ~= "sword_wave" or target == nil or
            not target:IsAlive() then
            return
        end
        if self.special_cooldown > 0 or self.attack_timer > 0 then
            return
        end
        if distance < (self.def.special_min_range or 0.6) then
            return
        end

        local nx, ny, length = Shared.Normalize(face_x, face_y)
        if length <= 0.0 then
            nx = 1.0
            ny = 0.0
        end

        self.attack_timer = self.def.special_attack_timer or 22
        self.special_cooldown = math.random(
                                    self.def.special_cooldown_min or 90,
                                    self.def.special_cooldown_max or 150)

        local actor = Actor.Instantiate("SwordWaveProjectile")
        if actor == nil then
            return
        end

        local projectile = actor:GetComponent("Projectile")
        if projectile ~= nil then
            projectile:LaunchSwordWave(self.transform.x + nx * 0.34,
                                       self.transform.y + ny * 0.34,
                                       nx, ny,
                                       self.def.special_damage or 2,
                                       self.def.special_speed or 0.045)
        end
        Shared.PlaySfx(16, {"goblinsaint_swordwave"}, 88)
    end,

    TakeDamage = function(self, amount, knockback_x, knockback_y)
        if not self.alive then
            return
        end

        self.health = math.max(0, self.health - (amount or 1))
        if self.transform ~= nil then
            -- Apply knockback immediately; these enemies are script-driven, not physics-driven.
            self.transform.x = Shared.Clamp(
                                   self.transform.x + (knockback_x or 0.0),
                                   self.min_x + self:GetHitRadius(),
                                   self.max_x - self:GetHitRadius())
            self.transform.y = Shared.Clamp(
                                   self.transform.y + (knockback_y or 0.0),
                                   self.min_y + self:GetHitRadius(),
                                   self.max_y - self:GetHitRadius())
        end

        if self.health <= 0 then
            self.alive = false
            Shared.DestroyHealthVisuals(self.boss_health_visuals)
            self.boss_health_visuals = nil
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
        self.last_face_x = face_x
        self.last_face_y = face_y

        local row, flip = Shared.DirectionRow(self.def.direction,
                                                        face_x, face_y)
        local image = self.def.walk
        local columns = self.def.walk_columns or self.def.columns or 4
        if self.attack_timer > 0 then
            image = self.def.attack
            columns = self.def.attack_columns or columns
        elseif math.abs(move_x) <= 0.0001 and math.abs(move_y) <= 0.0001 then
            image = self.def.idle
            columns = self.def.idle_columns or math.min(columns, 4)
        end

        local column = (math.floor(Application.GetFrame() / 8) % columns) + 1
        self.sprite.sprite = image
        self.sprite:SetSpriteCell(row, column)
        self.sprite.scale_x = self.def.scale * flip
        self.sprite.scale_y = self.def.scale
        self.sprite.sorting_order =
            Shared.SortOrder(self.transform.y, 70)
        self.sprite.auto_sorting_order = false
        if self.stun_timer ~= nil and self.stun_timer > 0 then
            self.sprite.r = 170
            self.sprite.g = 210
            self.sprite.b = 255
        else
            self.sprite.r = 255
            self.sprite.g = 255
            self.sprite.b = 255
        end
        self.sprite.a = 255
    end,

    UpdateHealthDisplay = function(self)
        if self:IsBoss() then
            self:UpdateBossHealthUI()
        else
            self:DrawHealthNumber()
        end
    end,

    UpdateBossHealthUI = function(self)
        if self.boss_health_visuals == nil then
            return
        end

        local window_width = Shared.GetWindowSize()
        local ui_x, ui_y = Shared.ScreenToWorld(window_width * 0.5, 96)
        -- Boss health is promoted to HUD space so the player can track the duel.
        Shared.UpdateHealthVisuals(self.boss_health_visuals, ui_x, ui_y,
                                   self.health, self.max_health, 1.02, 3300)
    end,

    DrawHealthNumber = function(self)
        if self.transform == nil then
            return
        end

        local text = tostring(math.max(0, self.health)) .. "/" ..
                         tostring(math.max(1, self.max_health))
        local screen_x, screen_y =
            Shared.WorldToScreen(self.transform.x, self.transform.y - 0.52)
        local text_x = screen_x - (#text * 3.5)

        -- Draw a tiny shadow first; direct numeric labels need contrast over crops.
        Text.Draw(text, text_x + 1, screen_y + 1, "NotoSans-Regular", 13,
                  24, 18, 14, 210)
        Text.Draw(text, text_x, screen_y, "NotoSans-Regular", 13,
                  250, 238, 198, 255)
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
    end,

    GetKind = function(self)
        return self.enemy_kind
    end,

    IsBoss = function(self)
        return self.def ~= nil and self.def.is_boss == true
    end
}
