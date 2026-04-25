Shared = Shared or {}

-- Runtime decoration pool. Environment.lua samples from this list each time a
-- scene starts, so stages feel alive without hand-placing every crop actor.
Shared.crop_cells = {
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

Shared.stages = {
    main = {
        title = "Stage 1: Slime Garden",
        attacker_name = "Slimes",
        objective = "Protect the altar. Clear the slime wave, then pick up the bow.",
        music = {"main", "Village Under Siege"},
        reward = "bow",
        next_scene = "goblin_raid",
        -- 1.5x larger combat map; decoration count scales up, but not by full area.
        min_x = -4.68,
        max_x = 4.68,
        min_y = -2.58,
        max_y = 2.58,
        decoration_count = 72,
        altar_x = 0.0,
        altar_y = 0.02,
        player_x = 0.0,
        player_y = 1.54,
        waves = {
            {frame = 30, spawns = {
                {kind = "slime", x = -4.32, y = -2.02},
                {kind = "slime", x = 4.34, y = 1.92}
            }},
            {frame = 220, spawns = {
                {kind = "slime", x = -4.40, y = 0.08},
                {kind = "slime", x = 4.38, y = -1.82},
                {kind = "slime", x = 4.18, y = 1.48}
            }},
            {frame = 430, spawns = {
                {kind = "slime", x = -4.24, y = 2.08},
                {kind = "slime", x = -4.20, y = -1.94},
                {kind = "slime", x = 4.36, y = 0.04},
                {kind = "slime", x = 4.30, y = -2.18}
            }}
        }
    },
    goblin_raid = {
        title = "Stage 2: Goblin Raid",
        attacker_name = "Goblins",
        objective = "Goblins switch targets between you and the altar. Survive, then claim the shield.",
        music = {"invasion", "Village Under Siege"},
        reward = "shield",
        next_scene = "champion_duel",
        -- Goblin stages can be busier, but still leave combat space readable.
        min_x = -4.68,
        max_x = 4.68,
        min_y = -2.58,
        max_y = 2.58,
        decoration_count = 80,
        altar_x = 0.18,
        altar_y = -0.05,
        player_x = -0.55,
        player_y = 1.48,
        waves = {
            {frame = 30, spawns = {
                {kind = "spear", x = -4.34, y = -2.00},
                {kind = "spear", x = 4.22, y = 1.36}
            }},
            {frame = 220, spawns = {
                {kind = "spear", x = -4.42, y = 0.42},
                {kind = "spear", x = 4.40, y = -1.88},
                {kind = "spear", x = 4.18, y = 2.04}
            }},
            {frame = 430, spawns = {
                {kind = "spear", x = -4.30, y = -2.10},
                {kind = "spear", x = -4.10, y = 1.86},
                {kind = "spear", x = 4.36, y = 0.08},
                {kind = "spear", x = 4.16, y = -2.08}
            }}
        }
    },
    champion_duel = {
        title = "Stage 3: Sword Saint Duel",
        attacker_name = "Goblin Sword Saint",
        objective = "Use the shield to reflect sword waves and end the invasion.",
        music = {"GoblinSwordSaint"},
        next_scene = "victory",
        -- Boss arenas should stay readable so projectile parries are fair.
        min_x = -4.68,
        max_x = 4.68,
        min_y = -2.58,
        max_y = 2.58,
        decoration_count = 56,
        altar_x = 0.0,
        altar_y = 0.02,
        player_x = 0.0,
        player_y = 1.76,
        waves = {
            {frame = 45, spawns = {
                {kind = "champion", x = 0.0, y = -1.96}
            }}
        }
    },
    victory = {
        title = "The Village Breathes Again",
        objective = "For now, the rim holds.",
        music = {"victory"},
        black_screen = true,
        show_player = true,
        altar_x = 0.52,
        altar_y = 0.02,
        player_x = -0.52,
        player_y = 0.08,
        victory = true
    }
}

Shared.enemy_defs = {
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
    },
    champion = {
        walk = "Enemies/GoblinSwordSaint/Walk",
        idle = "Enemies/GoblinSwordSaint/Idle",
        attack = "Enemies/GoblinSwordSaint/Attack",
        max_hp = 18,
        damage = 2,
        speed = 0.020,
        scale = 1.65,
        attack_range = 0.48,
        -- Roughly 1.2x faster than the first boss draft.
        attack_cooldown = 35,
        hit_radius = 0.30,
        target = "player",
        walk_columns = 6,
        idle_columns = 2,
        attack_columns = 9,
        direction = "standard",
        is_boss = true,
        special = "sword_wave",
        special_damage = 2,
        special_speed = 0.046,
        special_min_range = 0.62,
        special_attack_timer = 20,
        special_initial_cooldown_min = 54,
        special_initial_cooldown_max = 88,
        special_cooldown_min = 70,
        special_cooldown_max = 120
    }
}

function Shared.GetRunState()
    RunState = RunState or {
        bow = false,
        shield = false,
        weapon = "sword",
        current_music = ""
    }
    return RunState
end

function Shared.ResetRunState()
    local state = Shared.GetRunState()
    state.bow = false
    state.shield = false
    state.weapon = "sword"
    state.current_music = ""
end

function Shared.SeedRandomOnce()
    if RandomSeeded then
        return
    end
    local seed = 1337
    if os ~= nil and os.time ~= nil then
        seed = os.time() % 2147483647
    end
    math.randomseed(seed)
    RandomSeeded = true
end

function Shared.Clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

function Shared.GetWindowSize()
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

function Shared.GetStageBounds(scene_name)
    local stage = Shared.stages[scene_name or Scene.GetCurrent()]
    if stage == nil then
        return -3.12, 3.12, -1.72, 1.72
    end
    return stage.min_x or -3.12, stage.max_x or 3.12,
           stage.min_y or -1.72, stage.max_y or 1.72
end

function Shared.GetViewportHalfExtents()
    local zoom = math.max(0.01, Camera.GetZoom())
    local window_width, window_height = Shared.GetWindowSize()
    return window_width / (200.0 * zoom), window_height / (200.0 * zoom)
end

function Shared.ClampCameraToStage(x, y, scene_name)
    local min_x, max_x, min_y, max_y = Shared.GetStageBounds(scene_name)
    local half_width, half_height = Shared.GetViewportHalfExtents()
    local camera_x = x
    local camera_y = y

    if (max_x - min_x) <= half_width * 2.0 then
        camera_x = (min_x + max_x) * 0.5
    else
        camera_x = Shared.Clamp(camera_x, min_x + half_width,
                                max_x - half_width)
    end

    if (max_y - min_y) <= half_height * 2.0 then
        camera_y = (min_y + max_y) * 0.5
    else
        camera_y = Shared.Clamp(camera_y, min_y + half_height,
                                max_y - half_height)
    end

    Camera.SetPosition(camera_x, camera_y)
end

function Shared.WorldToScreen(x, y)
    local zoom = math.max(0.01, Camera.GetZoom())
    local window_width, window_height = Shared.GetWindowSize()
    -- Text.Draw is screen-space, so enemy labels need the same camera mapping
    -- that player mouse aiming uses in reverse.
    return (x - Camera.GetPositionX()) * 100.0 * zoom + window_width * 0.5,
           (y - Camera.GetPositionY()) * 100.0 * zoom + window_height * 0.5
end

function Shared.ScreenToWorld(x, y)
    local zoom = math.max(0.01, Camera.GetZoom())
    local window_width, window_height = Shared.GetWindowSize()
    return Camera.GetPositionX() + (x - window_width * 0.5) /
               (100.0 * zoom),
           Camera.GetPositionY() + (y - window_height * 0.5) /
               (100.0 * zoom)
end

function Shared.AnimationFrame(frame_count, frame_stride)
    return 1 + (math.floor(Application.GetFrame() / frame_stride) %
                   frame_count)
end

function Shared.Distance(ax, ay, bx, by)
    local dx = bx - ax
    local dy = by - ay
    return math.sqrt(dx * dx + dy * dy)
end

function Shared.Normalize(x, y)
    local length = math.sqrt(x * x + y * y)
    if length <= 0.00001 then
        return 0.0, 0.0, 0.0
    end
    return x / length, y / length, length
end

function Shared.RandomRange(minimum, maximum)
    return minimum + math.random() * (maximum - minimum)
end

function Shared.SortOrder(y, offset)
    return 500 + math.floor((y or 0.0) * 100.0) + (offset or 0)
end

function Shared.ResolveClip(candidates)
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

function Shared.PlayMusicOnce(candidates)
    local clip = Shared.ResolveClip(candidates)
    local state = Shared.GetRunState()
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

function Shared.PlaySfx(channel, candidates, volume)
    local clip = Shared.ResolveClip(candidates)
    if clip == "" then
        return
    end
    Audio.SetVolume(channel, volume or 88)
    Audio.Play(channel, clip, false)
end

function Shared.StandardDirectionRow(dx, dy)
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

function Shared.SlimeDirectionRow(dx, dy)
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

function Shared.DirectionRow(kind, dx, dy)
    if kind == "slime" then
        return Shared.SlimeDirectionRow(dx, dy)
    end
    return Shared.StandardDirectionRow(dx, dy)
end

function Shared.HeartColumn(health_units, slot_index)
    local remaining = health_units - ((slot_index - 1) * 2)
    if remaining >= 2 then
        return 1
    end
    if remaining == 1 then
        return 2
    end
    return 3
end

function Shared.SpawnVisual()
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

function Shared.DestroyVisual(visual)
    if visual ~= nil and visual.actor ~= nil then
        Actor.Destroy(visual.actor)
    end
end

function Shared.SetVisual(visual, image, row, column, x, y,
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

function Shared.CreateHealthVisuals(slot_count)
    local visuals = {
        background = Shared.SpawnVisual(),
        hearts = {}
    }
    for index = 1, slot_count do
        visuals.hearts[index] = Shared.SpawnVisual()
    end
    return visuals
end

function Shared.DestroyHealthVisuals(visuals)
    if visuals == nil then
        return
    end
    Shared.DestroyVisual(visuals.background)
    for index = 1, #visuals.hearts do
        Shared.DestroyVisual(visuals.hearts[index])
    end
end

function Shared.UpdateHealthVisuals(visuals, x, y, health_units,
                                              max_health_units, scale, order)
    if visuals == nil then
        return
    end
    local slots = math.max(1, math.ceil(max_health_units / 2))
    local visual_scale = scale or 1.0
    local spacing = 0.21 * visual_scale
    local start_x = x - ((slots - 1) * spacing) * 0.5
    -- The border sprite is one frame, so stretch it to the active heart count.
    local background_width =
        math.max(1.16 * visual_scale,
                 ((slots - 1) * spacing) + (0.68 * visual_scale)) * 1.5
    Shared.SetVisual(visuals.background, "UI/0.2.png", 2, 5,
                               x, y, background_width,
                               0.86 * visual_scale, order or 1500, 235)
    for index = 1, #visuals.hearts do
        local alpha = 255
        if index > slots then
            alpha = 0
        end
        Shared.SetVisual(
            visuals.hearts[index], "UI/Bars", 1,
            Shared.HeartColumn(health_units, index),
            start_x + (index - 1) * spacing, y,
            0.98 * visual_scale, 0.98 * visual_scale,
            (order or 1500) + index, alpha)
    end
end

function Shared.GetDirector()
    local actor = Actor.Find("director")
    if actor == nil then
        return nil
    end
    return actor:GetComponent("Director")
end

function Shared.GetPlayer()
    local actor = Actor.Find("player")
    if actor == nil then
        return nil
    end
    return actor:GetComponent("Player")
end

function Shared.GetAltar()
    local actor = Actor.Find("altar")
    if actor == nil then
        return nil
    end
    return actor:GetComponent("Altar")
end
