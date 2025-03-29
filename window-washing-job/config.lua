Config = {}

-- Job Settings
Config.MinWashTime = 5000 -- Minimum time to wash a window (ms)
Config.MaxWashTime = 10000 -- Maximum time to wash a window (ms)

-- Buildings with windows to clean
Config.Buildings = {
    ["downtown_1"] = {
        name = "downtown_1",
        coords = vector4(-66.42, -802.18, 44.23, 160.0),
        payment = 2500, -- Base payment for completing all windows
        windows = {
            {coords = vector4(-70.82, -800.69, 44.23, 160.0), cleaned = false},
            {coords = vector4(-75.25, -798.86, 44.23, 160.0), cleaned = false},
            {coords = vector4(-79.38, -797.19, 44.23, 160.0), cleaned = false},
            {coords = vector4(-83.82, -795.42, 44.23, 160.0), cleaned = false},
            {coords = vector4(-88.12, -793.72, 44.23, 160.0), cleaned = false},
            {coords = vector4(-70.82, -800.69, 47.95, 160.0), cleaned = false},
            {coords = vector4(-75.25, -798.86, 47.95, 160.0), cleaned = false},
            {coords = vector4(-79.38, -797.19, 47.95, 160.0), cleaned = false},
            {coords = vector4(-83.82, -795.42, 47.95, 160.0), cleaned = false},
            {coords = vector4(-88.12, -793.72, 47.95, 160.0), cleaned = false},
        }
    },
    ["downtown_2"] = {
        name = "downtown_2",
        coords = vector4(291.42, -986.68, 29.39, 0.0),
        payment = 3000,
        windows = {
            {coords = vector4(295.82, -986.69, 29.39, 0.0), cleaned = false},
            {coords = vector4(300.25, -986.86, 29.39, 0.0), cleaned = false},
            {coords = vector4(304.38, -986.19, 29.39, 0.0), cleaned = false},
            {coords = vector4(308.82, -986.42, 29.39, 0.0), cleaned = false},
            {coords = vector4(313.12, -986.72, 29.39, 0.0), cleaned = false},
            {coords = vector4(295.82, -986.69, 33.15, 0.0), cleaned = false},
            {coords = vector4(300.25, -986.86, 33.15, 0.0), cleaned = false},
            {coords = vector4(304.38, -986.19, 33.15, 0.0), cleaned = false},
            {coords = vector4(308.82, -986.42, 33.15, 0.0), cleaned = false},
            {coords = vector4(313.12, -986.72, 33.15, 0.0), cleaned = false},
            {coords = vector4(295.82, -986.69, 36.85, 0.0), cleaned = false},
            {coords = vector4(300.25, -986.86, 36.85, 0.0), cleaned = false},
            {coords = vector4(304.38, -986.19, 36.85, 0.0), cleaned = false},
            {coords = vector4(308.82, -986.42, 36.85, 0.0), cleaned = false},
            {coords = vector4(313.12, -986.72, 36.85, 0.0), cleaned = false},
        }
    },
    ["vinewood"] = {
        name = "vinewood",
        coords = vector4(-358.56, 221.43, 86.68, 0.0),
        payment = 4000,
        windows = {
            {coords = vector4(-354.16, 221.43, 86.68, 0.0), cleaned = false},
            {coords = vector4(-349.73, 221.43, 86.68, 0.0), cleaned = false},
            {coords = vector4(-345.60, 221.43, 86.68, 0.0), cleaned = false},
            {coords = vector4(-341.16, 221.43, 86.68, 0.0), cleaned = false},
            {coords = vector4(-336.86, 221.43, 86.68, 0.0), cleaned = false},
            {coords = vector4(-354.16, 221.43, 90.44, 0.0), cleaned = false},
            {coords = vector4(-349.73, 221.43, 90.44, 0.0), cleaned = false},
            {coords = vector4(-345.60, 221.43, 90.44, 0.0), cleaned = false},
            {coords = vector4(-341.16, 221.43, 90.44, 0.0), cleaned = false},
            {coords = vector4(-336.86, 221.43, 90.44, 0.0), cleaned = false},
            {coords = vector4(-354.16, 221.43, 94.14, 0.0), cleaned = false},
            {coords = vector4(-349.73, 221.43, 94.14, 0.0), cleaned = false},
            {coords = vector4(-345.60, 221.43, 94.14, 0.0), cleaned = false},
            {coords = vector4(-341.16, 221.43, 94.14, 0.0), cleaned = false},
            {coords = vector4(-336.86, 221.43, 94.14, 0.0), cleaned = false},
            {coords = vector4(-354.16, 221.43, 97.84, 0.0), cleaned = false},
            {coords = vector4(-349.73, 221.43, 97.84, 0.0), cleaned = false},
            {coords = vector4(-345.60, 221.43, 97.84, 0.0), cleaned = false},
            {coords = vector4(-341.16, 221.43, 97.84, 0.0), cleaned = false},
            {coords = vector4(-336.86, 221.43, 97.84, 0.0), cleaned = false},
        }
    }
}

-- Add job vehicle and ped configurations
Config.JobVehicle = "speedo"  -- Vehicle model for window washing job

-- Ped locations for job coordinators
Config.PedLocations = {
    {
        coords = vector4(-71.42, -812.18, 44.23, 340.0),  -- Near downtown_1 building
        model = "s_m_y_construct_01",
        vehicleSpawn = vector4(-75.42, -818.18, 44.23, 340.0)
    },
    {
        coords = vector4(285.42, -986.68, 29.39, 180.0),  -- Near downtown_2 building
        model = "s_m_y_construct_01",
        vehicleSpawn = vector4(280.42, -990.68, 29.39, 180.0)
    },
    {
        coords = vector4(-364.56, 221.43, 86.68, 180.0),  -- Near vinewood building
        model = "s_m_y_construct_01",
        vehicleSpawn = vector4(-370.56, 225.43, 86.68, 180.0)
    }
}

