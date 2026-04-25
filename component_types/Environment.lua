Environment = {
    OnStart = function(self)
        Shared.SeedRandomOnce()
        self.decorations = {}

        local director = Shared.GetDirector()
        self.stage = nil
        if director ~= nil then
            self.stage = director:GetStage()
        end
        if self.stage == nil then
            self.stage = Shared.stages[Scene.GetCurrent()] or
                             Shared.stages.main
        end

        if self.stage.black_screen then
            self:SpawnVictoryBackdrop()
            return
        end

        self:SpawnCrops()
    end,

    OnDestroy = function(self)
        if self.decorations == nil then
            return
        end
        for index = 1, #self.decorations do
            Shared.DestroyVisual(self.decorations[index])
        end
    end,

    SpawnCrops = function(self)
        local count = self.stage.decoration_count or 64
        local altar_x = self.stage.altar_x or 0.0
        local altar_y = self.stage.altar_y or 0.0
        local player_x = self.stage.player_x or 0.0
        local player_y = self.stage.player_y or 0.9

        for index = 1, count do
            local x = 0.0
            local y = 0.0
            for attempt = 1, 12 do
                x = Shared.RandomRange(-3.0, 3.0)
                y = Shared.RandomRange(-1.55, 1.55)
                local far_from_altar =
                    Shared.Distance(x, y, altar_x, altar_y) > 0.58
                local far_from_player =
                    Shared.Distance(x, y, player_x, player_y) > 0.44
                if far_from_altar and far_from_player then
                    break
                end
            end

            local cell = Shared.crop_cells[
                             math.random(1, #Shared.crop_cells)]
            local visual = Shared.SpawnVisual()
            Shared.SetVisual(
                visual, "Summer Crops", cell[1], cell[2], x, y, 2.0, 2.0,
                Shared.SortOrder(y, -60), 230)
            self.decorations[#self.decorations + 1] = visual
        end
    end,

    SpawnVictoryBackdrop = function(self)
        local visual = Shared.SpawnVisual()
        -- A tiny opaque texture scaled up is more reliable than tinting UI frames,
        -- because many UI sprites have transparent centers or decorative edges.
        Shared.SetVisual(visual, "victory_black", 1, 1, 0.0, 0.0,
                         45.0, 45.0, -5000, 255)
        self.decorations[#self.decorations + 1] = visual
    end
}
