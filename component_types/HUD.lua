HUD = {
    OnUpdate = function(self)
        local director = Shared.GetDirector()
        if director == nil then
            Text.Draw("VillageRimJr", 18, 16, "NotoSans-Regular", 24, 22, 28,
                      20, 255)
            return
        end

        local stage = director:GetStage()
        local title = "VillageRimJr"
        local objective = ""
        if stage ~= nil then
            title = stage.title or title
            objective = stage.objective or ""
        end

        Text.Draw(title, 18, 14, "NotoSans-Regular", 23, 20, 30, 18, 255)
        Text.Draw(objective, 18, 42, "NotoSans-Regular", 15, 28, 38, 24, 255)

        local controls = "WASD move | Space/LMB attack | 1 sword"
        local state = Shared.GetRunState()
        if state.bow then
            controls = controls .. " | 2 bow"
        end
        if state.shield then
            controls = controls .. " | RMB/Shift shield"
        end
        controls = controls .. " | R restart"
        Text.Draw(controls, 18, 334, "NotoSans-Regular", 14, 28, 38, 24, 255)

        local message = director:GetMessage()
        if message ~= nil and message ~= "" then
            Text.Draw(message, 18, 66, "NotoSans-Regular", 16, 120, 62, 18,
                      255)
        end
    end
}
