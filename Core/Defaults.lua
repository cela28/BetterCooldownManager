local _, BCDM = ...

BCDM.Defaults = {
    global = {
        UseGlobalProfile = false,
        GlobalProfile = "Default",
    },
    profile = {
        General = {
            Font = "Friz Quadrata TT",
            FontFlag = "OUTLINE",
            IconZoom = 0.1,
            CooldownText = {
                FontSize = 15,
                Colour = {1, 1, 1},
                Anchors = {"CENTER", "CENTER", 0, 0}
            },
        },
        Essential = {
            IconSize = {42, 42},
            Anchors = {"CENTER", "CENTER", 0, -275.1},
            Count = {
                FontSize = 15,
                Colour = {1, 1, 1},
                Anchors = {"BOTTOMRIGHT", "BOTTOMRIGHT", 0, 3}
            },
        },
        Utility = {
            IconSize = {36, 36},
            Anchors = {"TOP", "EssentialCooldownViewer", "BOTTOM", 0, -3},
            Count = {
                FontSize = 12,
                Colour = {1, 1, 1},
                Anchors = {"BOTTOMRIGHT", "BOTTOMRIGHT", 0, 3}
            },
        },
        Buffs = {
            IconSize = {36, 36},
            Anchors = {"BOTTOM", "BCDM_PowerBar", "TOP", 0, 2},
            Count = {
                FontSize = 12,
                Colour = {1, 1, 1},
                Anchors = {"BOTTOMRIGHT", "BOTTOMRIGHT", 0, 3}
            },
        },
        PowerBar = {
            Height = 13,
            FGTexture = "Blizzard Raid Bar",
            BGTexture = "Solid",
            FGColour = {0/255, 122/255, 204/255, 1},
            BGColour = {20/255, 20/255, 20/255, 1},
            Anchors = {"BOTTOM", "EssentialCooldownViewer", "TOP", 0, 2},
            ColourByPower = true,
            Text = {
                FontSize = 18,
                Colour = {1, 1, 1},
                Anchors = {"BOTTOM", "BOTTOM", 0, 3},
                ColourByPower = false
            },
            CustomColours = {
                Power = {
                    [0] = {0, 0, 1},            -- Mana
                    [1] = {1, 0, 0},            -- Rage
                    [2] = {1, 0.5, 0.25},       -- Focus
                    [3] = {1, 1, 0},            -- Energy
                    [6] = {0, 0.82, 1},         -- Runic Power
                    [8] = {0.75, 0.52, 0.9},     -- Lunar Power
                    [11] = {0, 0.5, 1},         -- Maelstrom
                    [13] = {0.4, 0, 0.8},       -- Insanity
                    [17] = {0.79, 0.26, 0.99},  -- Fury
                    [18] = {1, 0.61, 0}         -- Pain
                },
            }
        }
    }
}