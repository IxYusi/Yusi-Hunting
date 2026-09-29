lib.locale()

Config = {}
Config.Debug = false
Config.Target = nil               -- only supporting ox_target and qb-target | nil to disable targeting
Config.SpawnDelay = 20             -- seconds [how much time it should take between spawning animals]
Config.DeleteEntityRadius = 400.0 -- will delete animal if your 400 meters away from them
Config.HarvestMaxDistance = 0     -- max distance (meters) between player and animal when harvesting | 0 = unlimited
Config.HarvestLockTime = 60       -- seconds an animal is kept alive while someone skins it
Config.ExtraItemChance = 0.3      -- [0.0 - 1.0] chance of an extra item when skinning
Config.SpawnGraceTime = 15        -- seconds to wait for a new animal to stream in before removing it
Config.CleanupInterval = 5        -- seconds between animal cleanup checks
Config.MarkerDistance = 30.0      -- distance the animal marker is drawn from
Config.TrackedMarkerDistance = 400.0 -- same, while the animal is being tracked

Config.TrackerItem = "animal_tracker"
Config.TrackingDuration = 60      -- seconds
Config.DelayBetweenTracks = 120   -- seconds
Config.TrackingFailureChance = 20 -- [1 - 100]

Config.AimBlock = {
    enable = true,
    global = true,     -- false if you want to have aimblock only in hunting zones
    weaponsToBlock = { -- weapons that are disabled to shoot at players
        `WEAPON_HEAVYSNIPER_MK2`,
        -- `WEAPON_HEAVYSNIPER`,
    }
}

-- Weapons in this list are completely blocked from firing anywhere on the map
-- EXCEPT while the player is standing inside one of Config.HuntingZones.
Config.ZoneOnlyWeapons = {
    `WEAPON_HEAVYSNIPER_MK2`,
}

-- ox_lib skill check used when skinning/harvesting an animal.
-- Same mini game as tj_burgershot: two 'medium' rounds, press E.
-- Add more entries to `difficulty` to make it harder, remove entries to make it easier.
-- Set `keys = nil` to use ox_lib's default mouse-click style skillcheck instead.
Config.SkinningSkillCheck = {
    difficulty = { 'medium', 'medium' },
    keys = { 'e' },
}

Config.BaitItem = "huntingbait"
Config.BaitAttractionDistance = 150.0 -- in 200 radius it will atract an animal
Config.BaitTimeLimit = 2              -- minutes

Config.HuntingXPPerHarvest = 3  -- awarded each time you successfully skin an animal
Config.HuntingXPPerMission = 10 -- awarded on completing a bounty mission

Config.ImagesPath = "nui://FRRP-hunting/_icons/"

-- _____                           __  _
-- / ____|                         / _| (_)
-- | |      __ _  _ __ ___   _ __  | |_  _  _ __  ___
-- | |     / _` || '_ ` _ \ | '_ \ |  _|| || '__|/ _ \
-- | |____| (_| || | | | | || |_) || |  | || |  |  __/
-- \_____|\__,_||_| |_| |_|| .__/ |_|  |_||_|   \___|
--                         | |
--                         |_|

Config.Campfire = {
    enable = true,
    campfireItem = "campfire",
    items = {
        {
            label = "Cooked meat",
            give = "cooked_meat",
            cookTime = 5, -- seconds
            require = {
                {
                    label = "Raw Meat",
                    quantity = 1,
                    item = "raw_meat",
                },
            }
        },
}
}

-- _    _                _    _                  ______
-- | |  | |              | |  (_)                |___  /
-- | |__| | _   _  _ __  | |_  _  _ __    __ _      / /  ___   _ __    ___  ___
-- |  __  || | | || '_ \ | __|| || '_ \  / _` |    / /  / _ \ | '_ \  / _ \/ __|
-- | |  | || |_| || | | || |_ | || | | || (_| |   / /__| (_) || | | ||  __/\__ \
-- |_|  |_| \__,_||_| |_| \__||_||_| |_| \__, |  /_____|\___/ |_| |_| \___||___/
--                                        __/ |
--                                       |___/

Config.HuntingZones = {
    ["high drop rate zone lower deer spawn"] = {
        coords = vector3(-1364.09, 4525.69, 50.46),
        radius = 350.0,
        maxSpawns = 5,                                                  -- max animals spawned at one time
        allowedWeapons = { "WEAPON_HEAVYSNIPER_MK2", "WEAPON_DAGGER" }, -- nil if you want to allow every weapon
        zone_radius = {
            enable = true,
            color = 1,
            opacity = 128,
        },
        blip = {
            enable = true,
            name = 'Hunting Zone',
            type = 141,
            scale = 1.0,
            color = 0,
        },
        animals = {
            {
                model = "a_c_deer",
                chance = 90, -- chance of spawning
                harvestTime = 5,
                harvestWeapons = { "WEAPON_DAGGER" },
                blip = {
                    enable = false, -- animals no longer show up on the map
                    name = 'Deer',
                    type = 119,
                    scale = 0.8,
                    color = 1,
                },
                marker = {
                    enable = false, -- in-world glow stays so you can still spot it once you're close
                    color = { r = 196, g = 136, b = 77, a = 150 }
                },
                items = {
                    skins = {
                        {
                            item = "skin_deer_ruined",
                            chance = 0,
                            maxQuantity = 1,
                        },
                        {
                            item = "skin_deer_low",
                            chance = 0,
                            maxQuantity = 1,
                        },
                        {
                            item = "skin_deer_medium",
                            chance = 50,
                            maxQuantity = 1,
                        },
                        {
                            item = "skin_deer_good",
                            chance = 25,
                            maxQuantity = 1,
                        },
                        {
                            item = "skin_deer_perfect",
                            chance = 25,
                            maxQuantity = 1,
                        },
                    },
                    meat = {
                        {
                            item = "raw_meat",
                            chance = 100,
                            maxQuantity = 5,
                        },
                    },
                    extra = { -- rare items
                        {
                            item = "deer_horn",
                            chance = 30,
                            maxQuantity = 1,
                        },
                    }

                }
            },
        }
    },
    ["mid drop rate with mid deer spawn rate "] = {
        coords = vector3(-427.39, 4926.31, 174.26),
        radius = 300.0,
        maxSpawns = 7,                                                  -- max animals spawned at one time
        allowedWeapons = { "WEAPON_HEAVYSNIPER_MK2", "WEAPON_DAGGER" }, -- nil if you want to allow every weapon
        zone_radius = {
            enable = true,
            color = 1,
            opacity = 128,
        },
        blip = {
            enable = true,
            name = 'Hunting Zone',
            type = 141,
            scale = 1.0,
            color = 0,
        },
        animals = {
            {
                model = "a_c_deer",
                chance = 100, -- chance of spawning
                harvestTime = 5,
                harvestWeapons = { "WEAPON_DAGGER" },
                blip = {
                    enable = false, -- animals no longer show up on the map
                    name = 'Deer',
                    type = 119,
                    scale = 0.8,
                    color = 1,
                },
                marker = {
                    enable = false, -- in-world glow stays so you can still spot it once you're close
                    color = { r = 196, g = 136, b = 77, a = 150 }
                },
                items = {
                    skins = {
                        {
                            item = "skin_deer_ruined",
                            chance = 50,
                            maxQuantity = 1,
                        },
                        {
                            item = "skin_deer_low",
                            chance = 50,
                            maxQuantity = 1,
                        },
                        {
                            item = "skin_deer_medium",
                            chance = 50,
                            maxQuantity = 1,
                        },
                        {
                            item = "skin_deer_good",
                            chance = 25,
                            maxQuantity = 1,
                        },
                        {
                            item = "skin_deer_perfect",
                            chance = 15,
                            maxQuantity = 1,
                        },
                    },
                    meat = {
                        {
                            item = "raw_meat",
                            chance = 100,
                            maxQuantity = 10,
                        },
                    },
                    extra = { -- rare items
                        {
                            item = "deer_horn",
                            chance = 25,
                            maxQuantity = 1,
                        },
                    }

                }
            },
        }
    },
    ["smaller zone with mid tier drop rate "] = {
        coords = vector3(1193.15, 4558.45, 97.5),
        radius = 300.0,
        maxSpawns = 5,                                                  -- max animals spawned at one time
        allowedWeapons = { "WEAPON_HEAVYSNIPER_MK2", "WEAPON_DAGGER" }, -- nil if you want to allow every weapon
        zone_radius = {
            enable = true,
            color = 1,
            opacity = 128,
        },
        blip = {
            enable = true,
            name = 'Hunting Zone',
            type = 141,
            scale = 1.0,
            color = 0,
        },
        animals = {
            {
                model = "a_c_deer",
                chance = 90, -- chance of spawning
                harvestTime = 5,
                harvestWeapons = { "WEAPON_DAGGER" },
                blip = {
                    enable = false, -- animals no longer show up on the map
                    name = 'Deer',
                    type = 119,
                    scale = 0.8,
                    color = 1,
                },
                marker = {
                    enable = false, -- in-world glow stays so you can still spot it once you're close
                    color = { r = 196, g = 136, b = 77, a = 150 }
                },
                items = {
                    skins = {
                        {
                            item = "skin_deer_ruined",
                            chance = 0,
                            maxQuantity = 1,
                        },
                        {
                            item = "skin_deer_low",
                            chance = 50,
                            maxQuantity = 1,
                        },
                        {
                            item = "skin_deer_medium",
                            chance = 50,
                            maxQuantity = 1,
                        },
                        {
                            item = "skin_deer_good",
                            chance = 50,
                            maxQuantity = 1,
                        },
                        {
                            item = "skin_deer_perfect",
                            chance = 15,
                            maxQuantity = 1,
                        },
                    },
                    meat = {
                        {
                            item = "raw_meat",
                            chance = 100,
                            maxQuantity = 10,
                        },
                    },
                    extra = { -- rare items
                        {
                            item = "deer_horn",
                            chance = 50,
                            maxQuantity = 1,
                        },
                    }

                }
            },
        }
    },
    ["flat zone with good deer spawn rate but super low drop rate for farming xp "] = {
        coords = vector3(-511.15, 3005.25, 35.25),
        radius = 250.0,
        maxSpawns = 5,                                                  -- max animals spawned at one time
        allowedWeapons = { "WEAPON_HEAVYSNIPER_MK2", "WEAPON_DAGGER" }, -- nil if you want to allow every weapon
        zone_radius = {
            enable = true,
            color = 1,
            opacity = 128,
        },
        blip = {
            enable = true,
            name = 'Hunting Zone',
            type = 141,
            scale = 1.0,
            color = 0,
        },
        animals = {
            {
                model = "a_c_deer",
                chance = 100, -- chance of spawning
                harvestTime = 7,
                harvestWeapons = { "WEAPON_DAGGER" },
                blip = {
                    enable = false, -- animals no longer show up on the map
                    name = 'Deer',
                    type = 119,
                    scale = 0.8,
                    color = 1,
                },
                marker = {
                    enable = false, -- in-world glow stays so you can still spot it once you're close
                    color = { r = 196, g = 136, b = 77, a = 150 }
                },
                items = {
                    skins = {
                        {
                            item = "skin_deer_ruined",
                            chance = 70,
                            maxQuantity = 1,
                        },
                        {
                            item = "skin_deer_low",
                            chance = 10,
                            maxQuantity = 1,
                        },
                        {
                            item = "skin_deer_medium",
                            chance = 10,
                            maxQuantity = 1,
                        },
                        {
                            item = "skin_deer_good",
                            chance = 10,
                            maxQuantity = 1,
                        },
                        {
                            item = "skin_deer_perfect",
                            chance = 10,
                            maxQuantity = 1,
                        },
                    },
                    meat = {
                        {
                            item = "raw_meat",
                            chance = 100,
                            maxQuantity = 5,
                        },
                    },
                    extra = { -- rare items
                        {
                            item = "deer_horn",
                            chance = 10,
                            maxQuantity = 1,
                        },
                    }

                }
            },
        }
    },
}
-- _____  _
-- / ____|| |
-- | (___  | |__    ___   _ __   ___
-- \___ \ | '_ \  / _ \ | '_ \ / __|
-- ____) || | | || (_) || |_) |\__ \
-- |_____/ |_| |_| \___/ | .__/ |___/
--                      | |
--                      |_|

Config.Shops = {
    ["HuntGear Store"] = {
        coords = vector4(967.6, -2121.12, 30.48, 86.84),
        ped = {
            enable = Config.Target and true or true, -- false the last bool to dont use ped
            model = "s_m_m_ammucountry"
        },
        blip = {
            enable = true,
            type = 59,
            scale = 0.7,
            color = 5,
        },
        useDrawText = true,
        items = {
            sell = {
                {
                    item = "skin_deer_ruined",
                    price = 300,
                    label = "Tattered Deer Pelt"

                },
                {
                    item = "skin_deer_low",
                    price = 750,
                    label = "Worn Deer Pelt"

                },
                {
                    item = "skin_deer_medium",
                    price = 1250,
                    label = "Supple Deer Pelt"

                },
                {
                    item = "skin_deer_good",
                    price = 2500,
                    label = "Prime Deer Pelt"

                },
                {
                    item = "skin_deer_perfect",
                    price = 5000,
                    label = "Flawless Deer Pelt"

                },
            },
            buy = {
                {
                    item = "huntingbait",
                    label = "hunting Bait",
                    price = 250,
                },
                {
                    item = "campfire",
                    label = "Campfire",
                    price = 750,
                },
                {
                    item = "animal_tracker",
                    label = "Animal Tracker",
                    price = 10050,
                },
            }

        }
    },
}

-- __  __  _            _
-- |  \/  |(_)          (_)
-- | \  / | _  ___  ___  _   ___   _ __   ___
-- | |\/| || |/ __|/ __|| | / _ \ | '_ \ / __|
-- | |  | || |\__ \\__ \| || (_) || | | |\__ \
-- |_|  |_||_||___/|___/|_| \___/ |_| |_||___/

Config.HuntMaster = {
    coords = vector4(17.04, 3688.28, 38.68, 147.12),
    model = "cs_fabien",
    blip = {
        enable = true,
        name = 'Hunting bounties',
        type = 85,
        scale = 0.8,
        color = 5,
    },
    vehicleSpawn = vector4(10.04, 3679.52, 39.72, 115.0),
    vehicleDeposit = vector3(10.04, 3679.52, 39.72)
}

Config.Missions = {
    {
        label = "High-Quality Pelts",
        content = "Bring me 5 high-quality deer skins",
        icon = "fa-solid fa-bullseye",
        image = Config.ImagesPath .. "skin_deer_good.png",
        delay = 10, -- wait 10 minutes do another of this mission
        time = 60,  -- minutes
        type = "item",
        id = "mission_1",
        vehicle = {
            enable = false,
            model = "bodhi2",
        },
        requirements = {
            {
                item = "skin_deer_good",
                label = "Prime Deer Pelt",
                quantity = 5
            }
        },
        rewards = {
            {
                item = "money",
                quantity = 17500
            }
        }
    },
    {
        label = "Antler Collection",
        content = "Gather 5 Deer Horns for my collection",
        icon = "fa-solid fa-bullseye",
        image = Config.ImagesPath .. "deer_horn.png",
        delay = 10, -- wait 10 minutes do another of this mission
        time = 60,  -- minutes
        type = "item",
        id = "mission_2",
        vehicle = {
            enable = false,
            model = "bodhi2",
        },
        requirements = {
            {
                item = "deer_horn",
                label = "Deer Horns",
                quantity = 5
            }
        },
        rewards = {
            {
                item = "money",
                quantity = 7000
            }
        }
    },

    -- PLACEHOLDER MISSIONS — fill in label/content/requirements/rewards yourself.
    -- Copy the structure of "High-Quality Pelts" above (type = "item") if you
    -- want a delivery-style mission, or "Boar Bounty" (type = "animal") if you
    -- want a catch-and-deliver style mission.
    {
        label = "Blood for art",
        content = "Bring me 10 high-quality deer skins for random gun dye",
        icon = "fa-solid fa-bullseye",
        image = Config.ImagesPath .. "weapontint_black.png",
        delay = 10, -- wait 10 minutes do another of this mission
        time = 30,  -- minutes
        type = "item",
        id = "mission_4",
        vehicle = {
            enable = false,
            model = "bodhi2",
        },
        requirements = {
            {
                item = "skin_deer_good",
                label = "Prime Deer Pelt",
                quantity = 10
            }
        },
        rewards = {}, -- no guaranteed items, the reward is a single random dye below
        rewardPool = { -- one of these is picked at random and granted (equal odds)
            { item = "weapontint_6", quantity = 1, chance = 50 },
            { item = "weapontint_mk2_0", quantity = 1, chance = 50 },
            { item = "weapontint_mk2_5", quantity = 1, chance = 50 },
            { item = "weapontint_mk2_8", quantity = 1, chance = 50 },
            { item = "weapontint_mk2_32", quantity = 1, chance = 50 },
            { item = "weapontint_mk2_31", quantity = 1, chance = 50 },
            { item = "weapontint_mk2_30", quantity = 1, chance = 50 },
            { item = "weapontint_mk2_28", quantity = 1, chance = 50 },
            { item = "weapontint_mk2_7", quantity = 1, chance = 50 },
            { item = "weapontint_mk2_2", quantity = 1, chance = 50 },
            { item = "woodcamo_attachment", quantity = 1, chance = 50 },
        }
    },
    {
        label = "Blood for cash",
        content = "Bring me 50 kg of Raw Meat for a good pay",
        icon = "fa-solid fa-bullseye",
        image = Config.ImagesPath .. "raw_meat.png",
        delay = 10,
        time = 60,
        type = "item",
        id = "mission_5",
        vehicle = {
            enable = false,
            model = "bodhi2",
        },
        requirements = {
            {
                item = "raw_meat",
                label = "Raw Meat",
                quantity = 50
            }
        },
        rewards = {
            {
                item = "money",
                quantity = 20000
            }
        }
    },
    {
        label = "blood for gear",
        content = "Bring me 10 medium-quality deer skins for random gun gear",
        icon = "fa-solid fa-bullseye",
        image = Config.ImagesPath .. "largescope_attachment.png",
        delay = 10,
        time = 60,
        type = "item",
        id = "mission_6",
        vehicle = {
            enable = false,
            model = "bodhi2",
        },
        requirements = {
            {
                item = "skin_deer_medium",
                label = "Supple Deer Pelt",
                quantity = 10
            }
        },
        rewards = {}, -- no guaranteed items, the reward is a single random attachment below
        rewardPool = { -- one of these is picked at random and granted (equal odds)
            { item = "thermalscope_attachment", quantity = 1, chance = 50 },
            { item = "advscope_attachment", quantity = 1, chance = 50 },
            { item = "nvscope_attachment", quantity = 1, chance = 50 },
            { item = "holoscope_attachment", quantity = 1, chance = 50 },
            { item = "rifle_ammo", quantity = 5, chance = 50 },
        }
    },

}
