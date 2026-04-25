local function CardinalizeDirection(dx, dy, fallback_x, fallback_y)
    if math.abs(dx) <= 0.0001 and math.abs(dy) <= 0.0001 then
        return fallback_x or 1.0, fallback_y or 0.0
    end

    if math.abs(dx) > math.abs(dy) then
        return (dx < 0.0) and -1.0 or 1.0, 0.0
    end
    return 0.0, (dy < 0.0) and -1.0 or 1.0
end

local function GetMouseWorldPosition()
    local mouse_position = Input.GetMousePosition()
    return Shared.ScreenToWorld(mouse_position.x, mouse_position.y)
end

Player = {
    max_health = 10,
    health = 10,
    move_speed = 0.035,
    sprite_scale = 1.72,
    shield_move_factor = 0.58,
    sword_damage = 2,
    sword_range = 0.62,
    sword_attack_duration = 18,
    sword_hit_frame = 7,
    bow_damage = 2,
    bow_attack_duration = 16,
    bow_release_frame = 6,
    bow_projectile_speed = 0.068,
    invulnerable_frames = 38,
    hurt_frames = 18,
    death_frames = 90,
    hit_radius = 0.18,
    shield_radius = 0.38,
    stage_name = "",
    facing_x = 1.0,
    facing_y = 0.0,
    attack_timer = 0,
    attack_kind = "",
    invulnerable_timer = 0,
    death_timer = 0,
    alive = true,
    min_x = -3.05,
    max_x = 3.05,
    min_y = -1.55,
    max_y = 1.55,

    OnStart = function(self)
        self.transform = self.actor:GetComponent("Transform")
        self.sprite = self.actor:GetComponent("SpriteRenderer")

        local scene_name = Scene.GetCurrent()
        self.is_victory_display = scene_name == "victory"
        local min_x, max_x, min_y, max_y =
            Shared.GetStageBounds(scene_name)
        local padding = math.max(0.12, self.hit_radius)
        self.min_x = min_x + padding
        self.max_x = max_x - padding
        self.min_y = min_y + padding
        self.max_y = max_y - padding

        if self.transform ~= nil then
            self.transform.x =
                Shared.Clamp(self.transform.x, self.min_x, self.max_x)
            self.transform.y =
                Shared.Clamp(self.transform.y, self.min_y, self.max_y)
        end

        self.health = self.max_health
        self.alive = true
        self.death_timer = 0
        self.invulnerable_timer = 0
        self.hurt_timer = 0
        self.attack_timer = 0
        self.attack_kind = ""
        self.attacked_targets = {}
        self.pending_shot_x = 1.0
        self.pending_shot_y = 0.0

        if not self.is_victory_display then
            self.health_visuals =
                Shared.CreateHealthVisuals(math.ceil(self.max_health / 2))
        end
        self.shield_visual = Shared.SpawnVisual()

        local state = Shared.GetRunState()
        if state.weapon == nil or state.weapon == "" then
            state.weapon = "sword"
        end
        if self.stage_name == "goblin_raid" then
            state.bow = true
            state.weapon = "bow"
        end
        if not state.bow and state.weapon == "bow" then
            state.weapon = "sword"
        end

        self:UpdateHealthUI()
        self:UpdateShieldVisual(false)
        self:ApplySpriteTint(false)
        self:RenderLocomotionSprite(0.0, 0.0)
    end,

    OnUpdate = function(self)
        if self.transform == nil or self.sprite == nil then
            return
        end

        if self.invulnerable_timer > 0 then
            self.invulnerable_timer = self.invulnerable_timer - 1
        end
        if self.hurt_timer > 0 then
            self.hurt_timer = self.hurt_timer - 1
        end

        if not self.alive then
            self:UpdateDeath()
            self:UpdateHealthUI()
            self:UpdateShieldVisual(false)
            return
        end

        if self.is_victory_display then
            self:RenderLocomotionSprite(0.0, 0.0)
            self:UpdateShieldVisual(false)
            return
        end

        self:HandleWeaponKeys()
        local move_x, move_y = self:ReadMovement()
        local mouse_world_x, mouse_world_y = GetMouseWorldPosition()
        local mouse_aim_x, mouse_aim_y = Shared.Normalize(
                                           mouse_world_x - self.transform.x,
                                           mouse_world_y - self.transform.y)
        local mouse_face_x, mouse_face_y = CardinalizeDirection(
                                             mouse_world_x - self.transform.x,
                                             mouse_world_y - self.transform.y,
                                             self.facing_x, self.facing_y)
        local move_face_x, move_face_y = CardinalizeDirection(
                                           move_x, move_y, self.facing_x,
                                           self.facing_y)

        local left_click = Input.GetMouseButtonDown(1)
        local mouse_click = left_click or Input.GetMouseButtonDown(2) or
                                Input.GetMouseButtonDown(3)
        if mouse_click then
            self.facing_x = mouse_face_x
            self.facing_y = mouse_face_y
        elseif self.attack_timer <= 0 and
               (move_x ~= 0.0 or move_y ~= 0.0) then
            self.facing_x = move_face_x
            self.facing_y = move_face_y
        elseif self.attack_timer <= 0 then
            self.facing_x = mouse_face_x
            self.facing_y = mouse_face_y
        end

        local shield_active = self:IsShieldActive()
        self:Move(move_x, move_y, shield_active)

        local wants_attack = Input.GetKeyDown("space") or
                                 Input.GetKeyDown("j") or left_click
        if self.attack_timer <= 0 and wants_attack and not shield_active then
            self:BeginAttack(mouse_aim_x, mouse_aim_y)
        end

        self:UpdateAttack()
        if self.attack_timer <= 0 then
            if self.hurt_timer > 0 then
                self:RenderDamageSprite()
            else
                self:RenderLocomotionSprite(move_x, move_y)
            end
        end

        self:ApplySpriteTint(shield_active)
        self:UpdateHealthUI()
        self:UpdateShieldVisual(shield_active)
    end,

    OnDestroy = function(self)
        Shared.DestroyHealthVisuals(self.health_visuals)
        Shared.DestroyVisual(self.shield_visual)
    end,

    SetStage = function(self, stage_name)
        self.stage_name = stage_name or ""
    end,

    HandleWeaponKeys = function(self)
        local state = Shared.GetRunState()
        if Input.GetKeyDown("1") then
            state.weapon = "sword"
        elseif state.bow and Input.GetKeyDown("2") then
            state.weapon = "bow"
        end
    end,

    ReadMovement = function(self)
        local x = 0.0
        local y = 0.0
        if Input.GetKey("left") or Input.GetKey("a") then
            x = x - 1.0
        end
        if Input.GetKey("right") or Input.GetKey("d") then
            x = x + 1.0
        end
        if Input.GetKey("up") or Input.GetKey("w") then
            y = y - 1.0
        end
        if Input.GetKey("down") or Input.GetKey("s") then
            y = y + 1.0
        end
        local nx, ny = Shared.Normalize(x, y)
        return nx, ny
    end,

    Move = function(self, move_x, move_y, shield_active)
        if self.attack_timer > 0 then
            return
        end
        if move_x == 0.0 and move_y == 0.0 then
            return
        end

        local speed = self.move_speed
        if shield_active then
            speed = speed * self.shield_move_factor
        end

        self.transform.x = Shared.Clamp(
                               self.transform.x + move_x * speed, self.min_x,
                               self.max_x)
        self.transform.y = Shared.Clamp(
                               self.transform.y + move_y * speed, self.min_y,
                               self.max_y)
    end,

    BeginAttack = function(self, aim_x, aim_y)
        local state = Shared.GetRunState()
        self.attacked_targets = {}

        if state.weapon == "bow" and state.bow then
            if math.abs(aim_x) > 0.0001 or math.abs(aim_y) > 0.0001 then
                self.pending_shot_x = aim_x
                self.pending_shot_y = aim_y
            else
                self.pending_shot_x = self.facing_x
                self.pending_shot_y = self.facing_y
            end
            self.attack_kind = "bow"
            self.attack_timer = self.bow_attack_duration
            Shared.PlaySfx(13, {"arrow-swish"}, 82)
            return
        end

        self.attack_kind = "sword"
        self.attack_timer = self.sword_attack_duration
        Shared.PlaySfx(12, {"playSwingSword_clean", "playSwingSword"},
                                 84)
    end,

    UpdateAttack = function(self)
        if self.attack_timer <= 0 then
            return
        end

        if self.attack_kind == "bow" then
            local elapsed = self.bow_attack_duration - self.attack_timer
            if elapsed == self.bow_release_frame then
                self:FireArrow()
            end
            self:RenderAttackSprite("Player/Bow and Arrow", 7, elapsed,
                                    self.bow_attack_duration)
        else
            local elapsed = self.sword_attack_duration - self.attack_timer
            if elapsed == self.sword_hit_frame then
                self:HitEnemiesWithSword()
            end
            self:RenderAttackSprite("Player/Sword", 10, elapsed,
                                    self.sword_attack_duration)
        end

        self.attack_timer = self.attack_timer - 1
        if self.attack_timer <= 0 then
            self.attack_kind = ""
        end
    end,

    HitEnemiesWithSword = function(self)
        local enemies = Actor.FindAll("enemy")
        for index = 1, #enemies do
            local enemy_actor = enemies[index]
            local enemy_uid = enemy_actor:GetUID()
            if self.attacked_targets[enemy_uid] == nil then
                local enemy = enemy_actor:GetComponent("Enemy")
                if enemy ~= nil and enemy:IsAlive() then
                    local dx = enemy:GetPositionX() - self.transform.x
                    local dy = enemy:GetPositionY() - self.transform.y
                    local _, _, distance = Shared.Normalize(dx, dy)
                    local dot = dx * self.facing_x + dy * self.facing_y
                    if distance <= self.sword_range and dot > -0.06 then
                        -- Use facing direction as knockback so sword hits buy space.
                        enemy:TakeDamage(self.sword_damage, self.facing_x * 0.16,
                                         self.facing_y * 0.16)
                        self.attacked_targets[enemy_uid] = true
                    end
                end
            end
        end
    end,

    FireArrow = function(self)
        local actor = Actor.Instantiate("ArrowProjectile")
        if actor == nil then
            return
        end

        local shot_x = self.pending_shot_x or self.facing_x
        local shot_y = self.pending_shot_y or self.facing_y
        if math.abs(shot_x) <= 0.0001 and math.abs(shot_y) <= 0.0001 then
            shot_x = self.facing_x
            shot_y = self.facing_y
        end

        local x = self.transform.x + shot_x * 0.28
        local y = self.transform.y + shot_y * 0.28
        local projectile = actor:GetComponent("Projectile")
        if projectile ~= nil then
            projectile:Launch(x, y, shot_x, shot_y, self.bow_damage,
                              self.bow_projectile_speed)
        end
    end,

    IsShieldActive = function(self)
        local state = Shared.GetRunState()
        if not state.shield or not self.alive or self.attack_timer > 0 then
            return false
        end
        return Input.GetMouseButton(3) or Input.GetKey("shift") or
                   Input.GetKey("left shift") or Input.GetKey("right shift")
    end,

    TakeDamage = function(self, amount, source_x, source_y)
        if not self.alive or self.invulnerable_timer > 0 then
            return
        end

        if self:IsShieldActive() then
            self.invulnerable_timer = 14
            Shared.PlaySfx(14, {"shieldblock"}, 88)
            return
        end

        self.health = math.max(0, self.health - (amount or 1))
        self.invulnerable_timer = self.invulnerable_frames
        self.hurt_timer = self.hurt_frames
        self.attack_timer = 0
        self.attack_kind = ""
        Shared.PlaySfx(15, {"playerDamaged"}, 82)

        if self.transform ~= nil then
            self.transform.x = Shared.Clamp(
                                   self.transform.x + (source_x or 0.0) * 0.08,
                                   self.min_x, self.max_x)
            self.transform.y = Shared.Clamp(
                                   self.transform.y + (source_y or 0.0) * 0.08,
                                   self.min_y, self.max_y)
        end

        self:UpdateHealthUI()
        if self.health <= 0 then
            self.alive = false
            self.death_timer = self.death_frames
            local director = Shared.GetDirector()
            if director ~= nil then
                director:NotifyPlayerDefeated()
            end
        end
    end,

    GrantBow = function(self)
        local state = Shared.GetRunState()
        state.bow = true
        state.weapon = "bow"
    end,

    GrantShield = function(self)
        local state = Shared.GetRunState()
        state.shield = true
    end,

    RenderAttackSprite = function(self, image, columns, elapsed, duration)
        local row, flip = Shared.StandardDirectionRow(self.facing_x,
                                                                self.facing_y)
        local column = math.min(columns,
                                1 + math.floor(elapsed * columns / duration))
        self.sprite.sprite = image
        self.sprite:SetSpriteCell(row, column)
        self.sprite.scale_x = self.sprite_scale * flip
        self.sprite.scale_y = self.sprite_scale
        self.sprite.sorting_order =
            Shared.SortOrder(self.transform.y, 80)
        self.sprite.auto_sorting_order = false
    end,

    RenderLocomotionSprite = function(self, move_x, move_y)
        local row, flip = Shared.StandardDirectionRow(self.facing_x,
                                                                self.facing_y)
        if math.abs(move_x) > 0.0 or math.abs(move_y) > 0.0 then
            self.sprite.sprite = "Player/Run"
            self.sprite:SetSpriteCell(row, Shared.AnimationFrame(8, 5))
        else
            self.sprite.sprite = "Player/Idle"
            self.sprite:SetSpriteCell(row,
                                      Shared.AnimationFrame(4, 10))
        end
        self.sprite.scale_x = self.sprite_scale * flip
        self.sprite.scale_y = self.sprite_scale
        self.sprite.sorting_order =
            Shared.SortOrder(self.transform.y, 80)
        self.sprite.auto_sorting_order = false
    end,

    RenderDamageSprite = function(self)
        local row, flip = Shared.StandardDirectionRow(self.facing_x,
                                                                self.facing_y)
        local elapsed = self.hurt_frames - self.hurt_timer
        local column = math.min(4, 1 + math.floor(elapsed * 4 /
                                                     self.hurt_frames))
        self.sprite.sprite = "Player/Damage"
        self.sprite:SetSpriteCell(row, column)
        self.sprite.scale_x = self.sprite_scale * flip
        self.sprite.scale_y = self.sprite_scale
        self.sprite.sorting_order =
            Shared.SortOrder(self.transform.y, 80)
        self.sprite.auto_sorting_order = false
    end,

    ApplySpriteTint = function(self, shield_active)
        if shield_active then
            self.sprite.r = 210
            self.sprite.g = 235
            self.sprite.b = 255
        elseif self.invulnerable_timer > 0 and
               (self.invulnerable_timer % 6) < 3 then
            self.sprite.r = 255
            self.sprite.g = 180
            self.sprite.b = 180
        else
            self.sprite.r = 255
            self.sprite.g = 255
            self.sprite.b = 255
        end
        self.sprite.a = 255
    end,

    UpdateDeath = function(self)
        self.death_timer = math.max(0, self.death_timer - 1)
        local row, flip = Shared.StandardDirectionRow(self.facing_x,
                                                                self.facing_y)
        self.sprite.sprite = "Player/Dead"
        self.sprite.scale_x = self.sprite_scale * flip
        self.sprite.scale_y = self.sprite_scale
        self.sprite:SetSpriteCell(row, math.min(4,
            1 + math.floor((self.death_frames - self.death_timer) / 12)))
        self.sprite.sorting_order =
            Shared.SortOrder(self.transform.y, 80)
        self.sprite.auto_sorting_order = false
        self.sprite.r = 255
        self.sprite.g = 255
        self.sprite.b = 255
        self.sprite.a = 255
    end,

    UpdateHealthUI = function(self)
        -- Keep player health anchored to the screen's top-left corner.
        local ui_x, ui_y = Shared.ScreenToWorld(104, 42)
        Shared.UpdateHealthVisuals(self.health_visuals, ui_x, ui_y,
                                             self.health, self.max_health, 0.98,
                                             3200)
    end,

    UpdateShieldVisual = function(self, shield_active)
        if self.shield_visual == nil or self.transform == nil then
            return
        end

        local alpha = shield_active and 230 or 0
        -- Shield is a body-centered guard, matching the projectile parry logic.
        local x = self.transform.x
        local y = self.transform.y
        Shared.SetVisual(self.shield_visual, "shield", 1, 1, x, y,
                                   1.22, 1.22,
                                   Shared.SortOrder(y, 120), alpha)
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
        return self.hit_radius
    end,

    GetShieldRadius = function(self)
        return self.shield_radius
    end
}
