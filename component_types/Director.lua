Director = {
    stage_name = "",
    frame = 0,
    spawn_index = 1,
    failed = false,
    fail_timer = -1,
    stage_clear = false,
    reward_spawned = false,
    reward_collected = false,
    transition_timer = -1,
    message = "",

    OnStart = function(self)
        Shared.SeedRandomOnce()

        if self.stage_name == nil or self.stage_name == "" then
            self.stage_name = Scene.GetCurrent()
        end
        self.stage = Shared.stages[self.stage_name] or
                         Shared.stages.main

        self.frame = 0
        self.spawn_index = 1
        self.failed = false
        self.fail_timer = -1
        self.stage_clear = false
        self.reward_spawned = false
        self.reward_collected = false
        self.transition_timer = -1
        self.message = self.stage.objective or ""

        if self.stage_name == "main" then
            Shared.ResetRunState()
        end

        local run_state = Shared.GetRunState()
        if self.stage_name == "goblin_raid" then
            run_state.bow = true
            run_state.weapon = "bow"
        elseif self.stage_name == "champion_duel" then
            run_state.bow = true
            run_state.shield = true
            run_state.weapon = "sword"
        elseif self.stage_name == "victory" then
            run_state.bow = true
            run_state.shield = true
        end

        Camera.SetPosition(0.0, 0.0)
        -- Keep world sprites comfortably readable in the larger 960x540 window.
        Camera.SetZoom(self.stage.camera_zoom or 1.2)
        Shared.PlayMusicOnce(self.stage.music)

        self:SpawnCoreActors()
        if self.stage.victory then
            self.message = "The village is safe for now. Press R to restart."
        end
    end,

    OnUpdate = function(self)
        self.frame = self.frame + 1

        if Input.GetKeyDown("r") then
            Scene.Load(self.stage.victory and "main" or self.stage_name)
            return
        end

        if self.stage.victory then
            return
        end

        if self.failed then
            self.fail_timer = self.fail_timer - 1
            if self.fail_timer <= 0 then
                Scene.Load(self.stage_name)
            end
            return
        end

        self:RunWaves()

        if self.transition_timer > 0 then
            self.transition_timer = self.transition_timer - 1
            if self.transition_timer <= 0 and self.stage.next_scene ~= nil then
                Scene.Load(self.stage.next_scene)
            end
            return
        end

        if self:AllWavesFinished() and self:LiveEnemyCount() == 0 then
            if not self.stage_clear then
                self.stage_clear = true
                if self.stage.reward ~= nil and self.stage.reward ~= "" then
                    self.message = "Wave cleared. Claim the reward."
                else
                    self.message = "Victory. Moving on..."
                    self.transition_timer = 95
                end
            end
            if not self.reward_spawned then
                self:SpawnReward()
            end
        end
    end,

    SpawnCoreActors = function(self)
        local altar = Actor.Instantiate("Altar")
        if altar ~= nil then
            local transform = altar:GetComponent("Transform")
            if transform ~= nil then
                transform.x = self.stage.altar_x or 0.0
                transform.y = self.stage.altar_y or 0.0
            end
            local altar_component = altar:GetComponent("Altar")
            if altar_component ~= nil then
                altar_component:SetStage(self.stage_name)
            end
        end

        if not self.stage.victory or self.stage.show_player then
            local player = Actor.Instantiate("Player")
            if player ~= nil then
                local transform = player:GetComponent("Transform")
                if transform ~= nil then
                    transform.x = self.stage.player_x or 0.0
                    transform.y = self.stage.player_y or 0.9
                end
                local player_component = player:GetComponent("Player")
                if player_component ~= nil then
                    player_component:SetStage(self.stage_name)
                    player_component:UpdateCamera()
                end
            end
        end
    end,

    RunWaves = function(self)
        local waves = self.stage.waves or {}
        while self.spawn_index <= #waves do
            local wave = waves[self.spawn_index]
            if wave == nil or self.frame < (wave.frame or 0) then
                break
            end
            self:SpawnWave(wave)
            self.spawn_index = self.spawn_index + 1
        end
    end,

    SpawnWave = function(self, wave)
        local spawns = wave.spawns or {}
        for index = 1, #spawns do
            local spawn = spawns[index]
            self:SpawnEnemy(spawn.kind, spawn.x, spawn.y)
        end
        self.message = "Enemies are attacking. Defend the altar."
    end,

    SpawnEnemy = function(self, kind, x, y)
        local template = "SlimeEnemy"
        if kind == "spear" then
            template = "SpearGoblin"
        elseif kind == "champion" then
            template = "GoblinSwordSaint"
        end

        local actor = Actor.Instantiate(template)
        if actor == nil then
            return
        end

        local transform = actor:GetComponent("Transform")
        if transform ~= nil then
            transform.x = x or 0.0
            transform.y = y or 0.0
        end

        local enemy = actor:GetComponent("Enemy")
        if enemy ~= nil then
            enemy:SetKind(kind or "slime")
        end
    end,

    SpawnReward = function(self)
        if self.stage.reward == nil or self.stage.reward == "" then
            return
        end

        self.reward_spawned = true
        local actor = Actor.Instantiate("Pickup")
        if actor == nil then
            return
        end

        local x = (self.stage.altar_x or 0.0) + 0.72
        local y = (self.stage.altar_y or 0.0) + 0.22
        local transform = actor:GetComponent("Transform")
        if transform ~= nil then
            transform.x = x
            transform.y = y
        end

        local pickup = actor:GetComponent("Pickup")
        if pickup ~= nil then
            pickup:SetKind(self.stage.reward)
            pickup:Place(x, y)
        end
    end,

    AllWavesFinished = function(self)
        local waves = self.stage.waves or {}
        return self.spawn_index > #waves
    end,

    LiveEnemyCount = function(self)
        local actors = Actor.FindAll("enemy")
        local count = 0
        for index = 1, #actors do
            local enemy = actors[index]:GetComponent("Enemy")
            if enemy ~= nil and enemy:IsAlive() then
                count = count + 1
            end
        end
        return count
    end,

    NotifyPickupCollected = function(self, kind)
        self.reward_collected = true
        if kind == "bow" then
            self.message = "Bow acquired. Moving to the goblin raid..."
        elseif kind == "shield" then
            self.message = "Shield acquired. Face the Sword Saint..."
        else
            self.message = "Reward acquired."
        end
        self.transition_timer = 95
    end,

    NotifyAltarDestroyed = function(self)
        if self.failed then
            return
        end
        self.failed = true
        self.fail_timer = 140
        self.message = "The altar fell. Restarting..."
    end,

    NotifyPlayerDefeated = function(self)
        if self.failed then
            return
        end
        self.failed = true
        self.fail_timer = 140
        self.message = "You fell. Restarting..."
    end,

    GetStage = function(self)
        return self.stage
    end,

    GetStageName = function(self)
        return self.stage_name
    end,

    GetFrame = function(self)
        return self.frame
    end,

    GetMessage = function(self)
        return self.message or ""
    end
}
