VillageRimShared = VillageRimShared or {}

VillageRimShared.crop_cells = {
    {2, 1}, {2, 2}, {2, 3},
    {4, 1}, {4, 2}, {4, 3}, {4, 4},
    {6, 3}, {6, 4},
    {8, 1}, {8, 3},
    {10, 2}, {10, 3},
    {16, 3},
    {20, 3},
    {22, 3}, {22, 4},
    {24, 11},
    {26, 3}
}

VillageRimShared.stages = {
    main = {
        title = "Stage 1: Slime Garden",
        objective = "Protect the altar. Clear the slime wave, then pick up the bow.",
        music = {"main", "Village Under Siege"},
        reward = "bow",
        next_scene = "goblin_raid",
        decoration_count = 66,
        altar_x = 0.0,
        altar_y = 0.02,
        player_x = 0.0,
        player_y = 0.88,
        waves = {
            {frame = 30, spawns = {
                {kind = "slime", x = -2.85, y = -1.20},
                {kind = "slime", x = 2.86, y = 1.12}
            }},
            {frame = 220, spawns = {
                {kind = "slime", x = -2.92, y = 0.05},
                {kind = "slime", x = 2.94, y = -0.92},
                {kind = "slime", x = 2.82, y = 0.86}
            }},
            {frame = 430, spawns = {
                {kind = "slime", x = -2.86, y = 1.15},
                {kind = "slime", x = -2.76, y = -1.06},
                {kind = "slime", x = 2.93, y = 0.04},
                {kind = "slime", x = 2.92, y = -1.26}
            }}
        }
    },
    goblin_raid = {
        title = "Stage 2: Goblin Raid",
        objective = "Goblins switch targets between you and the altar. Survive, then claim the shield.",
        music = {"invasion", "Village Under Siege"},
        reward = "shield",
        next_scene = "victory",
        decoration_count = 74,
        altar_x = 0.18,
        altar_y = -0.05,
        player_x = -0.55,
        player_y = 0.86,
        waves = {
            {frame = 30, spawns = {
                {kind = "spear", x = -2.90, y = -1.12},
                {kind = "spear", x = 2.78, y = 0.78}
            }},
            {frame = 220, spawns = {
                {kind = "spear", x = -2.92, y = 0.24},
                {kind = "spear", x = 2.92, y = -1.05},
                {kind = "spear", x = 2.82, y = 1.12}
            }},
            {frame = 430, spawns = {
                {kind = "spear", x = -2.88, y = -1.20},
                {kind = "spear", x = -2.78, y = 1.04},
                {kind = "spear", x = 2.94, y = 0.06},
                {kind = "spear", x = 2.74, y = -1.18}
            }}
        }
    },
    victory = {
        title = "The Village Breathes Again",
        objective = "Chapter 3 will open later. For now, the rim holds.",
        music = {"victory"},
        decoration_count = 86,
        altar_x = 0.0,
        altar_y = 0.08,
        victory = true
    }
}

VillageRimShared.enemy_defs = {
    slime = {
        walk = "Enemies/Slime/Walk",
        idle = "Enemies/Slime/Idle",
        attack = "Enemies/Slime/Attack",
        max_hp = 4,
        damage = 1,
        speed = 0.013,
        scale = 1.85,
        attack_range = 0.34,
        attack_cooldown = 58,
        hit_radius = 0.24,
        target = "altar",
        columns = 4,
        direction = "slime"
    },
    spear = {
        walk = "Enemies/Spear Goblin/Walk",
        idle = "Enemies/Spear Goblin/Idle",
        attack = "Enemies/Spear Goblin/Spear",
        max_hp = 6,
        damage = 1,
        speed = 0.017,
        scale = 1.75,
        attack_range = 0.42,
        attack_cooldown = 54,
        hit_radius = 0.25,
        target = "random",
        columns = 6,
        direction = "standard"
    }
}

function VillageRimShared.GetRunState()
    VillageRimJrState = VillageRimJrState or {
        bow = false,
        shield = false,
        weapon = "sword",
        current_music = ""
    }
    return VillageRimJrState
end

function VillageRimShared.ResetRunState()
    local state = VillageRimShared.GetRunState()
    state.bow = false
    state.shield = false
    state.weapon = "sword"
    state.current_music = ""
end

function VillageRimShared.SeedRandomOnce()
    if VillageRimJrRandomSeeded then
        return
    end
    local seed = 1337
    if os ~= nil and os.time ~= nil then
        seed = os.time() % 2147483647
    end
    math.randomseed(seed)
    VillageRimJrRandomSeeded = true
end

function VillageRimShared.Clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

function VillageRimShared.GetWindowSize()
    local window_width = 640
    local window_height = 360
    if Application ~= nil and Application.GetWindowWidth ~= nil then
        window_width = math.max(1, Application.GetWindowWidth())
    end
    if Application ~= nil and Application.GetWindowHeight ~= nil then
        window_height = math.max(1, Application.GetWindowHeight())
    end
    return window_width, window_height
end

function VillageRimShared.GetStageBounds(scene_name)
    return -3.12, 3.12, -1.72, 1.72
end

function VillageRimShared.AnimationFrame(frame_count, frame_stride)
    return 1 + (math.floor(Application.GetFrame() / frame_stride) %
                   frame_count)
end

function VillageRimShared.Distance(ax, ay, bx, by)
    local dx = bx - ax
    local dy = by - ay
    return math.sqrt(dx * dx + dy * dy)
end

function VillageRimShared.Normalize(x, y)
    local length = math.sqrt(x * x + y * y)
    if length <= 0.00001 then
        return 0.0, 0.0, 0.0
    end
    return x / length, y / length, length
end

function VillageRimShared.RandomRange(minimum, maximum)
    return minimum + math.random() * (maximum - minimum)
end

function VillageRimShared.SortOrder(y, offset)
    return 500 + math.floor((y or 0.0) * 100.0) + (offset or 0)
end

function VillageRimShared.ResolveClip(candidates)
    if candidates == nil then
        return ""
    end
    for index = 1, #candidates do
        local name = candidates[index]
        if name ~= nil and name ~= "" and Audio.HasClip(name) then
            return name
        end
    end
    return ""
end

function VillageRimShared.PlayMusicOnce(candidates)
    local clip = VillageRimShared.ResolveClip(candidates)
    local state = VillageRimShared.GetRunState()
    if clip == "" then
        Music.Halt()
        state.current_music = ""
        return
    end
    if state.current_music == clip and Music.IsPlaying() then
        return
    end
    Music.SetVolume(82)
    Music.Play(clip, true)
    state.current_music = clip
end

function VillageRimShared.PlaySfx(channel, candidates, volume)
    local clip = VillageRimShared.ResolveClip(candidates)
    if clip == "" then
        return
    end
    Audio.SetVolume(channel, volume or 88)
    Audio.Play(channel, clip, false)
end

function VillageRimShared.StandardDirectionRow(dx, dy)
    if math.abs(dx) > math.abs(dy) then
        if dx < 0.0 then
            return 3, -1.0
        end
        return 3, 1.0
    end
    if dy < 0.0 then
        return 2, 1.0
    end
    return 1, 1.0
end

function VillageRimShared.SlimeDirectionRow(dx, dy)
    if math.abs(dx) > math.abs(dy) then
        if dx < 0.0 then
            return 1, -1.0
        end
        return 1, 1.0
    end
    if dy < 0.0 then
        return 3, 1.0
    end
    return 2, 1.0
end

function VillageRimShared.DirectionRow(kind, dx, dy)
    if kind == "slime" then
        return VillageRimShared.SlimeDirectionRow(dx, dy)
    end
    return VillageRimShared.StandardDirectionRow(dx, dy)
end

function VillageRimShared.HeartColumn(health_units, slot_index)
    local remaining = health_units - ((slot_index - 1) * 2)
    if remaining >= 2 then
        return 1
    end
    if remaining == 1 then
        return 2
    end
    return 3
end

function VillageRimShared.SpawnVisual()
    local actor = Actor.Instantiate("VisualActor")
    if actor == nil then
        return nil
    end
    local transform = actor:GetComponent("Transform")
    local sprite = actor:GetComponent("SpriteRenderer")
    if transform == nil or sprite == nil then
        return nil
    end
    return {
        actor = actor,
        transform = transform,
        sprite = sprite
    }
end

function VillageRimShared.DestroyVisual(visual)
    if visual ~= nil and visual.actor ~= nil then
        Actor.Destroy(visual.actor)
    end
end

function VillageRimShared.SetVisual(visual, image, row, column, x, y,
                                    scale_x, scale_y, order, alpha)
    if visual == nil then
        return
    end
    visual.transform.x = x
    visual.transform.y = y
    visual.sprite.sprite = image
    visual.sprite:SetSpriteCell(row or 1, column or 1)
    visual.sprite.scale_x = scale_x or 1.0
    visual.sprite.scale_y = scale_y or math.abs(scale_x or 1.0)
    visual.sprite.sorting_order = order or 0
    visual.sprite.auto_sorting_order = false
    visual.sprite.r = 255
    visual.sprite.g = 255
    visual.sprite.b = 255
    visual.sprite.a = alpha or 255
end

function VillageRimShared.CreateHealthVisuals(slot_count)
    local visuals = {
        background = VillageRimShared.SpawnVisual(),
        hearts = {}
    }
    for index = 1, slot_count do
        visuals.hearts[index] = VillageRimShared.SpawnVisual()
    end
    return visuals
end

function VillageRimShared.DestroyHealthVisuals(visuals)
    if visuals == nil then
        return
    end
    VillageRimShared.DestroyVisual(visuals.background)
    for index = 1, #visuals.hearts do
        VillageRimShared.DestroyVisual(visuals.hearts[index])
    end
end

function VillageRimShared.UpdateHealthVisuals(visuals, x, y, health_units,
                                              max_health_units, scale, order)
    if visuals == nil then
        return
    end
    local slots = math.max(1, math.ceil(max_health_units / 2))
    local spacing = 0.18 * (scale or 1.0)
    local start_x = x - ((slots - 1) * spacing) * 0.5
    VillageRimShared.SetVisual(visuals.background, "UI/0.2.png", 2, 5,
                               x, y, 0.66 * (scale or 1.0),
                               0.42 * (scale or 1.0), order or 1500, 230)
    for index = 1, #visuals.hearts do
        local alpha = 255
        if index > slots then
            alpha = 0
        end
        VillageRimShared.SetVisual(
            visuals.hearts[index], "UI/Bars", 1,
            VillageRimShared.HeartColumn(health_units, index),
            start_x + (index - 1) * spacing, y,
            0.74 * (scale or 1.0), 0.74 * (scale or 1.0),
            (order or 1500) + index, alpha)
    end
end

function VillageRimShared.GetDirector()
    local actor = Actor.Find("director")
    if actor == nil then
        return nil
    end
    return actor:GetComponent("VillageRimDirector")
end

function VillageRimShared.GetPlayer()
    local actor = Actor.Find("player")
    if actor == nil then
        return nil
    end
    return actor:GetComponent("VillageRimPlayer")
end

function VillageRimShared.GetAltar()
    local actor = Actor.Find("altar")
    if actor == nil then
        return nil
    end
    return actor:GetComponent("VillageRimAltar")
end
