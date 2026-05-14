GLOBAL.setfenv(1, GLOBAL)

return {
    MASTERFARMER = {
        COMMON = {
            ENABLED = "Enabled",
            DISABLED = "Disabled",
            STATUS_FORMAT = "%s: %s",
        },
        COMPONENTS = {
            AUTOFARM = { NAME = "Auto Farm" },
            AUTOPLANT = { NAME = "Auto Plant" },
        },
        AUTOFARM = {
            FARMING = "Auto Farming...",
        },
        AUTOPLANT = {
            PLANTING = "Auto Planting...",
            COMBO_LIST = "Combo List",
            FILTER = "Filter",
            FILTERED = "Filtered",
            FILTERED_PREFIX = "Filtered:",
            CLEAR_FILTER = "Clear filter",
            CROP_FILTER = "Crop Filter",
            CONFIRM = "Confirm",
            CONTINUE = "Continue",
            CANCEL = "Cancel",
            PRIORITY = "Priority:",
            NOT_IN_SEASON = "Not in Season",
            UNKNOWN = "Unknown",
            PLANT_COMBO = "Plant this combo?",
            SEEDS_INSUFFICIENT = "Not enough seeds for this combo",
            CLEAR_FARM_SOIL = "Clear at least two farm plots first",
            TILES_2 = "2 Tiles",
            TILES_4 = "4 Tiles",
        },
    },
}
