VillageRimPlayer = {
    max_health = 10,
    health = 10,
    speed = 0.035,
    stage_name = "",
    facing_x = 1.0,
    facing_y = 0.0,
    attack_timer = 0,
    attack_cooldown = 0,
    invulnerable_timer = 0,
    alive = true,

    OnStart = function(self)
        self.transform = self.actor:GetComponent("Transform")
        self.sprite = self.actor:GetComponent("SpriteRenderer")
        self.health = self.max_health
        self.alive = true
        self.health_visuals =
            VillageRimShared.CreateHealthVisuals(math.ceil(self.max_health / 2))
        self.shield_visual = VillageRimShared.SpawnVisual()

        local state = VillageRimShared.GetRunState()
        if self.stage_name == "goblin_raid" then
            state.bow = true
            state.weapon = "bow"
        end
        self:UpdateSprite(0.0, 0.0)
    end,

    OnUpdate = function(self)
        if self.transform == nil then
            return
        end
        if not self.alive then
            self:UpdateHealthUI()
            return
        end

        if self.attack_cooldown > 0 then
            self.attack_cooldown = self.attack_cooldown - 1
        end
        if self.attack_timer > 0 then
            self.attack_timer = self.attack_timer - 1
        end
        if self.invulnerable_timer > 0 then
            self.invulnerable_timer = self.invulnerable_timer - 1
        end

        self:HandleWeaponKeys()
        local move_x, move_y = self:ReadMovement()
        self:Move(move_x, move_y)

        if Input.GetKeyDown("space") or Input.GetMouseButtonDown(0) then
            self:Attack()
        end

        self:UpdateSprite(move_x, move_y)
        self:UpdateHealthUI()
        self:UpdateShieldVisual()
    end,

    OnDestroy = function(self)
        VillageRimShared.DestroyHealthVisuals(self.health_visuals)
        VillageRimShared.DestroyVisual(self.shield_visual)
    end,

    SetStage = function(self, stage_name)
        self.stage_name = stage_name or ""
    end,

    HandleWeaponKeys = function(self)
        local state = VillageRimShared.GetRunState()
        if Input.GetKeyDown("1") then
            state.weapon = "sword"
        end
        if state.bow and Input.GetKeyDown("2") then
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

        local nx, ny, length = VillageRimShared.Normalize(x, y)
        if length > 0.0 then
            self.facing_x = nx
            self.facing_y = ny
        end
        return nx, ny
    end,

    Move = function(self, move_x, move_y)
        self.transform.x = VillageRimShared.Clamp(
                               self.transform.x + move_x * self.speed, -3.05,
                               3.05)
        self.transform.y = VillageRimShared.Clamp(
                               self.transform.y + move_y * self.speed, -1.55,
                               1.55)
    end,

    Attack = function(self)
        if self.attack_cooldown > 0 then
            return
        end

        local state = VillageRimShared.GetRunState()
        if state.weapon == "bow" and state.bow then
            self:ShootArrow()
            self.attack_cooldown = 22
            self.attack_timer = 14
            return
        end

        self:SwordSlash()
        self.attack_cooldown = 26
        self.attack_timer = 16
    end,

    SwordSlash = function(self)
        VillageRimShared.PlaySfx(
            12, {"playSwingSword_clean", "playSwingSword"}, 84)

        local enemies = Actor.FindAll("enemy")
        for index = 1, #enemies do
            local enemy = enemies[index]:GetComponent("VillageRimEnemy")
            if enemy ~= nil and enemy:IsAlive() then
                local dx = enemy:GetPositionX() - self.transform.x
                local dy = enemy:GetPositionY() - self.transform.y
                local _, _, distance = VillageRimShared.Normalize(dx, dy)
                local dot = dx * self.facing_x + dy * self.facing_y
                if distance <= 0.62 and dot > -0.08 then
                    enemy:TakeDamage(2, self.facing_x * 0.08,
                                     self.facing_y * 0.08)
                end
            end
        end
    end,

    ShootArrow = function(self)
        VillageRimShared.PlaySfx(13, {"arrow-swish"}, 82)
        local actor = Actor.Instantiate("ArrowProjectile")
        if actor == nil then
            return
        end

        local x = self.transform.x + self.facing_x * 0.28
        local y = self.transform.y + self.facing_y * 0.28
        local projectile = actor:GetComponent("VillageRimProjectile")
        if projectile ~= nil then
            projectile:Launch(x, y, self.facing_x, self.facing_y, 2, 0.066)
        end
    end,

    IsShieldActive = function(self)
        local state = VillageRimShared.GetRunState()
        if not state.shield then
            return false
        end
        return Input.GetMouseButton(1) or Input.GetKey("shift") or
                   Input.GetKey("left shift") or Input.GetKey("right shift")
    end,

    TakeDamage = function(self, amount)
        if not self.alive or self.invulnerable_timer > 0 then
            return
        end

        if self:IsShieldActive() then
            self.invulnerable_timer = 18
            VillageRimShared.PlaySfx(14, {"shieldblock"}, 88)
            return
        end

        self.health = math.max(0, self.health - (amount or 1))
        self.invulnerable_timer = 38
        VillageRimShared.PlaySfx(15, {"playerDamaged"}, 82)
        self:UpdateHealthUI()
        if self.health <= 0 then
            self.alive = false
            local director = VillageRimShared.GetDirector()
            if director ~= nil then
                director:NotifyPlayerDefeated()
            end
        end
    end,

    GrantBow = function(self)
        local state = VillageRimShared.GetRunState()
        state.bow = true
        state.weapon = "bow"
    end,

    GrantShield = function(self)
        local state = VillageRimShared.GetRunState()
        state.shield = true
    end,

    UpdateSprite = function(self, move_x, move_y)
        if self.sprite == nil then
            return
        end

        local state = VillageRimShared.GetRunState()
        local row, flip = VillageRimShared.StandardDirectionRow(self.facing_x,
                                                                self.facing_y)
        local image = "Player/Idle"
        local columns = 4
        if self.attack_timer > 0 and state.weapon == "bow" and state.bow then
            image = "Player/Bow and Arrow"
            columns = 7
        elseif self.attack_timer > 0 then
            image = "Player/Sword"
            columns = 10
        elseif math.abs(move_x) > 0.0 or math.abs(move_y) > 0.0 then
            image = "Player/Run"
            columns = 8
        end

        local column = (math.floor(Application.GetFrame() / 6) % columns) + 1
        self.sprite.sprite = image
        self.sprite:SetSpriteCell(row, column)
        self.sprite.scale_x = 1.72 * flip
        self.sprite.scale_y = 1.72
        self.sprite.sorting_order =
            VillageRimShared.SortOrder(self.transform.y, 80)
        self.sprite.auto_sorting_order = false
    end,

    UpdateHealthUI = function(self)
        VillageRimShared.UpdateHealthVisuals(self.health_visuals, -2.70, -1.54,
                                             self.health, self.max_health, 0.82,
                                             3200)
    end,

    UpdateShieldVisual = function(self)
        if self.shield_visual == nil or self.transform == nil then
            return
        end

        local alpha = 0
        if self:IsShieldActive() then
            alpha = 230
        end

        local x = self.transform.x + self.facing_x * 0.25
        local y = self.transform.y + self.facing_y * 0.25
        VillageRimShared.SetVisual(self.shield_visual, "shield", 1, 1, x, y,
                                   1.15, 1.15,
                                   VillageRimShared.SortOrder(y, 120), alpha)
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
