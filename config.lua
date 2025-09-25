Config = {}
Config.ChangeToCrash = 80 -- Bigger value the more change you will flipover and crash.
Config.MaxAngleForChangeToCrash = 15 -- 15 is default.
Config.MinDriveSpeedChangeToCrash = 20.0 -- min speed before you can flipover.
Config.ReduseVehicleHealthWhenCrashed = 100.0 -- default 100 this will be -100.0 from the curent health.
Config.WaitAfterCrashBeforePlayerCanDrive = 2000 -- default 2 secs. (2000 = 2 secs)

-- this will ignore wheel types.
Config.IngnoreWheelTypes = {
    [0] = false,  -- SPORT 
    [1] = false, -- MUSCLE 
    [2] = true,  -- LOWRIDER 
    [3] = false, -- SUV 
    [4] = false, -- OFFROAD 
    [5] = true,  -- TUNER 
    [6] = true,  -- BIKE 
    [7] = true,  -- HI-END 
    [8] = false, -- SUPERMOD1 // Benny's Original
    [9] = true,  -- SUPERMOD2 // Benny's Bespoke
    [10] = true, -- SUPERMOD3 // Open Wheel
    [11] = true, -- SUPERMOD4 // Street
    [12] = true, -- SUPERMOD5 // Track
}