HUD = {
    OnUpdate = function(self)
        local director = Shared.GetDirector()
        if director == nil then
            Text.Draw("VillageRimJr", 18, 16, "NotoSans-Regular", 24, 22, 28,
                      20, 255)
            return
        end

        local window_width, window_height = Shared.GetWindowSize()
        local stage = director:GetStage()
        local title = "VillageRimJr"
        if stage ~= nil then
            if stage.victory then
                Text.Draw(stage.title or "The Village Breathes Again",
                          window_width * 0.5 - 185, window_height * 0.40,
                          "NotoSans-Regular", 26, 240, 232, 205, 255)
                Text.Draw(stage.objective or "For now...",
                          window_width * 0.5 - 88, window_height * 0.47,
                          "NotoSans-Regular", 16, 210, 202, 180, 255)
                return
            else
                local attacker_name = stage.attacker_name or "Enemies"
                title = attacker_name .. " attacking... protect altar!!"
            end
        end

        -- Keep combat HUD sparse: one status line, one control line.
        Text.Draw(title, 18, 6, "NotoSans-Regular", 23, 20, 30, 18, 255)

        local controls = "1 sword | left click to attack"
        local state = Shared.GetRunState()
        if state.bow then
            controls = controls .. " | 2 bow"
        end
        if state.shield then
            controls = controls .. " | right hold to use shield"
        end
        Text.Draw(controls, 18, window_height - 26, "NotoSans-Regular", 14,
                  28, 38, 24, 255)
    end
}
