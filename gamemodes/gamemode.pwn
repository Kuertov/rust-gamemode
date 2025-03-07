#pragma warning disable 239
#pragma warning disable 219

#pragma option -;+
#pragma option -(+
#pragma semicolon 1
// RUST MODE FOR SA-MP
// Main include files
#include <a_samp>
#include <a_mysql>
#include <streamer>
#include <sscanf2>
//#include <foreach>
#include <zcmd>
#include <progress2>
#include <YSI_Coding\y_timers>
#include <YSI_Data\y_iterate>

// Definitions
#define SERVER_NAME "RUST SA-MP"
#define SCRIPT_VERSION "1.0.0"

// Database connection
new MySQL:g_SQL;

// Colors
#define COLOR_RED 0xFF0000FF
#define COLOR_GREEN 0x33AA33FF
#define COLOR_BLUE 0x0000FFFF
#define COLOR_YELLOW 0xFFFF00FF
#define COLOR_ORANGE 0xFF9900FF
#define COLOR_PURPLE 0xC2A2DAFF
#define COLOR_WHITE 0xFFFFFFFF
#define COLOR_BLACK 0x000000FF
#define COLOR_GRAY 0xAFAFAFFF
#define COLOR_BROWN 0xA52A2AFF

// Dialogs
#define DIALOG_NULL 0
#define DIALOG_LOGIN 1
#define DIALOG_REGISTER 2
#define DIALOG_INVENTORY 3
#define DIALOG_CRAFTING 4
#define DIALOG_CRAFTING_CONFIRM 5
#define DIALOG_BUILDING 6
#define DIALOG_LOOT 7
#define DIALOG_PLAYER_MENU 8
#define DIALOG_ADMIN 9
#define DIALOG_ADMIN_SPAWN 10

// Player variables
enum pInfo
{
    pID,
    pName[MAX_PLAYER_NAME],
    pPassword[65],
    pAdmin,
    pKills,
    pDeaths,
    Float:pHealth,
    Float:pArmor,
    Float:pHunger,
    Float:pThirst,
    Float:pRadiation,
    pMaterials[5], // 0 - Wood, 1 - Stone, 2 - Metal, 3 - Cloth, 4 - Fuel
    pInventory[30],
    pInventoryAmount[30],
    Float:pLastX,
    Float:pLastY,
    Float:pLastZ,
    pInterior,
    pVirtualWorld,
    pSpawnPoint,
    pBuildingMode,
    pBuildingType,
    pBuildingRotation,
    pLootingID,
    PlayerBar:pProgressBar,
    PlayerBar:pHungerBar,
    PlayerBar:pThirstBar,
    PlayerBar:pRadiationBar,
    pHasMap,
    pLastLogin,
    pRegisterDate,
    pPlaytime,
    pSleeping
}
new PlayerInfo[MAX_PLAYERS][pInfo];

// Resources objects
#define MAX_RESOURCES 1000
enum resInfo
{
    resType, // 0 - Wood, 1 - Stone, 2 - Metal, 3 - Hemp, 4 - Food, 5 - Barrel
    resObject,
    Float:resX,
    Float:resY,
    Float:resZ,
    Float:resRX,
    Float:resRY,
    Float:resRZ,
    resAmount,
    resHealth,
    bool:resActive,
    resRespawnTime
}
new ResourceInfo[MAX_RESOURCES][resInfo];
new ResourceCount = 0;

// Buildings system
#define MAX_BUILDINGS 5000
enum buildInfo
{
    buildID,
    buildOwner,
    buildType, // 0 - Foundation, 1 - Wall, 2 - Doorway, 3 - Door, 4 - Floor, 5 - Ceiling, 6 - Stairs, 7 - Window, 8 - Chest
    buildObject,
    Float:buildX,
    Float:buildY,
    Float:buildZ,
    Float:buildRX,
    Float:buildRY,
    Float:buildRZ,
    buildHealth,
    buildMaxHealth,
    buildLockCode[10],
    buildLocked,
    buildItemID[20],
    buildItemAmount[20]
}
new BuildingInfo[MAX_BUILDINGS][buildInfo];
new BuildingCount = 0;

// Items definitions
#define ITEM_HATCHET 1
#define ITEM_PICKAXE 2
#define ITEM_HAMMER 3
#define ITEM_FOOD 4
#define ITEM_WATER 5
#define ITEM_MEDKIT 6
#define ITEM_BANDAGE 7
#define ITEM_PISTOL 8
#define ITEM_RIFLE 9
#define ITEM_SHOTGUN 10
#define ITEM_AMMO_PISTOL 11
#define ITEM_AMMO_RIFLE 12
#define ITEM_AMMO_SHOTGUN 13
#define ITEM_RADIATION_SUIT 14
#define ITEM_MAP 15
#define ITEM_SLEEPING_BAG 16
#define ITEM_FURNACE 17
#define ITEM_CAMPFIRE 18
#define ITEM_CODELOCK 19
#define ITEM_KEYLOCK 20
#define ITEM_KEY 21
#define ITEM_WOOD_DOOR 22
#define ITEM_METAL_DOOR 23
#define ITEM_METAL_FRAGMENTS 24
#define ITEM_CHARCOAL 25
#define ITEM_GUNPOWDER 26
#define ITEM_EXPLOSIVE 27
#define ITEM_C4 28
#define ITEM_SULFUR 29
#define ITEM_CRUDE_OIL 30
#define ITEM_WOOD 31
#define ITEM_STONE 32
#define ITEM_METAL 33
#define ITEM_CLOTH 34

// Loot containers
#define MAX_LOOT_CONTAINERS 500
enum lootInfo
{
    lootType, // 0 - Barrel, 1 - Crate, 2 - Military Crate, 3 - Elite Crate, 4 - Dead Body
    lootObject,
    Float:lootX,
    Float:lootY,
    Float:lootZ,
    lootInterior,
    lootVW,
    lootItems[10],
    lootItemsAmount[10],
    bool:lootActive,
    lootRespawnTime
}
new LootInfo[MAX_LOOT_CONTAINERS][lootInfo];
new LootCount = 0;

// Radiation zones
#define MAX_RADIATION_ZONES 10
enum radInfo
{
    Float:radX,
    Float:radY,
    Float:radZ,
    Float:radRadius,
    radLevel // 1-5, intensity of radiation
}
new RadiationZones[MAX_RADIATION_ZONES][radInfo];
new RadiationZoneCount = 0;

// Sleeping players
#define MAX_SLEEPING_PLAYERS 500
enum sleepInfo
{
    sleepName[MAX_PLAYER_NAME],
    sleepUserID,
    sleepObject,
    Float:sleepX,
    Float:sleepY,
    Float:sleepZ,
    Float:sleepRot,
    sleepInterior,
    sleepVW,
    bool:sleepActive,
    sleepInventory[30],
    sleepInventoryAmount[30],
    sleepMaterials[5],
    Float:sleepHealth,
    Float:sleepArmor,
    Float:sleepHunger,
    Float:sleepThirst
}
new SleepingPlayers[MAX_SLEEPING_PLAYERS][sleepInfo];
new SleepingCount = 0;

// Forward declarations
forward OnPlayerDataCheck(playerid);
forward OnPlayerRegister(playerid);
forward OnInventoryLoad(playerid);
forward UpdateHunger(playerid);
forward UpdateThirst(playerid);
forward CheckRadiationExposure(playerid);
forward UpdateResourceHealth(resourceid, playerid, damage);
forward RespawnResource(resourceid);
forward OnBuildingsLoad();
forward OnLootLoad();
forward OnLootRespawn(lootid);
forward HealOverTime(playerid);
forward UpdateGlobalTimers();
forward CreateSleepingBag(playerid);
forward PlayerSleepSave(playerid);
forward SaveAllBuildings();
forward RandomAirDrop();
forward UpdateAllPlayersHUDInfo();
forward Float:GetDistanceBetweenPoints3D(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2);

// Main code

forward OnTableCreated();
public OnTableCreated() { return 1; }

public OnGameModeInit()
{
    print("\n--------------------------------------");
    print("Loading Rust SA-MP Gamemode...");
    print("--------------------------------------\n");

    // Game mode info
    SetGameModeText(SERVER_NAME);

    // Connect to database
    g_SQL = mysql_connect("127.0.0.1", "root", "123123", "rustdb");
    if(mysql_errno() != 0)
    {
        print("MySQL Connection Failed!");
        return 0;
    }
    print("MySQL connection successful!");

    // Create tables if not exists
    mysql_tquery(g_SQL, "CREATE TABLE IF NOT EXISTS players (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(24), password VARCHAR(65), admin INT, kills INT, deaths INT, health FLOAT, armor FLOAT, hunger FLOAT, thirst FLOAT, radiation FLOAT, wood INT, stone INT, metal INT, cloth INT, fuel INT, lastX FLOAT, lastY FLOAT, lastZ FLOAT, interior INT, virtualworld INT, spawnpoint INT, hasmap INT, lastlogin INT, registerdate INT, playtime INT)", "OnTableCreated", "");
    mysql_tquery(g_SQL, "CREATE TABLE IF NOT EXISTS inventory (player_id INT, slot INT, item_id INT, amount INT)", "OnTableCreated", "");
    mysql_tquery(g_SQL, "CREATE TABLE IF NOT EXISTS buildings (id INT AUTO_INCREMENT PRIMARY KEY, owner INT, type INT, x FLOAT, y FLOAT, z FLOAT, rx FLOAT, ry FLOAT, rz FLOAT, health INT, maxhealth INT, lockcode VARCHAR(10), locked INT)", "OnTableCreated", "");
    mysql_tquery(g_SQL, "CREATE TABLE IF NOT EXISTS building_items (building_id INT, slot INT, item_id INT, amount INT)", "OnTableCreated", "");
    mysql_tquery(g_SQL, "CREATE TABLE IF NOT EXISTS sleeping_players (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(24), user_id INT, x FLOAT, y FLOAT, z FLOAT, rot FLOAT, interior INT, virtualworld INT, active INT, health FLOAT, armor FLOAT, hunger FLOAT, thirst FLOAT)", "OnTableCreated", "");
    mysql_tquery(g_SQL, "CREATE TABLE IF NOT EXISTS sleeping_inventory (sleep_id INT, slot INT, item_id INT, amount INT)", "OnTableCreated", "");
    mysql_tquery(g_SQL, "CREATE TABLE IF NOT EXISTS sleeping_materials (sleep_id INT, wood INT, stone INT, metal INT, cloth INT, fuel INT)", "OnTableCreated", "");

    // Game settings
    ShowPlayerMarkers(0);
    ShowNameTags(1);
    SetNameTagDrawDistance(20.0);
    DisableInteriorEnterExits();
    EnableStuntBonusForAll(0);
    SetWeather(2);

    // Create radiation zones
    CreateRadiationZones();

    // Spawn resources
    SpawnAllResources();

    // Load buildings
    LoadBuildings();

    // Spawn loot containers
    LoadLootContainers();

    // Load sleeping players
    LoadSleepingPlayers();

    // Set global timer
    SetTimer("UpdateGlobalTimers", 1000, true);
    SetTimer("SaveAllBuildings", 300000, true); // Save buildings every 5 minutes
    SetTimer("RandomAirDrop", 3600000, true); // Air drop every hour

    print("\n--------------------------------------");
    print(SERVER_NAME " Gamemode Loaded Successfully!");
    print("--------------------------------------\n");

    return 1;
}

public OnGameModeExit()
{
    // Save all players data
    foreach(new i : Player)
    {
        SavePlayerData(i);

        if(IsValidPlayerProgressBar(i, PlayerInfo[i][pProgressBar]))
            DestroyPlayerProgressBar(i, PlayerInfo[i][pProgressBar]);

        if(IsValidPlayerProgressBar(i, PlayerInfo[i][pHungerBar]))
            DestroyPlayerProgressBar(i, PlayerInfo[i][pHungerBar]);

        if(IsValidPlayerProgressBar(i, PlayerInfo[i][pThirstBar]))
            DestroyPlayerProgressBar(i, PlayerInfo[i][pThirstBar]);

        if(IsValidPlayerProgressBar(i, PlayerInfo[i][pRadiationBar]))
            DestroyPlayerProgressBar(i, PlayerInfo[i][pRadiationBar]);
    }

    // Save all buildings
    SaveAllBuildings();

    // Close MySQL connection
    mysql_close(g_SQL);

    print("\n--------------------------------------");
    print(SERVER_NAME " Gamemode Shutdown Complete!");
    print("--------------------------------------\n");

    return 1;
}

public OnPlayerConnect(playerid)
{
    // Reset player data
    ResetPlayerData(playerid);

    // Create HUD
    PlayerInfo[playerid][pProgressBar] = CreatePlayerProgressBar(playerid, 548.0, 35.0, 56.0, 9.0, COLOR_GREEN, 100.0);
    PlayerInfo[playerid][pHungerBar] = CreatePlayerProgressBar(playerid, 548.0, 46.0, 56.0, 9.0, COLOR_ORANGE, 100.0);
    PlayerInfo[playerid][pThirstBar] = CreatePlayerProgressBar(playerid, 548.0, 57.0, 56.0, 9.0, COLOR_BLUE, 100.0);
    PlayerInfo[playerid][pRadiationBar] = CreatePlayerProgressBar(playerid, 548.0, 68.0, 56.0, 9.0, COLOR_YELLOW, 100.0);

    ShowPlayerProgressBar(playerid, PlayerInfo[playerid][pProgressBar]);
    ShowPlayerProgressBar(playerid, PlayerInfo[playerid][pHungerBar]);
    ShowPlayerProgressBar(playerid, PlayerInfo[playerid][pThirstBar]);
    ShowPlayerProgressBar(playerid, PlayerInfo[playerid][pRadiationBar]);

    // Check if player exists in database
    new query[128], name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    mysql_format(g_SQL, query, sizeof(query), "SELECT * FROM players WHERE name = '%e'", name);
    mysql_tquery(g_SQL, query, "OnPlayerDataCheck", "i", playerid);

    // Send welcome message
    SendClientMessage(playerid, COLOR_GREEN, "Welcome to "SERVER_NAME"!");
    SendClientMessage(playerid, COLOR_WHITE, "This is a survival game based on Rust. Gather resources, build a base, and survive!");

    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    // Save player data
    SavePlayerData(playerid);

    // Create sleeping player if not in safe zone
    if(!IsPlayerInSafeZone(playerid) && PlayerInfo[playerid][pHealth] > 0.0)
    {
        PlayerSleepSave(playerid);
    }

    // Destroy progress bars
    if(IsValidPlayerProgressBar(playerid, PlayerInfo[playerid][pProgressBar]))
        DestroyPlayerProgressBar(playerid, PlayerInfo[playerid][pProgressBar]);

    if(IsValidPlayerProgressBar(playerid, PlayerInfo[playerid][pHungerBar]))
        DestroyPlayerProgressBar(playerid, PlayerInfo[playerid][pHungerBar]);

    if(IsValidPlayerProgressBar(playerid, PlayerInfo[playerid][pThirstBar]))
        DestroyPlayerProgressBar(playerid, PlayerInfo[playerid][pThirstBar]);

    if(IsValidPlayerProgressBar(playerid, PlayerInfo[playerid][pRadiationBar]))
        DestroyPlayerProgressBar(playerid, PlayerInfo[playerid][pRadiationBar]);

    return 1;
}

public OnPlayerSpawn(playerid)
{
    // Set player's health and basic stats
    SetPlayerHealth(playerid, PlayerInfo[playerid][pHealth]);
    SetPlayerArmour(playerid, PlayerInfo[playerid][pArmor]);

    // Set default skin
    SetPlayerSkin(playerid, 73 + random(5)); // Random survivor skin

    // Give basic tools if new player
    if(PlayerInfo[playerid][pSpawnPoint] == 0)
    {
        GivePlayerBasicKit(playerid);

        // Random spawn location on beach
        new rand = random(10);
        new Float:spawnX, Float:spawnY, Float:spawnZ;

        switch(rand)
        {
            case 0: { spawnX = -1867.0; spawnY = -88.0; spawnZ = 15.0; } // Beach locations
            case 1: { spawnX = -1650.0; spawnY = 150.0; spawnZ = 15.0; }
            case 2: { spawnX = -1250.0; spawnY = 320.0; spawnZ = 15.0; }
            case 3: { spawnX = -850.0; spawnY = 450.0; spawnZ = 15.0; }
            case 4: { spawnX = -450.0; spawnY = 520.0; spawnZ = 15.0; }
            case 5: { spawnX = 100.0; spawnY = 550.0; spawnZ = 15.0; }
            case 6: { spawnX = 450.0; spawnY = 450.0; spawnZ = 15.0; }
            case 7: { spawnX = 750.0; spawnY = 300.0; spawnZ = 15.0; }
            case 8: { spawnX = 1050.0; spawnY = 120.0; spawnZ = 15.0; }
            case 9: { spawnX = 1450.0; spawnY = -80.0; spawnZ = 15.0; }
        }

        SetPlayerPos(playerid, spawnX, spawnY, spawnZ);
    }
    else if(PlayerInfo[playerid][pSpawnPoint] == 1) // Sleeping bag spawn
    {
        // Look for player's sleeping bag
        for(new i = 0; i < BuildingCount; i++)
        {
            if(BuildingInfo[i][buildType] == 16 && BuildingInfo[i][buildOwner] == PlayerInfo[playerid][pID])
            {
                SetPlayerPos(playerid, BuildingInfo[i][buildX], BuildingInfo[i][buildY], BuildingInfo[i][buildZ] + 1.0);
                SetPlayerFacingAngle(playerid, BuildingInfo[i][buildRZ]);
                SetPlayerInterior(playerid, 0);
                SetPlayerVirtualWorld(playerid, 0);
                break;
            }
        }
    }
    else // Last position
    {
        SetPlayerPos(playerid, PlayerInfo[playerid][pLastX], PlayerInfo[playerid][pLastY], PlayerInfo[playerid][pLastZ]);
        SetPlayerInterior(playerid, PlayerInfo[playerid][pInterior]);
        SetPlayerVirtualWorld(playerid, PlayerInfo[playerid][pVirtualWorld]);
    }

    // Start survival timers
    UpdatePlayerHUDInfo(playerid);

    // Display welcome back message
    new string[128];
    format(string, sizeof(string), "Welcome back! Health: %.1f | Hunger: %.1f | Thirst: %.1f",
        PlayerInfo[playerid][pHealth],
        PlayerInfo[playerid][pHunger],
        PlayerInfo[playerid][pThirst]);
    SendClientMessage(playerid, COLOR_GREEN, string);

    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    // Update stats
    PlayerInfo[playerid][pDeaths]++;

    if(killerid != INVALID_PLAYER_ID)
    {
        PlayerInfo[killerid][pKills]++;

        // Give XP and possibly loot to killer
        new string[128];
        format(string, sizeof(string), "You killed %s and earned 50 XP!", GetPlayerNameEx(playerid));
        SendClientMessage(killerid, COLOR_GREEN, string);

        format(string, sizeof(string), "You were killed by %s!", GetPlayerNameEx(killerid));
        SendClientMessage(playerid, COLOR_RED, string);
    }
    else
    {
        SendClientMessage(playerid, COLOR_RED, "You died!");
    }

    // Create death loot container
    CreateDeathLoot(playerid);

    // Reset player's data
    ResetPlayerInventory(playerid);
    PlayerInfo[playerid][pHealth] = 100.0;
    PlayerInfo[playerid][pArmor] = 0.0;
    PlayerInfo[playerid][pHunger] = 100.0;
    PlayerInfo[playerid][pThirst] = 100.0;
    PlayerInfo[playerid][pRadiation] = 0.0;

    for(new i = 0; i < 5; i++)
    {
        PlayerInfo[playerid][pMaterials][i] = 0;
    }

    // Reset player's spawn point to random (no sleeping bag when dead)
    PlayerInfo[playerid][pSpawnPoint] = 0;

    // Save data
    SavePlayerData(playerid);

    return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    return 0; // All commands are handled by ZCMD
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    // Left mouse button (KEY_FIRE) for gathering resources and hitting
    if(newkeys & KEY_FIRE)
    {
        // If player is in building mode, cancel action
        if(PlayerInfo[playerid][pBuildingMode])
            return 1;

        // Check if player is gathering resources
        if(GetPlayerWeapon(playerid) == 0 || GetPlayerWeapon(playerid) == 1)
            GatherResource(playerid);

        // Check if player is hitting a building (raiding)
        if(GetPlayerWeapon(playerid) >= 1 && GetPlayerWeapon(playerid) <= 46)
            HitBuilding(playerid);
    }

    // Right mouse button (KEY_SECONDARY_ATTACK) for building placement/interaction
    if(newkeys & KEY_SECONDARY_ATTACK)
    {
        // Building placement mode
        if(PlayerInfo[playerid][pBuildingMode])
        {
            PlaceBuilding(playerid);
            return 1;
        }

        // Check for building interaction
        InteractWithBuilding(playerid);
    }

    // Y key for inventory
    if(newkeys & KEY_YES)
    {
        ShowPlayerInventory(playerid);
    }

    // N key for crafting menu
    if(newkeys & KEY_NO)
    {
        ShowCraftingMenu(playerid);
    }

    // H key for help menu
    if(newkeys & KEY_WALK)
    {
        ShowHelpMenu(playerid);
    }

    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch(dialogid)
    {
        case DIALOG_LOGIN:
        {
            if(!response) return Kick(playerid);

            new query[256], hash[65], name[MAX_PLAYER_NAME];
            GetPlayerName(playerid, name, sizeof(name));

            SHA256_PassHash(inputtext, "", hash, sizeof(hash));
            mysql_format(g_SQL, query, sizeof(query), "SELECT * FROM players WHERE name = '%e' AND password = '%e'", name, hash);
            mysql_tquery(g_SQL, query, "OnPlayerLogin", "i", playerid);
        }

        case DIALOG_REGISTER:
        {
            if(!response) return Kick(playerid);

            if(strlen(inputtext) < 6)
            {
                SendClientMessage(playerid, COLOR_RED, "Password must be at least 6 characters long!");
                ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Register", "Please create a password for your account (min 6 chars):", "Register", "Quit");
                return 1;
            }

            new query[512], hash[65], name[MAX_PLAYER_NAME];
            GetPlayerName(playerid, name, sizeof(name));

            SHA256_PassHash(inputtext, "", hash, sizeof(hash));
            mysql_format(g_SQL, query, sizeof(query), "INSERT INTO players (name, password, admin, kills, deaths, health, armor, hunger, thirst, radiation, wood, stone, metal, cloth, fuel, lastX, lastY, lastZ, interior, virtualworld, spawnpoint, hasmap, lastlogin, registerdate, playtime) VALUES ('%e', '%e', 0, 0, 0, 100.0, 0.0, 100.0, 100.0, 0.0, 0, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0, 0, 0, 0, %d, %d, 0)", name, hash, gettime(), gettime());
            mysql_tquery(g_SQL, query, "OnPlayerRegister", "i", playerid);
        }

        case DIALOG_INVENTORY:
        {
            if(!response) return 1;

            // Handle inventory item usage
            new item = PlayerInfo[playerid][pInventory][listitem];
            new amount = PlayerInfo[playerid][pInventoryAmount][listitem];

            if(item == 0 || amount == 0) return SendClientMessage(playerid, COLOR_RED, "This slot is empty!");

            // Handle item usage based on item ID
            switch(item)
            {
                case ITEM_FOOD:
                {
                    // Add hunger
                    PlayerInfo[playerid][pHunger] += 25.0;
                    if(PlayerInfo[playerid][pHunger] > 100.0) PlayerInfo[playerid][pHunger] = 100.0;

                    // Remove item
                    PlayerInfo[playerid][pInventoryAmount][listitem]--;
                    if(PlayerInfo[playerid][pInventoryAmount][listitem] <= 0)
                    {
                        PlayerInfo[playerid][pInventory][listitem] = 0;
                        PlayerInfo[playerid][pInventoryAmount][listitem] = 0;
                    }

                    SendClientMessage(playerid, COLOR_GREEN, "You ate food. Hunger +25");
                    UpdatePlayerHUDInfo(playerid);
                }

                case ITEM_WATER:
                {
                    // Add thirst
                    PlayerInfo[playerid][pThirst] += 30.0;
                    if(PlayerInfo[playerid][pThirst] > 100.0) PlayerInfo[playerid][pThirst] = 100.0;

                    // Remove item
                    PlayerInfo[playerid][pInventoryAmount][listitem]--;
                    if(PlayerInfo[playerid][pInventoryAmount][listitem] <= 0)
                    {
                        PlayerInfo[playerid][pInventory][listitem] = 0;
                        PlayerInfo[playerid][pInventoryAmount][listitem] = 0;
                    }

                    SendClientMessage(playerid, COLOR_GREEN, "You drank water. Thirst +30");
                    UpdatePlayerHUDInfo(playerid);
                }

                case ITEM_MEDKIT:
                {
                    // Add health
                    new Float:health;
                    GetPlayerHealth(playerid, health);
                    health += 50.0;
                    if(health > 100.0) health = 100.0;
                    SetPlayerHealth(playerid, health);
                    PlayerInfo[playerid][pHealth] = health;

                    // Remove item
                    PlayerInfo[playerid][pInventoryAmount][listitem]--;
                    if(PlayerInfo[playerid][pInventoryAmount][listitem] <= 0)
                    {
                        PlayerInfo[playerid][pInventory][listitem] = 0;
                        PlayerInfo[playerid][pInventoryAmount][listitem] = 0;
                    }

                    SendClientMessage(playerid, COLOR_GREEN, "You used a medkit. Health +50");
                    UpdatePlayerHUDInfo(playerid);
                }

                case ITEM_BANDAGE:
                {
                    // Add health
                    new Float:health;
                    GetPlayerHealth(playerid, health);
                    health += 15.0;
                    if(health > 100.0) health = 100.0;
                    SetPlayerHealth(playerid, health);
                    PlayerInfo[playerid][pHealth] = health;

                    // Remove item
                    PlayerInfo[playerid][pInventoryAmount][listitem]--;
                    if(PlayerInfo[playerid][pInventoryAmount][listitem] <= 0)
                    {
                        PlayerInfo[playerid][pInventory][listitem] = 0;
                        PlayerInfo[playerid][pInventoryAmount][listitem] = 0;
                    }

                    SendClientMessage(playerid, COLOR_GREEN, "You used a bandage. Health +15");
                    UpdatePlayerHUDInfo(playerid);
                }

                case ITEM_RADIATION_SUIT:
                {
                    // Equip radiation suit (provides protection against radiation)
                    PlayerInfo[playerid][pInventory][listitem] = 0;
                    PlayerInfo[playerid][pInventoryAmount][listitem] = 0;

                    // Change player's skin to radiation suit
                    SetPlayerSkin(playerid, 285); // Hazmat suit skin

                    SendClientMessage(playerid, COLOR_GREEN, "You equipped a radiation suit. You're protected from radiation.");
                }

                case ITEM_MAP:
                {
                    // Activate map
                    PlayerInfo[playerid][pHasMap] = 1;

                    // Remove item
                    PlayerInfo[playerid][pInventoryAmount][listitem]--;
                    if(PlayerInfo[playerid][pInventoryAmount][listitem] <= 0)
                    {
                        PlayerInfo[playerid][pInventory][listitem] = 0;
                        PlayerInfo[playerid][pInventoryAmount][listitem] = 0;
                    }

                    SendClientMessage(playerid, COLOR_GREEN, "You now have a map. Press M to view it.");
                }

                case ITEM_SLEEPING_BAG:
                {
                    // Place sleeping bag
                    PlayerInfo[playerid][pBuildingMode] = 1;
                    PlayerInfo[playerid][pBuildingType] = 16; // Sleeping bag
                    PlayerInfo[playerid][pInventory][listitem] = 0;
                    PlayerInfo[playerid][pInventoryAmount][listitem] = 0;

                    SendClientMessage(playerid, COLOR_GREEN, "Right-click to place your sleeping bag. This will be your spawn point.");
                }

                // Equip weapons
                case ITEM_PISTOL:
                {
                    GivePlayerWeapon(playerid, 22, PlayerInfo[playerid][pInventoryAmount][listitem]);
                    PlayerInfo[playerid][pInventory][listitem] = 0;
                    PlayerInfo[playerid][pInventoryAmount][listitem] = 0;

                    SendClientMessage(playerid, COLOR_GREEN, "You equipped a pistol.");
                }

                case ITEM_RIFLE:
                {
                    GivePlayerWeapon(playerid, 30, PlayerInfo[playerid][pInventoryAmount][listitem]);
                    PlayerInfo[playerid][pInventory][listitem] = 0;
                    PlayerInfo[playerid][pInventoryAmount][listitem] = 0;

                    SendClientMessage(playerid, COLOR_GREEN, "You equipped a rifle.");
                }

                case ITEM_SHOTGUN:
                {
                    GivePlayerWeapon(playerid, 25, PlayerInfo[playerid][pInventoryAmount][listitem]);
                    PlayerInfo[playerid][pInventory][listitem] = 0;
                    PlayerInfo[playerid][pInventoryAmount][listitem] = 0;

                    SendClientMessage(playerid, COLOR_GREEN, "You equipped a shotgun.");
                }

                // Building items
                case ITEM_HAMMER:
                {
                    ShowBuildingMenu(playerid);
                }

                case ITEM_FURNACE:
                {
                    PlayerInfo[playerid][pBuildingMode] = 1;
                    PlayerInfo[playerid][pBuildingType] = 17; // Furnace

                    // Remove item
                    PlayerInfo[playerid][pInventoryAmount][listitem]--;
                    if(PlayerInfo[playerid][pInventoryAmount][listitem] <= 0)
                    {
                        PlayerInfo[playerid][pInventory][listitem] = 0;
                        PlayerInfo[playerid][pInventoryAmount][listitem] = 0;
                    }

                    SendClientMessage(playerid, COLOR_GREEN, "Right-click to place your furnace.");
                }

                case ITEM_CAMPFIRE:
                {
                    PlayerInfo[playerid][pBuildingMode] = 1;
                    PlayerInfo[playerid][pBuildingType] = 18; // Campfire

                    // Remove item
                    PlayerInfo[playerid][pInventoryAmount][listitem]--;
                    if(PlayerInfo[playerid][pInventoryAmount][listitem] <= 0)
                    {
                        PlayerInfo[playerid][pInventory][listitem] = 0;
                        PlayerInfo[playerid][pInventoryAmount][listitem] = 0;
                    }

                    SendClientMessage(playerid, COLOR_GREEN, "Right-click to place your campfire.");
                }

                case ITEM_C4:
                {
                    // Using C4 on a nearby door
                    new bool:found = false;
                    new Float:x, Float:y, Float:z;
                    GetPlayerPos(playerid, x, y, z);

                    for(new i = 0; i < BuildingCount; i++)
                    {
                        if((BuildingInfo[i][buildType] == 3 || BuildingInfo[i][buildType] == 23) && // Door types
                           GetDistanceBetweenPoints3D(x, y, z, BuildingInfo[i][buildX], BuildingInfo[i][buildY], BuildingInfo[i][buildZ]) < 3.0)
                        {
                            // Plant C4
                            found = true;

                            // Remove item
                            PlayerInfo[playerid][pInventoryAmount][listitem]--;
                            if(PlayerInfo[playerid][pInventoryAmount][listitem] <= 0)
                            {
                                PlayerInfo[playerid][pInventory][listitem] = 0;
                                PlayerInfo[playerid][pInventoryAmount][listitem] = 0;
                            }

                            // Create explosion after 10 seconds
                            SetTimerEx("ExplodeC4", 10000, false, "i", i);

                            SendClientMessage(playerid, COLOR_RED, "C4 planted! It will explode in 10 seconds.");

                            // Create beeping sound
                            for(new j = 0; j < 10; j++)
                            {
                                SetTimerEx("PlayBeepSound", j * 1000, false, "i", playerid);
                            }

                            break;
                        }
                    }

                    if(!found)
                    {
                        SendClientMessage(playerid, COLOR_RED, "No door nearby to place C4 on!");
                    }
                }

                default:
                {
                    new string[128];
                    format(string, sizeof(string), "Selected Item: %d, Amount: %d", item, amount);
                    SendClientMessage(playerid, COLOR_WHITE, string);
                }
            }

            // Show inventory again
            ShowPlayerInventory(playerid);
        }

        case DIALOG_CRAFTING:
        {
            if(!response) return 1;

            // Selected item to craft
            new itemType;

            switch(listitem)
            {
                case 0: itemType = ITEM_HATCHET; // Hatchet
                case 1: itemType = ITEM_PICKAXE; // Pickaxe
                case 2: itemType = ITEM_HAMMER; // Hammer
                case 3: itemType = ITEM_BANDAGE; // Bandage
                case 4: itemType = ITEM_MEDKIT; // Medkit
                case 5: itemType = ITEM_SLEEPING_BAG; // Sleeping Bag
                case 6: itemType = ITEM_FURNACE; // Furnace
                case 7: itemType = ITEM_CAMPFIRE; // Campfire
                case 8: itemType = ITEM_WOOD_DOOR; // Wooden Door
                case 9: itemType = ITEM_METAL_DOOR; // Metal Door
                case 10: itemType = ITEM_CODELOCK; // Code Lock
                case 11: itemType = ITEM_PISTOL; // Pistol
                case 12: itemType = ITEM_SHOTGUN; // Shotgun
                case 13: itemType = ITEM_RIFLE; // Rifle
                case 14: itemType = ITEM_AMMO_PISTOL; // Pistol Ammo
                case 15: itemType = ITEM_AMMO_SHOTGUN; // Shotgun Ammo
                case 16: itemType = ITEM_AMMO_RIFLE; // Rifle Ammo
                case 17: itemType = ITEM_GUNPOWDER; // Gunpowder
                case 18: itemType = ITEM_EXPLOSIVE; // Explosive
                case 19: itemType = ITEM_C4; // C4
            }

            // Get crafting requirements
            new wood, stone, metal, cloth, other, otherItem;
            GetCraftingRequirements(itemType, wood, stone, metal, cloth, other, otherItem);

            // Check if player has required resources
            new string[512];
            format(string, sizeof(string), "Crafting Requirements:\n\n");

            if(wood > 0)
                format(string, sizeof(string), "%sWood: %d/%d\n", string, PlayerInfo[playerid][pMaterials][0], wood);

            if(stone > 0)
                format(string, sizeof(string), "%sStone: %d/%d\n", string, PlayerInfo[playerid][pMaterials][1], stone);

            if(metal > 0)
                format(string, sizeof(string), "%sMetal: %d/%d\n", string, PlayerInfo[playerid][pMaterials][2], metal);

            if(cloth > 0)
                format(string, sizeof(string), "%sCloth: %d/%d\n", string, PlayerInfo[playerid][pMaterials][3], cloth);

            if(other > 0)
            {
                new otherName[32];
                GetItemName(otherItem, otherName);

                new count = 0;
                for(new i = 0; i < 30; i++)
                {
                    if(PlayerInfo[playerid][pInventory][i] == otherItem)
                        count += PlayerInfo[playerid][pInventoryAmount][i];
                }

                format(string, sizeof(string), "%s%s: %d/%d\n", string, otherName, count, other);
            }

            // Check if player can craft the item
            if(PlayerInfo[playerid][pMaterials][0] >= wood &&
               PlayerInfo[playerid][pMaterials][1] >= stone &&
               PlayerInfo[playerid][pMaterials][2] >= metal &&
               PlayerInfo[playerid][pMaterials][3] >= cloth)
            {
                // Check for special items if needed
                new bool:hasOtherItem = true;

                if(other > 0)
                {
                    new count = 0;
                    for(new i = 0; i < 30; i++)
                    {
                        if(PlayerInfo[playerid][pInventory][i] == otherItem)
                            count += PlayerInfo[playerid][pInventoryAmount][i];
                    }

                    if(count < other)
                        hasOtherItem = false;
                }

                if(hasOtherItem)
                {
                    // Calculate crafting time
                    new craftTime = GetCraftingTime(itemType);

                    // Set player's crafting information
                    SetPVarInt(playerid, "CraftingItem", itemType);
                    SetPVarInt(playerid, "CraftingWood", wood);
                    SetPVarInt(playerid, "CraftingStone", stone);
                    SetPVarInt(playerid, "CraftingMetal", metal);
                    SetPVarInt(playerid, "CraftingCloth", cloth);
                    SetPVarInt(playerid, "CraftingOtherItem", otherItem);
                    SetPVarInt(playerid, "CraftingOtherAmount", other);

                    format(string, sizeof(string), "%s\nYou have all required materials. Craft this item?", string);
                    ShowPlayerDialog(playerid, DIALOG_CRAFTING_CONFIRM, DIALOG_STYLE_MSGBOX, "Confirm Crafting", string, "Craft", "Cancel");
                }
                else
                {
                    format(string, sizeof(string), "%s\nYou don't have enough materials to craft this item!", string);
                    ShowPlayerDialog(playerid, DIALOG_NULL ,DIALOG_STYLE_MSGBOX, "Crafting Failed", string, "Back", "");
                }
            }
            else
            {
                format(string, sizeof(string), "%s\nYou don't have enough materials to craft this item!", string);
                ShowPlayerDialog(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "Crafting Failed", string, "Back", "");
            }
        }

        case DIALOG_CRAFTING_CONFIRM:
        {
            if(!response) return ShowCraftingMenu(playerid);

            // Get crafting data
            new itemType = GetPVarInt(playerid, "CraftingItem");
            new wood = GetPVarInt(playerid, "CraftingWood");
            new stone = GetPVarInt(playerid, "CraftingStone");
            new metal = GetPVarInt(playerid, "CraftingMetal");
            new cloth = GetPVarInt(playerid, "CraftingCloth");
            new otherItem = GetPVarInt(playerid, "CraftingOtherItem");
            new otherAmount = GetPVarInt(playerid, "CraftingOtherAmount");

            // Deduct resources
            PlayerInfo[playerid][pMaterials][0] -= wood;
            PlayerInfo[playerid][pMaterials][1] -= stone;
            PlayerInfo[playerid][pMaterials][2] -= metal;
            PlayerInfo[playerid][pMaterials][3] -= cloth;

            // Deduct special items if needed
            if(otherAmount > 0)
            {
                new remaining = otherAmount;

                for(new i = 0; i < 30 && remaining > 0; i++)
                {
                    if(PlayerInfo[playerid][pInventory][i] == otherItem)
                    {
                        if(PlayerInfo[playerid][pInventoryAmount][i] <= remaining)
                        {
                            remaining -= PlayerInfo[playerid][pInventoryAmount][i];
                            PlayerInfo[playerid][pInventory][i] = 0;
                            PlayerInfo[playerid][pInventoryAmount][i] = 0;
                        }
                        else
                        {
                            PlayerInfo[playerid][pInventoryAmount][i] -= remaining;
                            remaining = 0;
                        }
                    }
                }
            }

            // Calculate crafting time
            new craftTime = GetCraftingTime(itemType);

            // Show crafting progress
            TogglePlayerControllable(playerid, 0);
            GameTextForPlayer(playerid, "~y~Crafting...", craftTime * 1000, 3);
            ApplyAnimation(playerid, "BD_FIRE", "wash_up", 4.1, 1, 0, 0, 1, craftTime * 1000, 1);

            // Start crafting timer
            SetTimerEx("FinishCrafting", craftTime * 1000, false, "ii", playerid, itemType);

            // Display crafting message
            new itemName[32];
            GetItemName(itemType, itemName);

            new string[128];
            format(string, sizeof(string), "Crafting %s... Please wait %d seconds.", itemName, craftTime);
            SendClientMessage(playerid, COLOR_GREEN, string);
        }

        case DIALOG_BUILDING:
        {
            if(!response) return 1;

            new _buildType;

            switch(listitem)
            {
                case 0: { _buildType = 0; } // Foundation
                case 1: { _buildType = 1; } // Wall
                case 2: { _buildType = 2; } // Doorway
                case 3: { _buildType = 4; } // Floor
                case 4: { _buildType = 5; } // Ceiling
                case 5: { _buildType = 6; } // Stairs
                case 6: { _buildType = 7; } // Window
                case 7: { _buildType = 8; } // Storage Box
            }

            new wood, stone, metal;
            GetBuildingRequirements(_buildType, wood, stone, metal);

            if(PlayerInfo[playerid][pMaterials][0] >= wood &&
            PlayerInfo[playerid][pMaterials][1] >= stone &&
            PlayerInfo[playerid][pMaterials][2] >= metal)
            {
                PlayerInfo[playerid][pBuildingMode] = 1;
                PlayerInfo[playerid][pBuildingType] = _buildType;
                PlayerInfo[playerid][pBuildingRotation] = 0;

                PlayerInfo[playerid][pMaterials][0] -= wood;
                PlayerInfo[playerid][pMaterials][1] -= stone;
                PlayerInfo[playerid][pMaterials][2] -= metal;

                SendClientMessage(playerid, COLOR_GREEN, "Building mode enabled. Right-click to place, Q/E to rotate. Right-click again to cancel.");
            }
            else
            {
                new string[256];
                format(string, sizeof(string), "Building Requirements:\nWood: %d/%d\nStone: %d/%d\nMetal: %d/%d\n\nYou don't have enough materials!",
                    PlayerInfo[playerid][pMaterials][0], wood,
                    PlayerInfo[playerid][pMaterials][1], stone,
                    PlayerInfo[playerid][pMaterials][2], metal);

                ShowPlayerDialog(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "Building Failed", string, "Back", "");
            }
        }

        case DIALOG_LOOT:
        {
            if(!response) return 1;

            // Player is taking an item from a loot container
            new lootid = PlayerInfo[playerid][pLootingID];

            if(lootid == -1 || !LootInfo[lootid][lootActive])
            {
                SendClientMessage(playerid, COLOR_RED, "This container is no longer available!");
                return 1;
            }

            new itemID = LootInfo[lootid][lootItems][listitem];
            new amount = LootInfo[lootid][lootItemsAmount][listitem];

            if(itemID == 0 || amount == 0)
            {
                SendClientMessage(playerid, COLOR_RED, "This slot is empty!");
                return ShowLootContainer(playerid, lootid);
            }

            // Add item to player's inventory
            new slot = FindFreeInventorySlot(playerid, itemID);

            if(slot == -1)
            {
                SendClientMessage(playerid, COLOR_RED, "Your inventory is full!");
                return ShowLootContainer(playerid, lootid);
            }

            // Transfer item
            if(PlayerInfo[playerid][pInventory][slot] == 0)
            {
                PlayerInfo[playerid][pInventory][slot] = itemID;
                PlayerInfo[playerid][pInventoryAmount][slot] = amount;
            }
            else
            {
                PlayerInfo[playerid][pInventoryAmount][slot] += amount;
            }

            // Remove from loot container
            LootInfo[lootid][lootItems][listitem] = 0;
            LootInfo[lootid][lootItemsAmount][listitem] = 0;

            // Get item name
            new itemName[32];
            GetItemName(itemID, itemName);

            // Send message
            new string[128];
            format(string, sizeof(string), "You took %s x%d from the container.", itemName, amount);
            SendClientMessage(playerid, COLOR_GREEN, string);

            // Show loot container again
            ShowLootContainer(playerid, lootid);
        }

        case DIALOG_PLAYER_MENU:
        {
            if(!response) return 1;

            switch(listitem)
            {
                case 0: // Stats
                {
                    new string[512];
                    format(string, sizeof(string), "Player Statistics\n\n");
                    format(string, sizeof(string), "%sName: %s\n", string, GetPlayerNameEx(playerid));
                    format(string, sizeof(string), "%sKills: %d\n", string, PlayerInfo[playerid][pKills]);
                    format(string, sizeof(string), "%sDeaths: %d\n", string, PlayerInfo[playerid][pDeaths]);
                    format(string, sizeof(string), "%sK/D Ratio: %.2f\n", string, PlayerInfo[playerid][pDeaths] > 0 ? float(PlayerInfo[playerid][pKills]) / float(PlayerInfo[playerid][pDeaths]) : float(PlayerInfo[playerid][pKills]));
                    format(string, sizeof(string), "%sPlay Time: %d hours\n", string, PlayerInfo[playerid][pPlaytime] / 3600);

                    ShowPlayerDialog(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "Player Statistics", string, "Close", "");
                }

                case 1: // Inventory
                {
                    ShowPlayerInventory(playerid);
                }

                case 2: // Crafting
                {
                    ShowCraftingMenu(playerid);
                }

                case 3: // Building
                {
                    ShowBuildingMenu(playerid);
                }

                case 4: // Help
                {
                    ShowHelpMenu(playerid);
                }

                case 5: // Admin Panel (if admin)
                {
                    if(PlayerInfo[playerid][pAdmin] >= 1)
                    {
                        ShowAdminMenu(playerid);
                    }
                    else
                    {
                        SendClientMessage(playerid, COLOR_RED, "You are not an administrator!");
                    }
                }
            }
        }

        case DIALOG_ADMIN:
        {
            if(!response) return 1;

            if(PlayerInfo[playerid][pAdmin] < 1)
                return SendClientMessage(playerid, COLOR_RED, "You are not an administrator!");

            switch(listitem)
            {
                case 0: // Teleport to coordinates
                {
                    ShowPlayerDialog(playerid, DIALOG_ADMIN + 1, DIALOG_STYLE_INPUT, "Admin Teleport", "Enter coordinates (X Y Z):", "Teleport", "Cancel");
                }

                case 1: // Spawn item
                {
                    ShowPlayerDialog(playerid, DIALOG_ADMIN + 2, DIALOG_STYLE_INPUT, "Spawn Item", "Enter Item ID and Amount (ID Amount):", "Spawn", "Cancel");
                }

                case 2: // Spawn resource
                {
                    ShowPlayerDialog(playerid, DIALOG_ADMIN_SPAWN, DIALOG_STYLE_LIST, "Spawn Resource", "Wood Tree\nStone Node\nMetal Node\nHemp Plant\nBarrel\nCrate\nMilitary Crate", "Spawn", "Cancel");
                }

                case 3: // Kill player
                {
                    new string[512], count = 0;

                    foreach(new i : Player)
                    {
                        format(string, sizeof(string), "%s%s (ID: %d)\n", string, GetPlayerNameEx(i), i);
                        count++;
                    }

                    if(count == 0)
                    {
                        SendClientMessage(playerid, COLOR_RED, "No players online to kill!");
                        return ShowAdminMenu(playerid);
                    }

                    ShowPlayerDialog(playerid, DIALOG_ADMIN + 3, DIALOG_STYLE_LIST, "Kill Player", string, "Kill", "Cancel");
                }

                case 4: // Reset server
                {
                    if(PlayerInfo[playerid][pAdmin] < 3) // Require level 3 admin
                    {
                        SendClientMessage(playerid, COLOR_RED, "You need admin level 3 to use this command!");
                        return ShowAdminMenu(playerid);
                    }

                    ShowPlayerDialog(playerid, DIALOG_ADMIN + 4, DIALOG_STYLE_MSGBOX, "Reset Server", "Are you sure you want to reset the server?\nThis will kick all players and restart the script.", "Reset", "Cancel");
                }

                case 5: // Set admin level
                {
                    if(PlayerInfo[playerid][pAdmin] < 3) // Require level 3 admin
                    {
                        SendClientMessage(playerid, COLOR_RED, "You need admin level 3 to use this command!");
                        return ShowAdminMenu(playerid);
                    }

                    new string[512], count = 0;

                    foreach(new i : Player)
                    {
                        format(string, sizeof(string), "%s%s (ID: %d, Admin Level: %d)\n", string, GetPlayerNameEx(i), i, PlayerInfo[i][pAdmin]);
                        count++;
                    }

                    if(count == 0)
                    {
                        SendClientMessage(playerid, COLOR_RED, "No players online to set admin level!");
                        return ShowAdminMenu(playerid);
                    }

                    ShowPlayerDialog(playerid, DIALOG_ADMIN + 5, DIALOG_STYLE_LIST, "Set Admin Level", string, "Select", "Cancel");
                }
            }
        }
    }

    return 1;
}

public OnPlayerUpdate(playerid)
{
    // Update player's data
    new Float:health;
    GetPlayerHealth(playerid, health);
    PlayerInfo[playerid][pHealth] = health;

    new Float:armour;
    GetPlayerArmour(playerid, armour);
    PlayerInfo[playerid][pArmor] = armour;

    // Check radiation exposure
    CheckRadiationExposure(playerid);

    // Update HUD occasionally (not every frame)
    if(GetTickCount() % 5000 < 50) // Update roughly every 5 seconds
    {
        UpdatePlayerHUDInfo(playerid);
    }

    return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
    return 1;
}

// Timer functions
forward FinishCrafting(playerid, itemType);
public FinishCrafting(playerid, itemType)
{
    if(!IsPlayerConnected(playerid)) return 0;

    // Enable player controls
    TogglePlayerControllable(playerid, 1);
    ClearAnimations(playerid);

    // Add crafted item to inventory
    new slot = FindFreeInventorySlot(playerid, itemType);

    if(slot == -1)
    {
        SendClientMessage(playerid, COLOR_RED, "Inventory full! Crafted item was dropped.");

        // Create a loot container with the item at player's position
        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);

        new lootid = FindFreeLootContainer();
        if(lootid != -1)
        {
            LootInfo[lootid][lootType] = 4; // Dropped item
            LootInfo[lootid][lootX] = x;
            LootInfo[lootid][lootY] = y;
            LootInfo[lootid][lootZ] = z;
            LootInfo[lootid][lootInterior] = GetPlayerInterior(playerid);
            LootInfo[lootid][lootVW] = GetPlayerVirtualWorld(playerid);
            LootInfo[lootid][lootItems][0] = itemType;
            LootInfo[lootid][lootItemsAmount][0] = 1;
            LootInfo[lootid][lootActive] = true;
            LootInfo[lootid][lootRespawnTime] = 300; // 5 minutes

            // Create object
            LootInfo[lootid][lootObject] = CreateDynamicObject(2969, x, y, z - 0.5, 0.0, 0.0, 0.0, GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid));
        }
    }
    else
    {
        if(PlayerInfo[playerid][pInventory][slot] == 0)
        {
            PlayerInfo[playerid][pInventory][slot] = itemType;
            PlayerInfo[playerid][pInventoryAmount][slot] = 1;
        }
        else
        {
            PlayerInfo[playerid][pInventoryAmount][slot]++;
        }

        // Get item name
        new itemName[32];
        GetItemName(itemType, itemName);

        // Display success message
        new string[128];
        format(string, sizeof(string), "You crafted a %s!", itemName);
        SendClientMessage(playerid, COLOR_GREEN, string);
    }

    return 1;
}

forward ExplodeC4(buildingid);
public ExplodeC4(buildingid)
{
    if(buildingid < 0 || buildingid >= BuildingCount) return 0;
    if(!IsValidDynamicObject(BuildingInfo[buildingid][buildObject])) return 0;

    // Create explosion effect
    CreateExplosion(BuildingInfo[buildingid][buildX], BuildingInfo[buildingid][buildY], BuildingInfo[buildingid][buildZ], 7, 5.0);

    // Damage the door/wall severely or destroy it
    BuildingInfo[buildingid][buildHealth] -= 500; // Huge damage

    if(BuildingInfo[buildingid][buildHealth] <= 0)
    {
        // Destroy the building object
        DestroyDynamicObject(BuildingInfo[buildingid][buildObject]);
        BuildingInfo[buildingid][buildObject] = INVALID_OBJECT_ID;

        // Remove from database
        new query[128];
        mysql_format(g_SQL, query, sizeof(query), "DELETE FROM buildings WHERE id = %d", BuildingInfo[buildingid][buildID]);
        mysql_tquery(g_SQL, query);

        // Also remove any items stored in it
        mysql_format(g_SQL, query, sizeof(query), "DELETE FROM building_items WHERE building_id = %d", BuildingInfo[buildingid][buildID]);
        mysql_tquery(g_SQL, query);

        // Notify nearby players
        foreach(new i : Player)
        {
            if(IsPlayerInRangeOfPoint(i, 50.0, BuildingInfo[buildingid][buildX], BuildingInfo[buildingid][buildY], BuildingInfo[buildingid][buildZ]))
            {
                SendClientMessage(i, COLOR_RED, "A building was destroyed by an explosion!");
            }
        }
    }
    else
    {
        // Notify nearby players
        foreach(new i : Player)
        {
            if(IsPlayerInRangeOfPoint(i, 50.0, BuildingInfo[buildingid][buildX], BuildingInfo[buildingid][buildY], BuildingInfo[buildingid][buildZ]))
            {
                SendClientMessage(i, COLOR_RED, "A building was damaged by an explosion!");
            }
        }
    }

    return 1;
}

forward PlayBeepSound(playerid);
public PlayBeepSound(playerid)
{
    if(!IsPlayerConnected(playerid)) return 0;

    PlayerPlaySound(playerid, 1139, 0.0, 0.0, 0.0); // Beep sound

    return 1;
}

forward UpdateGlobalTimers();
public UpdateGlobalTimers()
{
    // This function runs every second

    // Update all players' hunger and thirst
    foreach(new i : Player)
    {
        // Decrease hunger and thirst over time
        PlayerInfo[i][pHunger] -= 0.03; // About 1 per minute
        PlayerInfo[i][pThirst] -= 0.05; // About 1.5 per minute

        // Handle hunger and thirst damage
        if(PlayerInfo[i][pHunger] <= 0.0)
        {
            PlayerInfo[i][pHunger] = 0.0;

            // Damage player from starvation
            new Float:health;
            GetPlayerHealth(i, health);
            health -= 1.0;

            if(health <= 0.0)
            {
                SetPlayerHealth(i, 0.0);
            }
            else
            {
                SetPlayerHealth(i, health);
                PlayerInfo[i][pHealth] = health;
            }

            // Send warning message every 15 seconds
            if(gettime() % 15 == 0)
            {
                SendClientMessage(i, COLOR_RED, "You are starving! Find food!");
            }
        }

        if(PlayerInfo[i][pThirst] <= 0.0)
        {
            PlayerInfo[i][pThirst] = 0.0;

            // Damage player from dehydration
            new Float:health;
            GetPlayerHealth(i, health);
            health -= 1.5;

            if(health <= 0.0)
            {
                SetPlayerHealth(i, 0.0);
            }
            else
            {
                SetPlayerHealth(i, health);
                PlayerInfo[i][pHealth] = health;
            }

            // Send warning message every 15 seconds
            if(gettime() % 15 == 0)
            {
                SendClientMessage(i, COLOR_RED, "You are dehydrated! Find water!");
            }
        }

        // Update HUD every 10 seconds
        if(gettime() % 10 == 0)
        {
            UpdatePlayerHUDInfo(i);
        }

        // Increment playtime
        PlayerInfo[i][pPlaytime]++;
    }

    // Update loot container respawns
    for(new i = 0; i < LootCount; i++)
    {
        if(!LootInfo[i][lootActive] && LootInfo[i][lootRespawnTime] > 0)
        {
            LootInfo[i][lootRespawnTime]--;

            if(LootInfo[i][lootRespawnTime] <= 0)
            {
                RespawnLootContainer(i);
            }
        }
    }

    // Every 5 minutes (300 seconds), save all players' data
    if(gettime() % 300 == 0)
    {
        foreach(new i : Player)
        {
            SavePlayerData(i);
        }

        print("Auto-saved all players' data");
    }

    return 1;
}

forward SaveAllBuildings();
public SaveAllBuildings()
{
    new query[256];

    for(new i = 0; i < BuildingCount; i++)
    {
        if(IsValidDynamicObject(BuildingInfo[i][buildObject]))
        {
            // Update building in database
            mysql_format(g_SQL, query, sizeof(query),
                "UPDATE buildings SET health = %d WHERE id = %d",
                BuildingInfo[i][buildHealth],
                BuildingInfo[i][buildID]
            );
            mysql_tquery(g_SQL, query);
        }
    }

    print("Auto-saved all buildings");

    return 1;
}

forward RandomAirDrop();
public RandomAirDrop()
{
    // Check if enough players are online
    new playerCount = 0;
    foreach(new i : Player)
    {
        playerCount++;
    }

    if(playerCount < 3) return 0; // Need at least 3 players for air drop

    // Generate random position
    new Float:dropX = -3000.0 + float(random(6000));
    new Float:dropY = -3000.0 + float(random(6000));
    new Float:dropZ = 0.0;

    // Create airdrop container
    new lootid = FindFreeLootContainer();
    if(lootid == -1) return 0;

    LootInfo[lootid][lootType] = 3; // Elite Crate
    LootInfo[lootid][lootX] = dropX;
    LootInfo[lootid][lootY] = dropY;
    LootInfo[lootid][lootZ] = dropZ;
    LootInfo[lootid][lootInterior] = 0;
    LootInfo[lootid][lootVW] = 0;
    LootInfo[lootid][lootActive] = true;
    LootInfo[lootid][lootRespawnTime] = 0; // Won't respawn automatically

    // Fill with high-tier loot
    for(new i = 0; i < 10; i++)
    {
        LootInfo[lootid][lootItems][i] = 0;
        LootInfo[lootid][lootItemsAmount][i] = 0;
    }

    // Add random high-tier items
    new itemCount = 3 + random(4); // 3-6 items

    for(new i = 0; i < itemCount; i++)
    {
        new slot = i;
        new itemType = GetRandomHighTierItem();
        new amount = 1;

        // Adjust amount for some items
        switch(itemType)
        {
            case ITEM_AMMO_PISTOL, ITEM_AMMO_RIFLE, ITEM_AMMO_SHOTGUN:
                amount = 10 + random(20);
            case ITEM_METAL_FRAGMENTS, ITEM_GUNPOWDER:
                amount = 50 + random(50);
        }

        LootInfo[lootid][lootItems][slot] = itemType;
        LootInfo[lootid][lootItemsAmount][slot] = amount;
    }

    // Create visual object for the airdrop
    LootInfo[lootid][lootObject] = CreateDynamicObject(2977, dropX, dropY, dropZ, 0.0, 0.0, 0.0, 0, 0);

    // Notify all players
    new string[128];
    format(string, sizeof(string), "An air drop has been deployed! Look for the supply crate!");
    SendClientMessageToAll(COLOR_ORANGE, string);

    // Create a checkpoint for the airdrop
    foreach(new i : Player)
    {
        if(PlayerInfo[i][pHasMap])
        {
            SetPlayerCheckpoint(i, dropX, dropY, dropZ, 5.0);
            SendClientMessage(i, COLOR_ORANGE, "Air drop location has been marked on your map!");
        }
    }

    return 1;
}

forward UpdateAllPlayersHUDInfo();
public UpdateAllPlayersHUDInfo()
{
    foreach(new i : Player)
    {
        UpdatePlayerHUDInfo(i);
    }

    return 1;
}

// Custom commands
CMD:inventory(playerid, params[])
{
    ShowPlayerInventory(playerid);
    return 1;
}

CMD:craft(playerid, params[])
{
    ShowCraftingMenu(playerid);
    return 1;
}

CMD:build(playerid, params[])
{
    ShowBuildingMenu(playerid);
    return 1;
}

CMD:drop(playerid, params[])
{
    new slot, amount;

    if(sscanf(params, "ii", slot, amount))
    {
        SendClientMessage(playerid, COLOR_WHITE, "USAGE: /drop [slot] [amount]");
        return 1;
    }

    if(slot < 1 || slot > 30)
    {
        SendClientMessage(playerid, COLOR_RED, "Invalid slot number (1-30)!");
        return 1;
    }

    slot--; // Convert to 0-based index

    if(PlayerInfo[playerid][pInventory][slot] == 0)
    {
        SendClientMessage(playerid, COLOR_RED, "This slot is empty!");
        return 1;
    }

    if(amount <= 0 || amount > PlayerInfo[playerid][pInventoryAmount][slot])
    {
        SendClientMessage(playerid, COLOR_RED, "Invalid amount!");
        return 1;
    }

    // Get item info
    new itemType = PlayerInfo[playerid][pInventory][slot];
    new itemName[32];
    GetItemName(itemType, itemName);

    // Drop the item
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    new lootid = FindFreeLootContainer();
    if(lootid != -1)
    {
        LootInfo[lootid][lootType] = 4; // Dropped item
        LootInfo[lootid][lootX] = x;
        LootInfo[lootid][lootY] = y;
        LootInfo[lootid][lootZ] = z;
        LootInfo[lootid][lootInterior] = GetPlayerInterior(playerid);
        LootInfo[lootid][lootVW] = GetPlayerVirtualWorld(playerid);
        LootInfo[lootid][lootItems][0] = itemType;
        LootInfo[lootid][lootItemsAmount][0] = amount;
        LootInfo[lootid][lootActive] = true;
        LootInfo[lootid][lootRespawnTime] = 300; // 5 minutes

        // Create object
        LootInfo[lootid][lootObject] = CreateDynamicObject(2969, x, y, z - 0.5, 0.0, 0.0, 0.0, GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid));

        // Remove from player's inventory
        PlayerInfo[playerid][pInventoryAmount][slot] -= amount;
        if(PlayerInfo[playerid][pInventoryAmount][slot] <= 0)
        {
            PlayerInfo[playerid][pInventory][slot] = 0;
            PlayerInfo[playerid][pInventoryAmount][slot] = 0;
        }

        // Send message
        new string[128];
        format(string, sizeof(string), "You dropped %s x%d on the ground.", itemName, amount);
        SendClientMessage(playerid, COLOR_GREEN, string);
    }
    else
    {
        SendClientMessage(playerid, COLOR_RED, "Failed to drop item. Try again later.");
    }

    return 1;
}

CMD:menu(playerid, params[])
{
    ShowPlayerMenu(playerid);
    return 1;
}

CMD:help(playerid, params[])
{
    ShowHelpMenu(playerid);
    return 1;
}

CMD:stats(playerid, params[])
{
    new string[512];
    format(string, sizeof(string), "Player Statistics\n\n");
    format(string, sizeof(string), "%sName: %s\n", string, GetPlayerNameEx(playerid));
    format(string, sizeof(string), "%sKills: %d\n", string, PlayerInfo[playerid][pKills]);
    format(string, sizeof(string), "%sDeaths: %d\n", string, PlayerInfo[playerid][pDeaths]);
    format(string, sizeof(string), "%sK/D Ratio: %.2f\n", string, PlayerInfo[playerid][pDeaths] > 0 ? float(PlayerInfo[playerid][pKills]) / float(PlayerInfo[playerid][pDeaths]) : float(PlayerInfo[playerid][pKills]));
    format(string, sizeof(string), "%sHealth: %.1f\n", string, PlayerInfo[playerid][pHealth]);
    format(string, sizeof(string), "%sHunger: %.1f\n", string, PlayerInfo[playerid][pHunger]);
    format(string, sizeof(string), "%sThirst: %.1f\n", string, PlayerInfo[playerid][pThirst]);
    format(string, sizeof(string), "%sRadiation: %.1f\n", string, PlayerInfo[playerid][pRadiation]);
    format(string, sizeof(string), "%sPlay Time: %d hours %d minutes\n", string, PlayerInfo[playerid][pPlaytime] / 3600, (PlayerInfo[playerid][pPlaytime] % 3600) / 60);

    ShowPlayerDialog(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "Player Statistics", string, "Close", "");

    return 1;
}

CMD:resources(playerid, params[])
{
    new string[256];
    format(string, sizeof(string), "Resources:\n\n");
    format(string, sizeof(string), "%sWood: %d\n", string, PlayerInfo[playerid][pMaterials][0]);
    format(string, sizeof(string), "%sStone: %d\n", string, PlayerInfo[playerid][pMaterials][1]);
    format(string, sizeof(string), "%sMetal: %d\n", string, PlayerInfo[playerid][pMaterials][2]);
    format(string, sizeof(string), "%sCloth: %d\n", string, PlayerInfo[playerid][pMaterials][3]);
    format(string, sizeof(string), "%sFuel: %d\n", string, PlayerInfo[playerid][pMaterials][4]);

    ShowPlayerDialog(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "Resources", string, "Close", "");

    return 1;
}

CMD:suicide(playerid, params[])
{
    SendClientMessage(playerid, COLOR_RED, "You committed suicide.");
    SetPlayerHealth(playerid, 0.0);
    return 1;
}

// Admin commands
CMD:admin(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] >= 1)
    {
        ShowAdminMenu(playerid);
    }
    else
    {
        SendClientMessage(playerid, COLOR_RED, "You are not an administrator!");
    }

    return 1;
}

CMD:aduty(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 1)
        return SendClientMessage(playerid, COLOR_RED, "You are not an administrator!");

    new string[128];

    if(GetPVarInt(playerid, "AdminDuty") == 0)
    {
        SetPVarInt(playerid, "AdminDuty", 1);
        SetPlayerColor(playerid, 0xFF0000FF); // Red color for admins
        format(string, sizeof(string), "* Administrator %s is now on duty.", GetPlayerNameEx(playerid));
        SendClientMessageToAll(COLOR_RED, string);
    }
    else
    {
        SetPVarInt(playerid, "AdminDuty", 0);
        SetPlayerColor(playerid, 0xFFFFFFFF); // White color for normal players
        format(string, sizeof(string), "* Administrator %s is now off duty.", GetPlayerNameEx(playerid));
        SendClientMessageToAll(COLOR_RED, string);
    }

    return 1;
}

CMD:goto(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 1)
        return SendClientMessage(playerid, COLOR_RED, "You are not an administrator!");

    new targetid;

    if(sscanf(params, "u", targetid))
        return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /goto [playerid/name]");

    if(!IsPlayerConnected(targetid))
        return SendClientMessage(playerid, COLOR_RED, "Player not connected!");

    new Float:x, Float:y, Float:z;
    GetPlayerPos(targetid, x, y, z);

    SetPlayerPos(playerid, x, y + 2.0, z);
    SetPlayerInterior(playerid, GetPlayerInterior(targetid));
    SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(targetid));

    new string[128];
    format(string, sizeof(string), "You teleported to %s.", GetPlayerNameEx(targetid));
    SendClientMessage(playerid, COLOR_GREEN, string);

    return 1;
}

CMD:gethere(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 2)
        return SendClientMessage(playerid, COLOR_RED, "You are not a level 2+ administrator!");

    new targetid;

    if(sscanf(params, "u", targetid))
        return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /gethere [playerid/name]");

    if(!IsPlayerConnected(targetid))
        return SendClientMessage(playerid, COLOR_RED, "Player not connected!");

    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    SetPlayerPos(targetid, x, y + 2.0, z);
    SetPlayerInterior(targetid, GetPlayerInterior(playerid));
    SetPlayerVirtualWorld(targetid, GetPlayerVirtualWorld(playerid));

    new string[128];
    format(string, sizeof(string), "You teleported %s to your position.", GetPlayerNameEx(targetid));
    SendClientMessage(playerid, COLOR_GREEN, string);

    format(string, sizeof(string), "Administrator %s teleported you.", GetPlayerNameEx(playerid));
    SendClientMessage(targetid, COLOR_GREEN, string);

    return 1;
}

CMD:giveitem(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 2)
        return SendClientMessage(playerid, COLOR_RED, "You are not a level 2+ administrator!");

    new targetid, itemid, amount;

    if(sscanf(params, "uii", targetid, itemid, amount))
        return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /giveitem [playerid/name] [itemid] [amount]");

    if(!IsPlayerConnected(targetid))
        return SendClientMessage(playerid, COLOR_RED, "Player not connected!");

    if(itemid <= 0 || itemid > 30)
        return SendClientMessage(playerid, COLOR_RED, "Invalid item ID!");

    if(amount <= 0 || amount > 1000)
        return SendClientMessage(playerid, COLOR_RED, "Invalid amount (1-1000)!");

    // Add item to player's inventory
    new slot = FindFreeInventorySlot(targetid, itemid);

    if(slot == -1)
    {
        SendClientMessage(playerid, COLOR_RED, "Player's inventory is full!");
        return 1;
    }

    if(PlayerInfo[targetid][pInventory][slot] == 0)
    {
        PlayerInfo[targetid][pInventory][slot] = itemid;
        PlayerInfo[targetid][pInventoryAmount][slot] = amount;
    }
    else
    {
        PlayerInfo[targetid][pInventoryAmount][slot] += amount;
    }

    // Get item name
    new itemName[32];
    GetItemName(itemid, itemName);

    // Send messages
    new string[128];
    format(string, sizeof(string), "You gave %s %d x %s.", GetPlayerNameEx(targetid), amount, itemName);
    SendClientMessage(playerid, COLOR_GREEN, string);

    format(string, sizeof(string), "Administrator %s gave you %d x %s.", GetPlayerNameEx(playerid), amount, itemName);
    SendClientMessage(targetid, COLOR_GREEN, string);

    return 1;
}

CMD:giveresource(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 2)
        return SendClientMessage(playerid, COLOR_RED, "You are not a level 2+ administrator!");

    new targetid, resourceid, amount;

    if(sscanf(params, "uii", targetid, resourceid, amount))
    {
        SendClientMessage(playerid, COLOR_WHITE, "USAGE: /giveresource [playerid/name] [resourceid] [amount]");
        SendClientMessage(playerid, COLOR_WHITE, "Resource IDs: 0=Wood, 1=Stone, 2=Metal, 3=Cloth, 4=Fuel");
        return 1;
    }

    if(!IsPlayerConnected(targetid))
        return SendClientMessage(playerid, COLOR_RED, "Player not connected!");

    if(resourceid < 0 || resourceid > 4)
        return SendClientMessage(playerid, COLOR_RED, "Invalid resource ID (0-4)!");

    if(amount <= 0 || amount > 10000)
        return SendClientMessage(playerid, COLOR_RED, "Invalid amount (1-10000)!");

    // Add resource to player
    PlayerInfo[targetid][pMaterials][resourceid] += amount;

    // Get resource name
    new resourceName[10];
    switch(resourceid)
    {
        case 0: resourceName = "Wood";
        case 1: resourceName = "Stone";
        case 2: resourceName = "Metal";
        case 3: resourceName = "Cloth";
        case 4: resourceName = "Fuel";
    }

    // Send messages
    new string[128];
    format(string, sizeof(string), "You gave %s %d x %s.", GetPlayerNameEx(targetid), amount, resourceName);
    SendClientMessage(playerid, COLOR_GREEN, string);

    format(string, sizeof(string), "Administrator %s gave you %d x %s.", GetPlayerNameEx(playerid), amount, resourceName);
    SendClientMessage(targetid, COLOR_GREEN, string);

    return 1;
}

CMD:spawn(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 3)
        return SendClientMessage(playerid, COLOR_RED, "You are not a level 3+ administrator!");

    new type, Float:x, Float:y, Float:z;

    if(sscanf(params, "i", type))
    {
        SendClientMessage(playerid, COLOR_WHITE, "USAGE: /spawn [type]");
        SendClientMessage(playerid, COLOR_WHITE, "Types: 0=Wood, 1=Stone, 2=Metal, 3=Hemp, 4=Barrel, 5=Crate, 6=Military Crate");
        return 1;
    }

    if(type < 0 || type > 6)
        return SendClientMessage(playerid, COLOR_RED, "Invalid type (0-6)!");

    GetPlayerPos(playerid, x, y, z);

    if(type <= 3) // Resources
    {
        new resourceid = CreateResourceAtPos(type, x, y, z);

        if(resourceid != -1)
        {
            new string[128];

            switch(type)
            {
                case 0: format(string, sizeof(string), "You spawned a wood resource node (ID: %d).", resourceid);
                case 1: format(string, sizeof(string), "You spawned a stone resource node (ID: %d).", resourceid);
                case 2: format(string, sizeof(string), "You spawned a metal resource node (ID: %d).", resourceid);
                case 3: format(string, sizeof(string), "You spawned a hemp plant (ID: %d).", resourceid);
            }

            SendClientMessage(playerid, COLOR_GREEN, string);
        }
        else
        {
            SendClientMessage(playerid, COLOR_RED, "Failed to spawn resource. Maximum resources reached.");
        }
    }
    else // Loot containers
    {
        new lootid = CreateLootContainerAtPos(type - 4, x, y, z);

        if(lootid != -1)
        {
            new string[128];

            switch(type)
            {
                case 4: format(string, sizeof(string), "You spawned a barrel (ID: %d).", lootid);
                case 5: format(string, sizeof(string), "You spawned a crate (ID: %d).", lootid);
                case 6: format(string, sizeof(string), "You spawned a military crate (ID: %d).", lootid);
            }

            SendClientMessage(playerid, COLOR_GREEN, string);
        }
        else
        {
            SendClientMessage(playerid, COLOR_RED, "Failed to spawn loot container. Maximum containers reached.");
        }
    }

    return 1;
}

CMD:restart(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 3)
        return SendClientMessage(playerid, COLOR_RED, "You are not a level 3+ administrator!");

    // Save all players' data
    foreach(new i : Player)
    {
        SavePlayerData(i);
    }

    // Save all buildings
    SaveAllBuildings();

    // Announce restart
    SendClientMessageToAll(COLOR_RED, "SERVER RESTART: The server is being restarted by an administrator!");
    SendClientMessageToAll(COLOR_RED, "Please reconnect in a few moments.");

    // Kick all players
    foreach(new i : Player)
    {
        Kick(i);
    }

    // Restart the gamemode
    GameModeExit();

    return 1;
}

// Custom functions
ResetPlayerData(playerid)
{
    PlayerInfo[playerid][pID] = 0;
    GetPlayerName(playerid, PlayerInfo[playerid][pName], MAX_PLAYER_NAME);
    PlayerInfo[playerid][pPassword][0] = '\0';
    PlayerInfo[playerid][pAdmin] = 0;
    PlayerInfo[playerid][pKills] = 0;
    PlayerInfo[playerid][pDeaths] = 0;
    PlayerInfo[playerid][pHealth] = 100.0;
    PlayerInfo[playerid][pArmor] = 0.0;
    PlayerInfo[playerid][pHunger] = 100.0;
    PlayerInfo[playerid][pThirst] = 100.0;
    PlayerInfo[playerid][pRadiation] = 0.0;

    for(new i = 0; i < 5; i++)
    {
        PlayerInfo[playerid][pMaterials][i] = 0;
    }

    for(new i = 0; i < 30; i++)
    {
        PlayerInfo[playerid][pInventory][i] = 0;
        PlayerInfo[playerid][pInventoryAmount][i] = 0;
    }

    PlayerInfo[playerid][pLastX] = 0.0;
    PlayerInfo[playerid][pLastY] = 0.0;
    PlayerInfo[playerid][pLastZ] = 0.0;
    PlayerInfo[playerid][pInterior] = 0;
    PlayerInfo[playerid][pVirtualWorld] = 0;
    PlayerInfo[playerid][pSpawnPoint] = 0;
    PlayerInfo[playerid][pBuildingMode] = 0;
    PlayerInfo[playerid][pBuildingType] = 0;
    PlayerInfo[playerid][pBuildingRotation] = 0;
    PlayerInfo[playerid][pLootingID] = -1;
    PlayerInfo[playerid][pHasMap] = 0;
    PlayerInfo[playerid][pLastLogin] = 0;
    PlayerInfo[playerid][pRegisterDate] = 0;
    PlayerInfo[playerid][pPlaytime] = 0;
    PlayerInfo[playerid][pSleeping] = 0;

    return 1;
}

ResetPlayerInventory(playerid)
{
    for(new i = 0; i < 30; i++)
    {
        PlayerInfo[playerid][pInventory][i] = 0;
        PlayerInfo[playerid][pInventoryAmount][i] = 0;
    }

    for(new i = 0; i < 5; i++)
    {
        PlayerInfo[playerid][pMaterials][i] = 0;
    }

    return 1;
}

SavePlayerData(playerid)
{
    if(PlayerInfo[playerid][pID] == 0) return 0;

    new query[512];
    new Float:health;
    GetPlayerHealth(playerid, health);
    PlayerInfo[playerid][pHealth] = health;

    new Float:armour;
    GetPlayerArmour(playerid, armour);
    PlayerInfo[playerid][pArmor] = armour;

    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    PlayerInfo[playerid][pLastX] = x;
    PlayerInfo[playerid][pLastY] = y;
    PlayerInfo[playerid][pLastZ] = z;

    PlayerInfo[playerid][pInterior] = GetPlayerInterior(playerid);
    PlayerInfo[playerid][pVirtualWorld] = GetPlayerVirtualWorld(playerid);

    mysql_format(g_SQL, query, sizeof(query),
        "UPDATE players SET health = %.1f, armor = %.1f, hunger = %.1f, thirst = %.1f, radiation = %.1f, wood = %d, stone = %d, metal = %d, cloth = %d, fuel = %d, lastX = %.1f, lastY = %.1f, lastZ = %.1f, interior = %d, virtualworld = %d, spawnpoint = %d, hasmap = %d, kills = %d, deaths = %d, lastlogin = %d, playtime = %d WHERE id = %d",
        PlayerInfo[playerid][pHealth],
        PlayerInfo[playerid][pArmor],
        PlayerInfo[playerid][pHunger],
        PlayerInfo[playerid][pThirst],
        PlayerInfo[playerid][pRadiation],
        PlayerInfo[playerid][pMaterials][0],
        PlayerInfo[playerid][pMaterials][1],
        PlayerInfo[playerid][pMaterials][2],
        PlayerInfo[playerid][pMaterials][3],
        PlayerInfo[playerid][pMaterials][4],
        PlayerInfo[playerid][pLastX],
        PlayerInfo[playerid][pLastY],
        PlayerInfo[playerid][pLastZ],
        PlayerInfo[playerid][pInterior],
        PlayerInfo[playerid][pVirtualWorld],
        PlayerInfo[playerid][pSpawnPoint],
        PlayerInfo[playerid][pHasMap],
        PlayerInfo[playerid][pKills],
        PlayerInfo[playerid][pDeaths],
        gettime(),
        PlayerInfo[playerid][pPlaytime],
        PlayerInfo[playerid][pID]
    );
    mysql_tquery(g_SQL, query);

    // Save inventory
    mysql_format(g_SQL, query, sizeof(query), "DELETE FROM inventory WHERE player_id = %d", PlayerInfo[playerid][pID]);
    mysql_tquery(g_SQL, query);

    for(new i = 0; i < 30; i++)
    {
        if(PlayerInfo[playerid][pInventory][i] > 0)
        {
            mysql_format(g_SQL, query, sizeof(query),
                "INSERT INTO inventory (player_id, slot, item_id, amount) VALUES (%d, %d, %d, %d)",
                PlayerInfo[playerid][pID],
                i,
                PlayerInfo[playerid][pInventory][i],
                PlayerInfo[playerid][pInventoryAmount][i]
            );
            mysql_tquery(g_SQL, query);
        }
    }

    return 1;
}

public OnPlayerDataCheck(playerid)
{
    new rows;
    cache_get_row_count(rows);
    if(rows)
        ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "Please enter your password:", "Login", "Quit");
    else
        ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Register", "Please create a password for your account (min 6 chars):", "Register", "Quit");

    return 1;
}

forward OnPlayerLogin(playerid);
public OnPlayerLogin(playerid)
{
    new rows;
    cache_get_row_count(rows);
    if(rows)
    {
        new id, admin, kills, deaths, wood, stone, metal, cloth, fuel, interior, vworld, spawnpoint, hasmap, lastlogin, regdate, playtime;
        new Float:health, Float:armor, Float:hunger, Float:thirst, Float:radiation, Float:lastX, Float:lastY, Float:lastZ;

        cache_get_value_name_int(0, "id", id);
        cache_get_value_name_int(0, "admin", admin);
        cache_get_value_name_int(0, "kills", kills);
        cache_get_value_name_int(0, "deaths", deaths);
        cache_get_value_name_float(0, "health", health);
        cache_get_value_name_float(0, "armor", armor);
        cache_get_value_name_float(0, "hunger", hunger);
        cache_get_value_name_float(0, "thirst", thirst);
        cache_get_value_name_float(0, "radiation", radiation);
        cache_get_value_name_int(0, "wood", wood);
        cache_get_value_name_int(0, "stone", stone);
        cache_get_value_name_int(0, "metal", metal);
        cache_get_value_name_int(0, "cloth", cloth);
        cache_get_value_name_int(0, "fuel", fuel);
        cache_get_value_name_float(0, "lastX", lastX);
        cache_get_value_name_float(0, "lastY", lastY);
        cache_get_value_name_float(0, "lastZ", lastZ);
        cache_get_value_name_int(0, "interior", interior);
        cache_get_value_name_int(0, "virtualworld", vworld);
        cache_get_value_name_int(0, "spawnpoint", spawnpoint);
        cache_get_value_name_int(0, "hasmap", hasmap);
        cache_get_value_name_int(0, "lastlogin", lastlogin);
        cache_get_value_name_int(0, "registerdate", regdate);
        cache_get_value_name_int(0, "playtime", playtime);

        PlayerInfo[playerid][pID] = id;
        PlayerInfo[playerid][pAdmin] = admin;
        PlayerInfo[playerid][pKills] = kills;
        PlayerInfo[playerid][pDeaths] = deaths;
        PlayerInfo[playerid][pHealth] = health;
        PlayerInfo[playerid][pArmor] = armor;
        PlayerInfo[playerid][pHunger] = hunger;
        PlayerInfo[playerid][pThirst] = thirst;
        PlayerInfo[playerid][pRadiation] = radiation;
        PlayerInfo[playerid][pMaterials][0] = wood;
        PlayerInfo[playerid][pMaterials][1] = stone;
        PlayerInfo[playerid][pMaterials][2] = metal;
        PlayerInfo[playerid][pMaterials][3] = cloth;
        PlayerInfo[playerid][pMaterials][4] = fuel;
        PlayerInfo[playerid][pLastX] = lastX;
        PlayerInfo[playerid][pLastY] = lastY;
        PlayerInfo[playerid][pLastZ] = lastZ;
        PlayerInfo[playerid][pInterior] = interior;
        PlayerInfo[playerid][pVirtualWorld] = vworld;
        PlayerInfo[playerid][pSpawnPoint] = spawnpoint;
        PlayerInfo[playerid][pHasMap] = hasmap;
        PlayerInfo[playerid][pLastLogin] = lastlogin;
        PlayerInfo[playerid][pRegisterDate] = regdate;
        PlayerInfo[playerid][pPlaytime] = playtime;

        SendClientMessage(playerid, COLOR_GREEN, "Successfully logged in!");
        new query[128];
        mysql_format(g_SQL, query, sizeof(query), "SELECT * FROM inventory WHERE player_id = %d", PlayerInfo[playerid][pID]);
        mysql_tquery(g_SQL, query, "OnInventoryLoad", "i", playerid);
    }
    else
    {
        SendClientMessage(playerid, COLOR_RED, "Invalid password!");
        ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "Please enter your password:", "Login", "Quit");
    }
    return 1;
}

public OnPlayerRegister(playerid)
{
    PlayerInfo[playerid][pID] = cache_insert_id();
    PlayerInfo[playerid][pAdmin] = 0;
    PlayerInfo[playerid][pKills] = 0;
    PlayerInfo[playerid][pDeaths] = 0;
    PlayerInfo[playerid][pHealth] = 100.0;
    PlayerInfo[playerid][pArmor] = 0.0;
    PlayerInfo[playerid][pHunger] = 100.0;
    PlayerInfo[playerid][pThirst] = 100.0;
    PlayerInfo[playerid][pRadiation] = 0.0;
    PlayerInfo[playerid][pMaterials][0] = 0;
    PlayerInfo[playerid][pMaterials][1] = 0;
    PlayerInfo[playerid][pMaterials][2] = 0;
    PlayerInfo[playerid][pMaterials][3] = 0;
    PlayerInfo[playerid][pMaterials][4] = 0;
    PlayerInfo[playerid][pLastX] = 0.0;
    PlayerInfo[playerid][pLastY] = 0.0;
    PlayerInfo[playerid][pLastZ] = 0.0;
    PlayerInfo[playerid][pInterior] = 0;
    PlayerInfo[playerid][pVirtualWorld] = 0;
    PlayerInfo[playerid][pSpawnPoint] = 0;
    PlayerInfo[playerid][pHasMap] = 0;
    PlayerInfo[playerid][pLastLogin] = gettime();
    PlayerInfo[playerid][pRegisterDate] = gettime();
    PlayerInfo[playerid][pPlaytime] = 0;

    SendClientMessage(playerid, COLOR_GREEN, "Successfully registered!");
    return 1;
}

public OnInventoryLoad(playerid)
{
    new rows;
    cache_get_row_count(rows);

    for(new i = 0; i < rows; i++)
    {
        new slot, item_id, amount;

        cache_get_value_name_int(i, "slot", slot);
        cache_get_value_name_int(i, "item_id", item_id);
        cache_get_value_name_int(i, "amount", amount);

        PlayerInfo[playerid][pInventory][slot] = item_id;
        PlayerInfo[playerid][pInventoryAmount][slot] = amount;
    }

    return 1;
}

GivePlayerBasicKit(playerid)
{
    // Give basic tools and supplies to new players
    PlayerInfo[playerid][pInventory][0] = ITEM_HATCHET;
    PlayerInfo[playerid][pInventoryAmount][0] = 1;

    PlayerInfo[playerid][pInventory][1] = ITEM_PICKAXE;
    PlayerInfo[playerid][pInventoryAmount][1] = 1;

    PlayerInfo[playerid][pInventory][2] = ITEM_BANDAGE;
    PlayerInfo[playerid][pInventoryAmount][2] = 3;

    PlayerInfo[playerid][pInventory][3] = ITEM_FOOD;
    PlayerInfo[playerid][pInventoryAmount][3] = 2;

    PlayerInfo[playerid][pInventory][4] = ITEM_WATER;
    PlayerInfo[playerid][pInventoryAmount][4] = 2;

    PlayerInfo[playerid][pInventory][5] = ITEM_SLEEPING_BAG;
    PlayerInfo[playerid][pInventoryAmount][5] = 1;

    SendClientMessage(playerid, COLOR_GREEN, "You received a starter kit with basic tools and supplies.");

    return 1;
}

ShowPlayerInventory(playerid)
{
    new string[1024], itemCount = 0;
    format(string, sizeof(string), "Inventory:\n");

    for(new i = 0; i < 30; i++)
    {
        if(PlayerInfo[playerid][pInventory][i] > 0)
        {
            new itemName[32];
            GetItemName(PlayerInfo[playerid][pInventory][i], itemName);

            format(string, sizeof(string), "%s%d. %s (x%d)\n", string, i+1, itemName, PlayerInfo[playerid][pInventoryAmount][i]);
            itemCount++;
        }
        else
        {
            format(string, sizeof(string), "%s%d. Empty\n", string, i+1);
        }
    }

    if(itemCount == 0)
    {
        format(string, sizeof(string), "%sYour inventory is empty.\n", string);
    }

    ShowPlayerDialog(playerid, DIALOG_INVENTORY, DIALOG_STYLE_LIST, "Inventory", string, "Use", "Close");

    return 1;
}

ShowCraftingMenu(playerid)
{
    new string[1024];
    format(string, sizeof(string), "Crafting Menu:\n");
    format(string, sizeof(string), "%s1. Hatchet (50 Wood, 25 Metal)\n", string);
    format(string, sizeof(string), "%s2. Pickaxe (50 Wood, 40 Metal)\n", string);
    format(string, sizeof(string), "%s3. Hammer (100 Wood, 50 Metal)\n", string);
    format(string, sizeof(string), "%s4. Bandage (10 Cloth)\n", string);
    format(string, sizeof(string), "%s5. Medkit (50 Cloth, 20 Metal)\n", string);
    format(string, sizeof(string), "%s6. Sleeping Bag (100 Cloth, 30 Wood)\n", string);
    format(string, sizeof(string), "%s7. Furnace (500 Stone, 100 Wood, 50 Metal)\n", string);
    format(string, sizeof(string), "%s8. Campfire (200 Wood, 20 Stone)\n", string);
    format(string, sizeof(string), "%s9. Wooden Door (200 Wood, 50 Metal)\n", string);
    format(string, sizeof(string), "%s10. Metal Door (300 Metal, 50 Wood)\n", string);
    format(string, sizeof(string), "%s11. Code Lock (100 Metal)\n", string);
    format(string, sizeof(string), "%s12. Pistol (150 Metal, 50 Wood, 20 Gunpowder)\n", string);
    format(string, sizeof(string), "%s13. Shotgun (200 Metal, 100 Wood, 30 Gunpowder)\n", string);
    format(string, sizeof(string), "%s14. Rifle (300 Metal, 150 Wood, 50 Gunpowder)\n", string);
    format(string, sizeof(string), "%s15. Pistol Ammo (20 Metal, 10 Gunpowder)\n", string);
    format(string, sizeof(string), "%s16. Shotgun Ammo (30 Metal, 15 Gunpowder)\n", string);
    format(string, sizeof(string), "%s17. Rifle Ammo (40 Metal, 20 Gunpowder)\n", string);
    format(string, sizeof(string), "%s18. Gunpowder (30 Charcoal, 20 Sulfur)\n", string);
    format(string, sizeof(string), "%s19. Explosive (100 Gunpowder, 50 Metal, 20 Cloth)\n", string);
    format(string, sizeof(string), "%s20. C4 (5 Explosive, 100 Metal, 60 Cloth)\n", string);

    ShowPlayerDialog(playerid, DIALOG_CRAFTING, DIALOG_STYLE_LIST, "Crafting Menu", string, "Craft", "Close");

    return 1;
}

ShowBuildingMenu(playerid)
{
    // Check if player has hammer
    new bool:hasHammer = false;

    for(new i = 0; i < 30; i++)
    {
        if(PlayerInfo[playerid][pInventory][i] == ITEM_HAMMER)
        {
            hasHammer = true;
            break;
        }
    }

    if(!hasHammer)
    {
        SendClientMessage(playerid, COLOR_RED, "You need a hammer to build! Craft one first.");
        return 0;
    }

    new string[512];
    format(string, sizeof(string), "Building Menu:\n");
    format(string, sizeof(string), "%s1. Foundation (500 Wood, 300 Stone)\n", string);
    format(string, sizeof(string), "%s2. Wall (200 Wood, 100 Stone)\n", string);
    format(string, sizeof(string), "%s3. Doorway (180 Wood, 90 Stone)\n", string);
    format(string, sizeof(string), "%s4. Floor (150 Wood, 80 Stone)\n", string);
    format(string, sizeof(string), "%s5. Ceiling (150 Wood, 80 Stone)\n", string);
    format(string, sizeof(string), "%s6. Stairs (250 Wood, 150 Stone)\n", string);
    format(string, sizeof(string), "%s7. Window (160 Wood, 80 Stone)\n", string);
    format(string, sizeof(string), "%s8. Storage Box (100 Wood, 20 Metal)\n", string);

    ShowPlayerDialog(playerid, DIALOG_BUILDING, DIALOG_STYLE_LIST, "Building Menu", string, "Build", "Close");

    return 1;
}

ShowHelpMenu(playerid)
{
    new string[1024];
    format(string, sizeof(string), "Help Menu - "SERVER_NAME"\n\n");
    format(string, sizeof(string), "%sBasic Controls:\n", string);
    format(string, sizeof(string), "%s- Y: Open Inventory\n", string);
    format(string, sizeof(string), "%s- N: Open Crafting Menu\n", string);
    format(string, sizeof(string), "%s- H: Show Help Menu\n", string);
    format(string, sizeof(string), "%s- Left Click: Hit/Gather Resources\n", string);
    format(string, sizeof(string), "%s- Right Click: Interact/Place Building\n\n", string);

    format(string, sizeof(string), "%sBasic Commands:\n", string);
    format(string, sizeof(string), "%s- /inventory - View your inventory\n", string);
    format(string, sizeof(string), "%s- /craft - Open crafting menu\n", string);
    format(string, sizeof(string), "%s- /build - Open building menu\n", string);
    format(string, sizeof(string), "%s- /drop [slot] [amount] - Drop item on ground\n", string);
    format(string, sizeof(string), "%s- /stats - View your statistics\n", string);
    format(string, sizeof(string), "%s- /resources - View your resources\n", string);
    format(string, sizeof(string), "%s- /menu - Show main menu\n", string);
    format(string, sizeof(string), "%s- /suicide - Kill yourself\n\n", string);

    format(string, sizeof(string), "%sSurvival Tips:\n", string);
    format(string, sizeof(string), "%s- Gather wood and stone to build a base\n", string);
    format(string, sizeof(string), "%s- Always keep food and water with you\n", string);
    format(string, sizeof(string), "%s- Avoid radiation zones without proper protection\n", string);
    format(string, sizeof(string), "%s- Place a sleeping bag to set your spawn point\n", string);
    format(string, sizeof(string), "%s- Lock your doors to prevent raiders\n", string);
    format(string, sizeof(string), "%s- Team up with other players for better chances of survival\n", string);

    ShowPlayerDialog(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "Help Menu", string, "Close", "");

    return 1;
}

ShowPlayerMenu(playerid)
{
    new string[256];
    format(string, sizeof(string), "Player Menu:\n");
    format(string, sizeof(string), "%s1. View Statistics\n", string);
    format(string, sizeof(string), "%s2. Inventory\n", string);
    format(string, sizeof(string), "%s3. Crafting\n", string);
    format(string, sizeof(string), "%s4. Building\n", string);
    format(string, sizeof(string), "%s5. Help\n", string);

    if(PlayerInfo[playerid][pAdmin] >= 1)
    {
        format(string, sizeof(string), "%s6. Admin Panel\n", string);
    }

    ShowPlayerDialog(playerid, DIALOG_PLAYER_MENU, DIALOG_STYLE_LIST, "Player Menu", string, "Select", "Close");

    return 1;
}

ShowAdminMenu(playerid)
{
    if(PlayerInfo[playerid][pAdmin] < 1) return 0;

    new string[512];
    format(string, sizeof(string), "Admin Menu - Level %d\n", PlayerInfo[playerid][pAdmin]);
    format(string, sizeof(string), "%s1. Teleport to Coordinates\n", string);
    format(string, sizeof(string), "%s2. Spawn Item\n", string);
    format(string, sizeof(string), "%s3. Spawn Resource\n", string);
    format(string, sizeof(string), "%s4. Kill Player\n", string);
    format(string, sizeof(string), "%s5. Reset Server\n", string);
    format(string, sizeof(string), "%s6. Set Admin Level\n", string);

    ShowPlayerDialog(playerid, DIALOG_ADMIN, DIALOG_STYLE_LIST, "Admin Menu", string, "Select", "Close");

    return 1;
}

ShowLootContainer(playerid, lootid)
{
    if(lootid < 0 || lootid >= LootCount || !LootInfo[lootid][lootActive])
    {
        SendClientMessage(playerid, COLOR_RED, "This container is no longer available!");
        return 0;
    }

    new string[512];
    new containerType[32];

    switch(LootInfo[lootid][lootType])
    {
        case 0: containerType = "Barrel";
        case 1: containerType = "Crate";
        case 2: containerType = "Military Crate";
        case 3: containerType = "Elite Crate";
        case 4: containerType = "Dead Body";
        default: containerType = "Container";
    }

    format(string, sizeof(string), "%s Contents:\n", containerType);

    for(new i = 0; i < 10; i++)
    {
        if(LootInfo[lootid][lootItems][i] > 0)
        {
            new itemName[32];
            GetItemName(LootInfo[lootid][lootItems][i], itemName);

            format(string, sizeof(string), "%s%d. %s (x%d)\n", string, i+1, itemName, LootInfo[lootid][lootItemsAmount][i]);
        }
        else
        {
            format(string, sizeof(string), "%s%d. Empty\n", string, i+1);
        }
    }

    PlayerInfo[playerid][pLootingID] = lootid;
    ShowPlayerDialog(playerid, DIALOG_LOOT, DIALOG_STYLE_LIST, containerType, string, "Take", "Close");

    return 1;
}

UpdatePlayerHUDInfo(playerid)
{
    // Update progress bars
    SetPlayerProgressBarValue(PlayerInfo[playerid][pProgressBar], PlayerInfo[playerid][pHealth]);
    SetPlayerProgressBarValue(PlayerInfo[playerid][pHungerBar], PlayerInfo[playerid][pHunger]);
    SetPlayerProgressBarValue(PlayerInfo[playerid][pThirstBar], PlayerInfo[playerid][pThirst]);
    SetPlayerProgressBarValue(PlayerInfo[playerid][pRadiationBar], PlayerInfo[playerid][pRadiation]);

    // Set progress bar colors based on value
    if(PlayerInfo[playerid][pHealth] > 75.0)
        SetPlayerProgressBarColour(PlayerInfo[playerid][pProgressBar], COLOR_GREEN);
    else if(PlayerInfo[playerid][pHealth] > 25.0)
        SetPlayerProgressBarColour(PlayerInfo[playerid][pProgressBar], COLOR_YELLOW);
    else
        SetPlayerProgressBarColour(PlayerInfo[playerid][pProgressBar], COLOR_RED);

    if(PlayerInfo[playerid][pHunger] > 75.0)
        SetPlayerProgressBarColour(PlayerInfo[playerid][pHungerBar], COLOR_GREEN);
    else if(PlayerInfo[playerid][pHunger] > 25.0)
        SetPlayerProgressBarColour(PlayerInfo[playerid][pHungerBar], COLOR_ORANGE);
    else
        SetPlayerProgressBarColour(PlayerInfo[playerid][pHungerBar], COLOR_RED);

    if(PlayerInfo[playerid][pThirst] > 75.0)
        SetPlayerProgressBarColour(PlayerInfo[playerid][pThirstBar], COLOR_BLUE);
    else if(PlayerInfo[playerid][pThirst] > 25.0)
        SetPlayerProgressBarColour(PlayerInfo[playerid][pThirstBar], COLOR_PURPLE);
    else
        SetPlayerProgressBarColour(PlayerInfo[playerid][pThirstBar], COLOR_RED);

    // Update text drawn info
    new string[128];
    format(string, sizeof(string), "Health: %.1f", PlayerInfo[playerid][pHealth]);
    PlayerTextDrawSetString(playerid, PlayerInfo[playerid][pProgressBar], string);

    format(string, sizeof(string), "Hunger: %.1f", PlayerInfo[playerid][pHunger]);
    PlayerTextDrawSetString(playerid, PlayerInfo[playerid][pHungerBar], string);

    format(string, sizeof(string), "Thirst: %.1f", PlayerInfo[playerid][pThirst]);
    PlayerTextDrawSetString(playerid, PlayerInfo[playerid][pThirstBar], string);

    format(string, sizeof(string), "Radiation: %.1f", PlayerInfo[playerid][pRadiation]);
    PlayerTextDrawSetString(playerid, PlayerInfo[playerid][pRadiationBar], string);

    return 1;
}

CreateRadiationZones()
{
    // Create radiation zones in dangerous areas
    RadiationZones[0][radX] = 2000.0;
    RadiationZones[0][radY] = 2000.0;
    RadiationZones[0][radZ] = 0.0;
    RadiationZones[0][radRadius] = 500.0;
    RadiationZones[0][radLevel] = 3;

    RadiationZones[1][radX] = -2000.0;
    RadiationZones[1][radY] = 1500.0;
    RadiationZones[1][radZ] = 0.0;
    RadiationZones[1][radRadius] = 300.0;
    RadiationZones[1][radLevel] = 2;

    RadiationZones[2][radX] = 0.0;
    RadiationZones[2][radY] = -2000.0;
    RadiationZones[2][radZ] = 0.0;
    RadiationZones[2][radRadius] = 400.0;
    RadiationZones[2][radLevel] = 4;

    RadiationZoneCount = 3;

    // Create map icons for radiation zones
    for(new i = 0; i < RadiationZoneCount; i++)
    {
        CreateDynamicMapIcon(RadiationZones[i][radX], RadiationZones[i][radY], RadiationZones[i][radZ], 23, 0, -1, -1, -1, 1000.0);
    }

    return 1;
}

public CheckRadiationExposure(playerid)
{
    // Check if player is in a radiation zone
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    new bool:inRadZone = false;
    new _radLevel = 0;

    for(new i = 0; i < RadiationZoneCount; i++)
    {
        new Float:distance = GetDistanceBetweenPoints3D(x, y, z, RadiationZones[i][radX], RadiationZones[i][radY], RadiationZones[i][radZ]);

        if(distance < RadiationZones[i][radRadius])
        {
            inRadZone = true;
            _radLevel = RadiationZones[i][radLevel];
            break;
        }
    }

    if(inRadZone)
    {
        // Check if player has radiation protection
        new bool:hasProtection = false;

        // Check if player is wearing radiation suit (specific skin ID)
        if(GetPlayerSkin(playerid) == 285) // Hazmat suit skin
        {
            hasProtection = true;
        }

        if(!hasProtection)
        {
            // Apply radiation damage based on level
            PlayerInfo[playerid][pRadiation] += 0.1 * _radLevel;

            if(PlayerInfo[playerid][pRadiation] > 100.0)
                PlayerInfo[playerid][pRadiation] = 100.0;

            // Apply health damage at high radiation
            if(PlayerInfo[playerid][pRadiation] > 50.0)
            {
                new Float:health;
                GetPlayerHealth(playerid, health);
                health -= 0.5 * (PlayerInfo[playerid][pRadiation] / 50.0);

                if(health <= 0.0)
                {
                    SetPlayerHealth(playerid, 0.0);
                }
                else
                {
                    SetPlayerHealth(playerid, health);
                    PlayerInfo[playerid][pHealth] = health;
                }
            }

            // Warn player about radiation
            if(GetTickCount() % 5000 < 50) // Only warn every ~5 seconds
            {
                new string[128];
                format(string, sizeof(string), "WARNING: You are in a radiation zone (Level %d)! Your radiation level: %.1f", radLevel, PlayerInfo[playerid][pRadiation]);
                SendClientMessage(playerid, COLOR_YELLOW, string);
            }
        }
    }
    else
    {
        // Slowly reduce radiation when not in zone
        if(PlayerInfo[playerid][pRadiation] > 0.0)
        {
            PlayerInfo[playerid][pRadiation] -= 0.05;

            if(PlayerInfo[playerid][pRadiation] < 0.0)
                PlayerInfo[playerid][pRadiation] = 0.0;
        }
    }

    return 1;
}

SpawnAllResources()
{
    print("Spawning resources...");

    // Spawn trees (wood)
    for(new i = 0; i < 400; i++)
    {
        new Float:x = -3000.0 + float(random(6000));
        new Float:y = -3000.0 + float(random(6000));
        new Float:z = 0.0;

        // Avoid spawning in water (simple check)
        if(z < 5.0) z = 5.0;

        CreateResourceAtPos(0, x, y, z);
    }

    // Spawn rocks (stone)
    for(new i = 0; i < 300; i++)
    {
        new Float:x = -3000.0 + float(random(6000));
        new Float:y = -3000.0 + float(random(6000));
        new Float:z = 0.0;

        // Avoid spawning in water (simple check)
        if(z < 5.0) z = 5.0;

        CreateResourceAtPos(1, x, y, z);
    }

    // Spawn metal nodes
    for(new i = 0; i < 200; i++)
    {
        new Float:x = -3000.0 + float(random(6000));
        new Float:y = -3000.0 + float(random(6000));
        new Float:z = 0.0;

        // Avoid spawning in water (simple check)
        if(z < 5.0) z = 5.0;

        CreateResourceAtPos(2, x, y, z);
    }

    // Spawn hemp plants (cloth)
    for(new i = 0; i < 150; i++)
    {
        new Float:x = -3000.0 + float(random(6000));
        new Float:y = -3000.0 + float(random(6000));
        new Float:z = 0.0;

        // Avoid spawning in water (simple check)
        if(z < 5.0) z = 5.0;

        CreateResourceAtPos(3, x, y, z);
    }

    printf("Spawned %d resources", ResourceCount);

    return 1;
}

CreateResourceAtPos(type, Float:x, Float:y, Float:z)
{
    if(ResourceCount >= MAX_RESOURCES) return -1;

    ResourceInfo[ResourceCount][resType] = type;
    ResourceInfo[ResourceCount][resX] = x;
    ResourceInfo[ResourceCount][resY] = y;
    ResourceInfo[ResourceCount][resZ] = z;
    ResourceInfo[ResourceCount][resRX] = 0.0;
    ResourceInfo[ResourceCount][resRY] = 0.0;
    ResourceInfo[ResourceCount][resRZ] = float(random(360));

    switch(type)
    {
        case 0: // Wood
        {
            ResourceInfo[ResourceCount][resAmount] = 100 + random(200);
            ResourceInfo[ResourceCount][resHealth] = 100;
            ResourceInfo[ResourceCount][resObject] = CreateDynamicObject(618, x, y, z, 0.0, 0.0, float(random(360)), -1, -1, -1, 300.0);
        }
        case 1: // Stone
        {
            ResourceInfo[ResourceCount][resAmount] = 80 + random(120);
            ResourceInfo[ResourceCount][resHealth] = 150;
            ResourceInfo[ResourceCount][resObject] = CreateDynamicObject(3929, x, y, z, 0.0, 0.0, float(random(360)), -1, -1, -1, 300.0);
        }
        case 2: // Metal
        {
            ResourceInfo[ResourceCount][resAmount] = 50 + random(100);
            ResourceInfo[ResourceCount][resHealth] = 200;
            ResourceInfo[ResourceCount][resObject] = CreateDynamicObject(3930, x, y, z, 0.0, 0.0, float(random(360)), -1, -1, -1, 300.0);
        }
        case 3: // Hemp/Cloth
        {
            ResourceInfo[ResourceCount][resAmount] = 30 + random(50);
            ResourceInfo[ResourceCount][resHealth] = 50;
            ResourceInfo[ResourceCount][resObject] = CreateDynamicObject(19473, x, y, z, 0.0, 0.0, float(random(360)), -1, -1, -1, 300.0);
        }
    }

    ResourceInfo[ResourceCount][resActive] = true;
    ResourceInfo[ResourceCount][resRespawnTime] = 300 + random(300); // 5-10 minutes

    ResourceCount++;

    return ResourceCount - 1;
}

GatherResource(playerid)
{
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    // Find nearest resource
    new resourceid = -1;
    new Float:minDist = 3.0;

    for(new i = 0; i < ResourceCount; i++)
    {
        if(!ResourceInfo[i][resActive]) continue;

        new Float:dist = GetDistanceBetweenPoints3D(x, y, z, ResourceInfo[i][resX], ResourceInfo[i][resY], ResourceInfo[i][resZ]);
        if(dist < minDist)
        {
            minDist = dist;
            resourceid = i;
        }
    }

    if(resourceid == -1)
    {
        return 0;
    }

    // Check if player has the right tool in inventory
    new bool:hasTool = false;
    new toolDamage = 1;

    switch(ResourceInfo[resourceid][resType])
    {
        case 0: // Wood - need hatchet
        {
            for(new i = 0; i < 30; i++)
            {
                if(PlayerInfo[playerid][pInventory][i] == ITEM_HATCHET) // Hatchet
                {
                    hasTool = true;
                    toolDamage = 10;
                    break;
                }
            }
        }
        case 1, 2: // Stone/Metal - need pickaxe
        {
            for(new i = 0; i < 30; i++)
            {
                if(PlayerInfo[playerid][pInventory][i] == ITEM_PICKAXE) // Pickaxe
                {
                    hasTool = true;
                    toolDamage = 8;
                    break;
                }
            }
        }
        case 3: // Hemp - can gather with hands
        {
            hasTool = true;
            toolDamage = 5;
        }
    }

    // If no tool, can still gather but at reduced efficiency
    if(!hasTool)
    {
        toolDamage = 1;
    }

    // Hit resource
    UpdateResourceHealth(resourceid, playerid, toolDamage);

    // Show animation
    ApplyAnimation(playerid, "BASEBALL", "Bat_4", 4.1, 0, 0, 0, 0, 0, 1);

    return 1;
}

public UpdateResourceHealth(resourceid, playerid, damage)
{
    if(resourceid < 0 || resourceid >= ResourceCount) return 0;
    if(!ResourceInfo[resourceid][resActive]) return 0;

    // Reduce resource health
    ResourceInfo[resourceid][resHealth] -= damage;

    if(ResourceInfo[resourceid][resHealth] <= 0)
    {
        // Resource depleted, give rewards
        new amount;

        switch(ResourceInfo[resourceid][resType])
        {
            case 0: // Wood
            {
                amount = 5 + random(10);
                PlayerInfo[playerid][pMaterials][0] += amount;

                // Small chance to get cloth from trees
                if(random(10) == 0)
                {
                    PlayerInfo[playerid][pMaterials][3] += 1 + random(3);
                    SendClientMessage(playerid, COLOR_GREEN, "You found some cloth in the tree!");
                }
            }
            case 1: // Stone
            {
                amount = 5 + random(8);
                PlayerInfo[playerid][pMaterials][1] += amount;

                // Small chance to get metal from stone
                if(random(5) == 0)
                {
                    PlayerInfo[playerid][pMaterials][2] += 1 + random(2);
                    SendClientMessage(playerid, COLOR_GREEN, "You found some metal ore in the rock!");
                }
            }
            case 2: // Metal
            {
                amount = 3 + random(5);
                PlayerInfo[playerid][pMaterials][2] += amount;

                // Chance to get sulfur or high quality metal
                if(random(3) == 0)
                {
                    new slot = FindFreeInventorySlot(playerid, ITEM_SULFUR);
                    if(slot != -1)
                    {
                        if(PlayerInfo[playerid][pInventory][slot] == 0)
                        {
                            PlayerInfo[playerid][pInventory][slot] = ITEM_SULFUR;
                            PlayerInfo[playerid][pInventoryAmount][slot] = 1 + random(3);
                        }
                        else
                        {
                            PlayerInfo[playerid][pInventoryAmount][slot] += 1 + random(3);
                        }
                        SendClientMessage(playerid, COLOR_GREEN, "You found some sulfur in the ore!");
                    }
                }
            }
            case 3: // Hemp
            {
                amount = 5 + random(10);
                PlayerInfo[playerid][pMaterials][3] += amount; // Cloth
            }
        }

        // Show message
        new message[128];
        new resourceName[10];
        switch(ResourceInfo[resourceid][resType])
        {
            case 0: resourceName = "wood";
            case 1: resourceName = "stone";
            case 2: resourceName = "metal";
            case 3: resourceName = "cloth";
        }

        format(message, sizeof(message), "You gathered %d %s. You now have %d %s.",
            amount,
            resourceName,
            PlayerInfo[playerid][pMaterials][ResourceInfo[resourceid][resType]],
            resourceName
        );
        SendClientMessage(playerid, COLOR_GREEN, message);

        // Remove resource temporarily
        ResourceInfo[resourceid][resActive] = false;
        DestroyDynamicObject(ResourceInfo[resourceid][resObject]);

        // Set respawn timer
        SetTimerEx("RespawnResource", ResourceInfo[resourceid][resRespawnTime] * 1000, false, "i", resourceid);
    }
    else
    {
        // Resource hit but not depleted, give small amount
        if(random(3) == 0) // 1/3 chance to get resource on hit
        {
            new amount = 1 + random(2);
            PlayerInfo[playerid][pMaterials][ResourceInfo[resourceid][resType]] += amount;

            // Show message
            new message[128];
            new resourceName[10];
            switch(ResourceInfo[resourceid][resType])
            {
                case 0: resourceName = "wood";
                case 1: resourceName = "stone";
                case 2: resourceName = "metal";
                case 3: resourceName = "cloth";
            }

            format(message, sizeof(message), "You gathered %d %s.", amount, resourceName);
            SendClientMessage(playerid, COLOR_GREEN, message);
        }
    }

    return 1;
}

public RespawnResource(resourceid)
{
    if(resourceid < 0 || resourceid >= ResourceCount) return 0;

    // Reset resource health
    switch(ResourceInfo[resourceid][resType])
    {
        case 0: ResourceInfo[resourceid][resHealth] = 100;
        case 1: ResourceInfo[resourceid][resHealth] = 150;
        case 2: ResourceInfo[resourceid][resHealth] = 200;
        case 3: ResourceInfo[resourceid][resHealth] = 50;
    }

    // Reset amount
    switch(ResourceInfo[resourceid][resType])
    {
        case 0: ResourceInfo[resourceid][resAmount] = 100 + random(200);
        case 1: ResourceInfo[resourceid][resAmount] = 80 + random(120);
        case 2: ResourceInfo[resourceid][resAmount] = 50 + random(100);
        case 3: ResourceInfo[resourceid][resAmount] = 30 + random(50);
    }

    // Create object
    switch(ResourceInfo[resourceid][resType])
    {
        case 0: // Wood
        {
            ResourceInfo[resourceid][resObject] = CreateDynamicObject(618,
                ResourceInfo[resourceid][resX],
                ResourceInfo[resourceid][resY],
                ResourceInfo[resourceid][resZ],
                ResourceInfo[resourceid][resRX],
                ResourceInfo[resourceid][resRY],
                ResourceInfo[resourceid][resRZ],
                -1, -1, -1, 300.0);
        }
        case 1: // Stone
        {
            ResourceInfo[resourceid][resObject] = CreateDynamicObject(3929,
                ResourceInfo[resourceid][resX],
                ResourceInfo[resourceid][resY],
                ResourceInfo[resourceid][resZ],
                ResourceInfo[resourceid][resRX],
                ResourceInfo[resourceid][resRY],
                ResourceInfo[resourceid][resRZ],
                -1, -1, -1, 300.0);
        }
        case 2: // Metal
        {
            ResourceInfo[resourceid][resObject] = CreateDynamicObject(3930,
                ResourceInfo[resourceid][resX],
                ResourceInfo[resourceid][resY],
                ResourceInfo[resourceid][resZ],
                ResourceInfo[resourceid][resRX],
                ResourceInfo[resourceid][resRY],
                ResourceInfo[resourceid][resRZ],
                -1, -1, -1, 300.0);
        }
        case 3: // Hemp
        {
            ResourceInfo[resourceid][resObject] = CreateDynamicObject(19473,
                ResourceInfo[resourceid][resX],
                ResourceInfo[resourceid][resY],
                ResourceInfo[resourceid][resZ],
                ResourceInfo[resourceid][resRX],
                ResourceInfo[resourceid][resRY],
                ResourceInfo[resourceid][resRZ],
                -1, -1, -1, 300.0);
        }
    }

    ResourceInfo[resourceid][resActive] = true;

    return 1;
}

forward LoadBuildings();
public LoadBuildings()
{
    new query[128];
    mysql_format(g_SQL, query, sizeof(query), "SELECT * FROM buildings");
    mysql_tquery(g_SQL, query, "OnBuildingsLoad", "");

    return 1;
}

public OnBuildingsLoad()
{
    new rows;
    cache_get_row_count(rows);

    printf("Loading %d buildings from database...", rows);

    for(new i = 0; i < rows; i++)
    {
        if(i >= MAX_BUILDINGS) break;

        new id, owner, type, health, maxhealth, locked;
        new Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz;

        cache_get_value_name_int(i, "id", id);
        cache_get_value_name_int(i, "owner", owner);
        cache_get_value_name_int(i, "type", type);
        cache_get_value_name_float(i, "x", x);
        cache_get_value_name_float(i, "y", y);
        cache_get_value_name_float(i, "z", z);
        cache_get_value_name_float(i, "rx", rx);
        cache_get_value_name_float(i, "ry", ry);
        cache_get_value_name_float(i, "rz", rz);
        cache_get_value_name_int(i, "health", health);
        cache_get_value_name_int(i, "maxhealth", maxhealth);
        cache_get_value_name(i, "lockcode", BuildingInfo[i][buildLockCode], 10);
        cache_get_value_name_int(i, "locked", locked);

        BuildingInfo[i][buildID] = id;
        BuildingInfo[i][buildOwner] = owner;
        BuildingInfo[i][buildType] = type;
        BuildingInfo[i][buildX] = x;
        BuildingInfo[i][buildY] = y;
        BuildingInfo[i][buildZ] = z;
        BuildingInfo[i][buildRX] = rx;
        BuildingInfo[i][buildRY] = ry;
        BuildingInfo[i][buildRZ] = rz;
        BuildingInfo[i][buildHealth] = health;
        BuildingInfo[i][buildMaxHealth] = maxhealth;
        BuildingInfo[i][buildLocked] = locked;

        new objectid;
        switch(BuildingInfo[i][buildType])
        {
            case 0: objectid = 19380; // Foundation
            case 1: objectid = 19353; // Wall
            case 2: objectid = 19454; // Doorway
            case 3: objectid = 19302; // Door
            case 4: objectid = 19366; // Floor
            case 5: objectid = 19445; // Ceiling
            case 6: objectid = 19423; // Stairs
            case 7: objectid = 19377; // Window
            case 8: objectid = 2969;  // Chest/Storage
            case 16: objectid = 1279; // Sleeping Bag
            case 17: objectid = 3525; // Furnace
            case 18: objectid = 19632; // Campfire
            default: objectid = 19353; // Default to wall
        }

        BuildingInfo[i][buildObject] = CreateDynamicObject(objectid,
            BuildingInfo[i][buildX],
            BuildingInfo[i][buildY],
            BuildingInfo[i][buildZ],
            BuildingInfo[i][buildRX],
            BuildingInfo[i][buildRY],
            BuildingInfo[i][buildRZ],
            -1, -1);


        if(BuildingInfo[i][buildType] == 8 || BuildingInfo[i][buildType] == 17 || BuildingInfo[i][buildType] == 18)
        {
            for(new j = 0; j < 20; j++)
            {
                BuildingInfo[i][buildItemID][j] = 0;
                BuildingInfo[i][buildItemAmount][j] = 0;
            }

            new itemQuery[128];
            mysql_format(g_SQL, itemQuery, sizeof(itemQuery), "SELECT * FROM building_items WHERE building_id = %d", BuildingInfo[i][buildID]);
            mysql_tquery(g_SQL, itemQuery, "OnBuildingItemsLoad", "i", i);
        }

        BuildingCount++;
    }

    printf("Loaded %d buildings", BuildingCount);

    return 1;
}

forward OnBuildingItemsLoad(buildingid);
public OnBuildingItemsLoad(buildingid)
{
    new rows;
    cache_get_row_count(rows);

    for(new i = 0; i < rows; i++)
    {
        new slot, item_id, amount;


        cache_get_value_name_int(i, "slot", slot);
        cache_get_value_name_int(i, "item_id", item_id);
        cache_get_value_name_int(i, "amount", amount);

        if(slot >= 0 && slot < 20)
        {
            BuildingInfo[buildingid][buildItemID][slot] = item_id;
            BuildingInfo[buildingid][buildItemAmount][slot] = amount;
        }
    }

    return 1;
}

PlaceBuilding(playerid)
{
    if(!PlayerInfo[playerid][pBuildingMode]) return 0;

    new buildingType = PlayerInfo[playerid][pBuildingType];

    // Get position for building
    new Float:x, Float:y, Float:z, Float:angle;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, angle);

    // Calculate position in front of player
    x += (2.0 * floatsin(-angle, degrees));
    y += (2.0 * floatcos(-angle, degrees));

    // Apply rotation if set
    angle += PlayerInfo[playerid][pBuildingRotation];
    if(angle >= 360.0) angle -= 360.0;

    // Find free building slot
    new buildingid = -1;

    for(new i = 0; i < MAX_BUILDINGS; i++)
    {
        if(!IsValidDynamicObject(BuildingInfo[i][buildObject]))
        {
            buildingid = i;
            break;
        }
    }

    if(buildingid == -1)
    {
        SendClientMessage(playerid, COLOR_RED, "Maximum buildings reached on server!");
        PlayerInfo[playerid][pBuildingMode] = 0;
        return 0;
    }

    // Check if placement is valid (not colliding with other buildings)
    for(new i = 0; i < BuildingCount; i++)
    {
        if(IsValidDynamicObject(BuildingInfo[i][buildObject]) &&
           GetDistanceBetweenPoints3D(x, y, z, BuildingInfo[i][buildX], BuildingInfo[i][buildY], BuildingInfo[i][buildZ]) < 1.0)
        {
            SendClientMessage(playerid, COLOR_RED, "Cannot place building here - too close to another structure!");
            return 0;
        }
    }

    // Create building object
    new objectid;
    new maxHealth;

    switch(buildingType)
    {
        case 0: // Foundation
        {
            objectid = 19380;
            maxHealth = 1000;
        }
        case 1: // Wall
        {
            objectid = 19353;
            maxHealth = 500;
        }
        case 2: // Doorway
        {
            objectid = 19454;
            maxHealth = 500;
        }
        case 3: // Door
        {
            objectid = 19302;
            maxHealth = 300;
        }
        case 4: // Floor
        {
            objectid = 19366;
            maxHealth = 400;
        }
        case 5: // Ceiling
        {
            objectid = 19445;
            maxHealth = 400;
        }
        case 6: // Stairs
        {
            objectid = 19423;
            maxHealth = 600;
        }
        case 7: // Window
        {
            objectid = 19377;
            maxHealth = 200;
        }
        case 8: // Storage Box
        {
            objectid = 2969;
            maxHealth = 100;
        }
        case 16: // Sleeping Bag
        {
            objectid = 1279;
            maxHealth = 50;
        }
        case 17: // Furnace
        {
            objectid = 3525;
            maxHealth = 200;
        }
        case 18: // Campfire
        {
            objectid = 19632;
            maxHealth = 100;
        }
        case 22: // Wooden Door
        {
            objectid = 19302;
            maxHealth = 300;
        }
        case 23: // Metal Door
        {
            objectid = 19302;
            maxHealth = 500;
        }
        default:
        {
            objectid = 19353; // Default to wall
            maxHealth = 500;
        }
    }

    BuildingInfo[buildingid][buildOwner] = PlayerInfo[playerid][pID];
    BuildingInfo[buildingid][buildType] = buildingType;
    BuildingInfo[buildingid][buildX] = x;
    BuildingInfo[buildingid][buildY] = y;
    BuildingInfo[buildingid][buildZ] = z;
    BuildingInfo[buildingid][buildRX] = 0.0;
    BuildingInfo[buildingid][buildRY] = 0.0;
    BuildingInfo[buildingid][buildRZ] = angle;
    BuildingInfo[buildingid][buildHealth] = maxHealth;
    BuildingInfo[buildingid][buildMaxHealth] = maxHealth;
    BuildingInfo[buildingid][buildLockCode][0] = '\0';
    BuildingInfo[buildingid][buildLocked] = 0;

    // Clear items if storage
    if(buildingType == 8 || buildingType == 17 || buildingType == 18)
    {
        for(new i = 0; i < 20; i++)
        {
            BuildingInfo[buildingid][buildItemID][i] = 0;
            BuildingInfo[buildingid][buildItemAmount][i] = 0;
        }
    }

    BuildingInfo[buildingid][buildObject] = CreateDynamicObject(objectid,
        BuildingInfo[buildingid][buildX],
        BuildingInfo[buildingid][buildY],
        BuildingInfo[buildingid][buildZ],
        BuildingInfo[buildingid][buildRX],
        BuildingInfo[buildingid][buildRY],
        BuildingInfo[buildingid][buildRZ],
        -1, -1);

    // Special handling for sleeping bag
    if(buildingType == 16)
    {
        PlayerInfo[playerid][pSpawnPoint] = 1; // Set to spawn at sleeping bag
        SendClientMessage(playerid, COLOR_GREEN, "Sleeping bag placed! You will now spawn here when you die or reconnect.");
    }

    // Save building to database
    new query[256];
    mysql_format(g_SQL, query, sizeof(query),
        "INSERT INTO buildings (owner, type, x, y, z, rx, ry, rz, health, maxhealth, lockcode, locked) VALUES (%d, %d, %.1f, %.1f, %.1f, %.1f, %.1f, %.1f, %d, %d, '', 0)",
        BuildingInfo[buildingid][buildOwner],
        BuildingInfo[buildingid][buildType],
        BuildingInfo[buildingid][buildX],
        BuildingInfo[buildingid][buildY],
        BuildingInfo[buildingid][buildZ],
        BuildingInfo[buildingid][buildRX],
        BuildingInfo[buildingid][buildRY],
        BuildingInfo[buildingid][buildRZ],
        BuildingInfo[buildingid][buildHealth],
        BuildingInfo[buildingid][buildMaxHealth]
    );
    mysql_tquery(g_SQL, query, "OnBuildingSave", "i", buildingid);

    // Disable building mode
    PlayerInfo[playerid][pBuildingMode] = 0;

    // Update building count
    if(buildingid + 1 > BuildingCount)
        BuildingCount = buildingid + 1;

    // Send message
    new buildingName[32];
    GetBuildingName(buildingType, buildingName);

    new string[128];
    format(string, sizeof(string), "%s placed successfully!", buildingName);
    SendClientMessage(playerid, COLOR_GREEN, string);

    return 1;
}

forward OnBuildingSave(buildingid);
public OnBuildingSave(buildingid)
{
    if(buildingid < 0 || buildingid >= MAX_BUILDINGS) return 0;

    BuildingInfo[buildingid][buildID] = cache_insert_id();

    return 1;
}

InteractWithBuilding(playerid)
{
    // Find closest building
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    new buildingid = -1;
    new Float:minDist = 3.0;

    for(new i = 0; i < BuildingCount; i++)
    {
        if(!IsValidDynamicObject(BuildingInfo[i][buildObject])) continue;

        new Float:dist = GetDistanceBetweenPoints3D(x, y, z, BuildingInfo[i][buildX], BuildingInfo[i][buildY], BuildingInfo[i][buildZ]);
        if(dist < minDist)
        {
            minDist = dist;
            buildingid = i;
        }
    }

    if(buildingid == -1) return 0;

    // Handle interaction based on building type
    switch(BuildingInfo[buildingid][buildType])
    {
        case 3, 22, 23: // Door types
        {
            // Check if door is locked
            if(BuildingInfo[buildingid][buildLocked] && BuildingInfo[buildingid][buildOwner] != PlayerInfo[playerid][pID])
            {
                // Check if player has code lock
                ShowPlayerDialog(playerid, DIALOG_NULL, DIALOG_STYLE_INPUT, "Enter Door Code", "This door is locked. Enter the code to unlock:", "Submit", "Cancel"); //hz dialog
                SetPVarInt(playerid, "InteractingBuildingID", buildingid);
                return 1;
            }

            // Toggle door open/closed
            new Float:zRot = BuildingInfo[buildingid][buildRZ];

            if(GetPVarInt(playerid, "DoorOpen") == 0)
            {
                zRot += 90.0;
                SetPVarInt(playerid, "DoorOpen", 1);
            }
            else
            {
                zRot -= 90.0;
                SetPVarInt(playerid, "DoorOpen", 0);
            }

            SetDynamicObjectRot(BuildingInfo[buildingid][buildObject],
                BuildingInfo[buildingid][buildRX],
                BuildingInfo[buildingid][buildRY],
                zRot);

            // Play door sound
            PlayerPlaySound(playerid, 1052, 0.0, 0.0, 0.0);
        }

        case 8: // Storage Box
        {
            // Check if owned by player or unlocked
            if(BuildingInfo[buildingid][buildOwner] != PlayerInfo[playerid][pID] && BuildingInfo[buildingid][buildLocked])
            {
                SendClientMessage(playerid, COLOR_RED, "This storage box is locked!");
                return 1;
            }

            // Show storage menu
            ShowStorageMenu(playerid, buildingid);
        }

        case 17: // Furnace
        {
            // Check if owned by player or unlocked
            if(BuildingInfo[buildingid][buildOwner] != PlayerInfo[playerid][pID] && BuildingInfo[buildingid][buildLocked])
            {
                SendClientMessage(playerid, COLOR_RED, "This furnace is locked!");
                return 1;
            }

            // Show furnace menu
            ShowFurnaceMenu(playerid, buildingid);
        }

        case 18: // Campfire
        {
            // Show campfire menu
            ShowCampfireMenu(playerid, buildingid);
        }
    }

    return 1;
}

ShowStorageMenu(playerid, buildingid)
{
    if(buildingid < 0 || buildingid >= BuildingCount) return 0;
    if(!IsValidDynamicObject(BuildingInfo[buildingid][buildObject])) return 0;

    new string[1024];
    format(string, sizeof(string), "Storage Box Contents:\n");

    for(new i = 0; i < 20; i++)
    {
        if(BuildingInfo[buildingid][buildItemID][i] > 0)
        {
            new itemName[32];
            GetItemName(BuildingInfo[buildingid][buildItemID][i], itemName);

            format(string, sizeof(string), "%s%d. %s (x%d)\n", string, i+1, itemName, BuildingInfo[buildingid][buildItemAmount][i]);
        }
        else
        {
            format(string, sizeof(string), "%s%d. Empty\n", string, i+1);
        }
    }

    SetPVarInt(playerid, "StorageBuildingID", buildingid);
    ShowPlayerDialog(playerid, DIALOG_NULL, DIALOG_STYLE_LIST, "Storage Box", string, "Take", "Close"); //hz dialog

    return 1;
}

ShowFurnaceMenu(playerid, buildingid)
{
    if(buildingid < 0 || buildingid >= BuildingCount) return 0;
    if(!IsValidDynamicObject(BuildingInfo[buildingid][buildObject])) return 0;

    new string[1024];
    format(string, sizeof(string), "Furnace:\n");

    // Check if furnace has fuel
    new bool:hasFuel = false;
    new fuelSlot = -1;

    for(new i = 0; i < 20; i++)
    {
        if(BuildingInfo[buildingid][buildItemID][i] == ITEM_WOOD || BuildingInfo[buildingid][buildItemID][i] == ITEM_CHARCOAL)
        {
            hasFuel = true;
            fuelSlot = i;
            break;
        }
    }

    if(hasFuel)
    {
        format(string, sizeof(string), "%sFurnace is active (has fuel)\n\n", string);
    }
    else
    {
        format(string, sizeof(string), "%sFurnace needs fuel to work\n\n", string);
    }

    // List contents
    for(new i = 0; i < 20; i++)
    {
        if(BuildingInfo[buildingid][buildItemID][i] > 0)
        {
            new itemName[32];
            GetItemName(BuildingInfo[buildingid][buildItemID][i], itemName);

            format(string, sizeof(string), "%s%d. %s (x%d)\n", string, i+1, itemName, BuildingInfo[buildingid][buildItemAmount][i]);
        }
        else
        {
            format(string, sizeof(string), "%s%d. Empty\n", string, i+1);
        }
    }

    SetPVarInt(playerid, "FurnaceBuildingID", buildingid);
    ShowPlayerDialog(playerid, DIALOG_NULL, DIALOG_STYLE_LIST, "Furnace", string, "Interact", "Close"); //hz dialog

    return 1;
}

ShowCampfireMenu(playerid, buildingid)
{
    if(buildingid < 0 || buildingid >= BuildingCount) return 0;
    if(!IsValidDynamicObject(BuildingInfo[buildingid][buildObject])) return 0;

    new string[512];
    format(string, sizeof(string), "Campfire:\n");

    // Check if campfire has fuel
    new bool:hasFuel = false;

    for(new i = 0; i < 20; i++)
    {
        if(BuildingInfo[buildingid][buildItemID][i] == ITEM_WOOD)
        {
            hasFuel = true;
            break;
        }
    }

    if(hasFuel)
    {
        format(string, sizeof(string), "%sCampfire is active (has fuel)\n\n", string);
        format(string, sizeof(string), "%sActions:\n", string);
        format(string, sizeof(string), "%s1. Cook Food\n", string);
        format(string, sizeof(string), "%s2. View Contents\n", string);
        format(string, sizeof(string), "%s3. Add Fuel (Wood)\n", string);
    }
    else
    {
        format(string, sizeof(string), "%sCampfire needs fuel to work\n\n", string);
        format(string, sizeof(string), "%sActions:\n", string);
        format(string, sizeof(string), "%s1. Add Fuel (Wood)\n", string);
        format(string, sizeof(string), "%s2. View Contents\n", string);
    }

    SetPVarInt(playerid, "CampfireBuildingID", buildingid);
    ShowPlayerDialog(playerid, DIALOG_NULL, DIALOG_STYLE_LIST, "Campfire", string, "Select", "Close"); // hz dialog

    return 1;
}

HitBuilding(playerid)
{
    // Find closest building
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    new buildingid = -1;
    new Float:minDist = 3.0;

    for(new i = 0; i < BuildingCount; i++)
    {
        if(!IsValidDynamicObject(BuildingInfo[i][buildObject])) continue;

        new Float:dist = GetDistanceBetweenPoints3D(x, y, z, BuildingInfo[i][buildX], BuildingInfo[i][buildY], BuildingInfo[i][buildZ]);
        if(dist < minDist)
        {
            minDist = dist;
            buildingid = i;
        }
    }

    if(buildingid == -1) return 0;

    // Calculate damage based on weapon
    new weaponid = GetPlayerWeapon(playerid);
    new damage = 0;

    switch(weaponid)
    {
        case 0: damage = 1; // Fist
        case 1: damage = 1; // Brass Knuckles
        case 2, 3, 4, 5, 6, 7, 8: damage = 2; // Melee weapons
        case 9: damage = 5; // Chainsaw
        case 22: damage = 5; // Pistol
        case 23: damage = 5; // Silenced Pistol
        case 24: damage = 7; // Desert Eagle
        case 25, 26, 27: damage = 10; // Shotguns
        case 28, 32: damage = 8; // Uzi/Tec9
        case 29, 30, 31: damage = 12; // MP5, AK47, M4
        case 33, 34: damage = 15; // Rifles
        case 35, 36, 37, 38: damage = 25; // Rockets/grenades
        default: damage = 3;
    }

    // Apply damage to building
    BuildingInfo[buildingid][buildHealth] -= damage;

    // Check if building is destroyed
    if(BuildingInfo[buildingid][buildHealth] <= 0)
    {
        // Create explosion effect
        CreateExplosion(BuildingInfo[buildingid][buildX], BuildingInfo[buildingid][buildY], BuildingInfo[buildingid][buildZ], 12, 1.0);

        // Drop items if storage
        if(BuildingInfo[buildingid][buildType] == 8)
        {
            DropBuildingItems(buildingid);
        }

        // Destroy building
        DestroyDynamicObject(BuildingInfo[buildingid][buildObject]);
        BuildingInfo[buildingid][buildObject] = INVALID_OBJECT_ID;

        // Remove from database
        new query[128];
        mysql_format(g_SQL, query, sizeof(query), "DELETE FROM buildings WHERE id = %d", BuildingInfo[buildingid][buildID]);
        mysql_tquery(g_SQL, query);

        // Also remove any items stored in it
        mysql_format(g_SQL, query, sizeof(query), "DELETE FROM building_items WHERE building_id = %d", BuildingInfo[buildingid][buildID]);
        mysql_tquery(g_SQL, query);

        // Send message
        SendClientMessage(playerid, COLOR_GREEN, "You destroyed a building!");
    }
    else
    {
        // Show damage effect
        new Float:health_percent = (float(BuildingInfo[buildingid][buildHealth]) / float(BuildingInfo[buildingid][buildMaxHealth])) * 100.0;

        if(health_percent < 25.0)
        {
            // Building critically damaged
            SendClientMessage(playerid, COLOR_RED, "This building is about to collapse!");
        }
        else if(health_percent < 50.0)
        {
            // Building badly damaged
            SendClientMessage(playerid, COLOR_ORANGE, "This building is heavily damaged!");
        }
    }

    return 1;
}

DropBuildingItems(buildingid)
{
    if(buildingid < 0 || buildingid >= BuildingCount) return 0;

    // Create loot container at building position
    new lootid = FindFreeLootContainer();
    if(lootid == -1) return 0;

    LootInfo[lootid][lootType] = 4; // Drop bag
    LootInfo[lootid][lootX] = BuildingInfo[buildingid][buildX];
    LootInfo[lootid][lootY] = BuildingInfo[buildingid][buildY];
    LootInfo[lootid][lootZ] = BuildingInfo[buildingid][buildZ];
    LootInfo[lootid][lootInterior] = 0;
    LootInfo[lootid][lootVW] = 0;
    LootInfo[lootid][lootActive] = true;
    LootInfo[lootid][lootRespawnTime] = 300; // 5 minutes

    // Transfer building items to loot container
    for(new i = 0; i < 10; i++)
    {
        LootInfo[lootid][lootItems][i] = 0;
        LootInfo[lootid][lootItemsAmount][i] = 0;
    }

    new itemCount = 0;

    for(new i = 0; i < 20 && itemCount < 10; i++)
    {
        if(BuildingInfo[buildingid][buildItemID][i] > 0)
        {
            LootInfo[lootid][lootItems][itemCount] = BuildingInfo[buildingid][buildItemID][i];
            LootInfo[lootid][lootItemsAmount][itemCount] = BuildingInfo[buildingid][buildItemAmount][i];
            itemCount++;
        }
    }

    // Create object for loot bag
    LootInfo[lootid][lootObject] = CreateDynamicObject(2969,
        LootInfo[lootid][lootX],
        LootInfo[lootid][lootY],
        LootInfo[lootid][lootZ],
        0.0, 0.0, 0.0, 0, 0);

    return 1;
}

LoadLootContainers()
{
    print("Spawning loot containers...");

    // Spawn barrels
    for(new i = 0; i < 100; i++)
    {
        new Float:x = -3000.0 + float(random(6000));
        new Float:y = -3000.0 + float(random(6000));
        new Float:z = 0.0;

        CreateLootContainerAtPos(0, x, y, z);
    }

    // Spawn crates
    for(new i = 0; i < 50; i++)
    {
        new Float:x = -3000.0 + float(random(6000));
        new Float:y = -3000.0 + float(random(6000));
        new Float:z = 0.0;

        CreateLootContainerAtPos(1, x, y, z);
    }

    // Spawn military crates (fewer, better loot)
    for(new i = 0; i < 25; i++)
    {
        new Float:x = -3000.0 + float(random(6000));
        new Float:y = -3000.0 + float(random(6000));
        new Float:z = 0.0;

        CreateLootContainerAtPos(2, x, y, z);
    }

    printf("Spawned %d loot containers", LootCount);

    return 1;
}

CreateLootContainerAtPos(type, Float:x, Float:y, Float:z)
{
    if(LootCount >= MAX_LOOT_CONTAINERS) return -1;

    LootInfo[LootCount][lootType] = type;
    LootInfo[LootCount][lootX] = x;
    LootInfo[LootCount][lootY] = y;
    LootInfo[LootCount][lootZ] = z;
    LootInfo[LootCount][lootInterior] = 0;
    LootInfo[LootCount][lootVW] = 0;
    LootInfo[LootCount][lootActive] = true;
    LootInfo[LootCount][lootRespawnTime] = 300 + random(300); // 5-10 minutes

    // Create object based on type
    switch(type)
    {
        case 0: // Barrel
        {
            LootInfo[LootCount][lootObject] = CreateDynamicObject(1225, x, y, z, 0.0, 0.0, 0.0, -1, -1, -1, 300.0);
        }
        case 1: // Crate
        {
            LootInfo[LootCount][lootObject] = CreateDynamicObject(964, x, y, z, 0.0, 0.0, 0.0, -1, -1, -1, 300.0);
        }
        case 2: // Military Crate
        {
            LootInfo[LootCount][lootObject] = CreateDynamicObject(2977, x, y, z, 0.0, 0.0, 0.0, -1, -1, -1, 300.0);
        }
        case 3: // Elite Crate
        {
            LootInfo[LootCount][lootObject] = CreateDynamicObject(3798, x, y, z, 0.0, 0.0, 0.0, -1, -1, -1, 300.0);
        }
    }

    // Fill with random loot
    for(new i = 0; i < 10; i++)
    {
        LootInfo[LootCount][lootItems][i] = 0;
        LootInfo[LootCount][lootItemsAmount][i] = 0;
    }

    new itemCount = random(5) + 1; // 1-5 items

    for(new i = 0; i < itemCount; i++)
    {
        new slot = i;
        new itemType;

        switch(type)
        {
            case 0: // Barrel - basic items
            {
                itemType = GetRandomBasicItem();
            }
            case 1: // Crate - medium tier items
            {
                itemType = GetRandomMediumItem();
            }
            case 2: // Military Crate - high tier items
            {
                itemType = GetRandomHighTierItem();
            }
            case 3: // Elite Crate - very high tier items
            {
                itemType = GetRandomEliteItem();
            }
        }

        new amount = 1;

        // Adjust amount for some items
        switch(itemType)
        {
            case ITEM_FOOD, ITEM_WATER, ITEM_BANDAGE:
                amount = 1 + random(3);
            case ITEM_AMMO_PISTOL, ITEM_AMMO_RIFLE, ITEM_AMMO_SHOTGUN:
                amount = 5 + random(15);
            case ITEM_METAL_FRAGMENTS, ITEM_GUNPOWDER, ITEM_SULFUR, ITEM_CHARCOAL:
                amount = 10 + random(40);
        }

        LootInfo[LootCount][lootItems][slot] = itemType;
        LootInfo[LootCount][lootItemsAmount][slot] = amount;
    }

    LootCount++;

    return LootCount - 1;
}

RespawnLootContainer(lootid)
{
    if(lootid < 0 || lootid >= LootCount) return 0;

    // Skip if it's a player drop
    if(LootInfo[lootid][lootType] == 4) return 0;

    // Recreate the object
    switch(LootInfo[lootid][lootType])
    {
        case 0: // Barrel
        {
            LootInfo[lootid][lootObject] = CreateDynamicObject(1225,
                LootInfo[lootid][lootX],
                LootInfo[lootid][lootY],
                LootInfo[lootid][lootZ],
                0.0, 0.0, 0.0,
                LootInfo[lootid][lootVW],
                LootInfo[lootid][lootInterior],
                -1, 300.0);
        }
        case 1: // Crate
        {
            LootInfo[lootid][lootObject] = CreateDynamicObject(964,
                LootInfo[lootid][lootX],
                LootInfo[lootid][lootY],
                LootInfo[lootid][lootZ],
                0.0, 0.0, 0.0,
                LootInfo[lootid][lootVW],
                LootInfo[lootid][lootInterior],
                -1, 300.0);
        }
        case 2: // Military Crate
        {
            LootInfo[lootid][lootObject] = CreateDynamicObject(2977,
                LootInfo[lootid][lootX],
                LootInfo[lootid][lootY],
                LootInfo[lootid][lootZ],
                0.0, 0.0, 0.0,
                LootInfo[lootid][lootVW],
                LootInfo[lootid][lootInterior],
                -1, 300.0);
        }
        case 3: // Elite Crate
        {
            LootInfo[lootid][lootObject] = CreateDynamicObject(3798,
                LootInfo[lootid][lootX],
                LootInfo[lootid][lootY],
                LootInfo[lootid][lootZ],
                0.0, 0.0, 0.0,
                LootInfo[lootid][lootVW],
                LootInfo[lootid][lootInterior],
                -1, 300.0);
        }
    }

    // Generate new loot
    for(new i = 0; i < 10; i++)
    {
        LootInfo[lootid][lootItems][i] = 0;
        LootInfo[lootid][lootItemsAmount][i] = 0;
    }

    new itemCount = random(5) + 1; // 1-5 items

    for(new i = 0; i < itemCount; i++)
    {
        new slot = i;
        new itemType;

        switch(LootInfo[lootid][lootType])
        {
            case 0: // Barrel - basic items
            {
                itemType = GetRandomBasicItem();
            }
            case 1: // Crate - medium tier items
            {
                itemType = GetRandomMediumItem();
            }
            case 2: // Military Crate - high tier items
            {
                itemType = GetRandomHighTierItem();
            }
            case 3: // Elite Crate - very high tier items
            {
                itemType = GetRandomEliteItem();
            }
        }

        new amount = 1;

        // Adjust amount for some items
        switch(itemType)
        {
            case ITEM_FOOD, ITEM_WATER, ITEM_BANDAGE:
                amount = 1 + random(3);
            case ITEM_AMMO_PISTOL, ITEM_AMMO_RIFLE, ITEM_AMMO_SHOTGUN:
                amount = 5 + random(15);
            case ITEM_METAL_FRAGMENTS, ITEM_GUNPOWDER, ITEM_SULFUR, ITEM_CHARCOAL:
                amount = 10 + random(40);
        }

        LootInfo[lootid][lootItems][slot] = itemType;
        LootInfo[lootid][lootItemsAmount][slot] = amount;
    }

    LootInfo[lootid][lootActive] = true;

    return 1;
}

FindFreeLootContainer()
{
    // First try to find an inactive container
    for(new i = 0; i < LootCount; i++)
    {
        if(!LootInfo[i][lootActive])
        {
            return i;
        }
    }

    // If none found, create a new one if there's space
    if(LootCount < MAX_LOOT_CONTAINERS)
    {
        return LootCount;
    }

    // No space, return invalid
    return -1;
}

CreateDeathLoot(playerid)
{
    // Get player position
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    // Create loot container
    new lootid = FindFreeLootContainer();
    if(lootid == -1) return 0;

    LootInfo[lootid][lootType] = 4; // Dead Body
    LootInfo[lootid][lootX] = x;
    LootInfo[lootid][lootY] = y;
    LootInfo[lootid][lootZ] = z;
    LootInfo[lootid][lootInterior] = GetPlayerInterior(playerid);
    LootInfo[lootid][lootVW] = GetPlayerVirtualWorld(playerid);
    LootInfo[lootid][lootActive] = true;
    LootInfo[lootid][lootRespawnTime] = 300; // 5 minutes

    // Transfer player's inventory to loot container
    for(new i = 0; i < 10; i++)
    {
        LootInfo[lootid][lootItems][i] = 0;
        LootInfo[lootid][lootItemsAmount][i] = 0;
    }

    new itemCount = 0;

    // Transfer resources
    for(new i = 0; i < 5; i++)
    {
        if(PlayerInfo[playerid][pMaterials][i] > 0 && itemCount < 10)
        {
            // Convert resource type to item ID
            new itemType;
            switch(i)
            {
                case 0: itemType = ITEM_WOOD;
                case 1: itemType = ITEM_STONE;
                case 2: itemType = ITEM_METAL;
                case 3: itemType = ITEM_CLOTH;
                case 4: itemType = ITEM_CRUDE_OIL;
            }

            LootInfo[lootid][lootItems][itemCount] = itemType;
            LootInfo[lootid][lootItemsAmount][itemCount] = PlayerInfo[playerid][pMaterials][i];
            itemCount++;
        }
    }

    // Transfer inventory items
    for(new i = 0; i < 30 && itemCount < 10; i++)
    {
        if(PlayerInfo[playerid][pInventory][i] > 0)
        {
            LootInfo[lootid][lootItems][itemCount] = PlayerInfo[playerid][pInventory][i];
            LootInfo[lootid][lootItemsAmount][itemCount] = PlayerInfo[playerid][pInventoryAmount][i];
            itemCount++;

            if(itemCount >= 10) break; // Maximum 10 slots in loot container
        }
    }

    // Create death bag object
    LootInfo[lootid][lootObject] = CreateDynamicObject(2060, x, y, z - 0.5, 0.0, 0.0, 0.0,
        LootInfo[lootid][lootVW], LootInfo[lootid][lootInterior]);

    return 1;
}

LoadSleepingPlayers()
{
    new query[128];
    mysql_format(g_SQL, query, sizeof(query), "SELECT * FROM sleeping_players WHERE active = 1");
    mysql_tquery(g_SQL, query, "OnSleepingPlayersLoad", "");

    return 1;
}

forward OnSleepingPlayersLoad();
public OnSleepingPlayersLoad()
{
    new rows;
    cache_get_row_count(rows);

    printf("Loading %d sleeping players...", rows);

    for(new i = 0; i < rows; i++)
    {
        if(i >= MAX_SLEEPING_PLAYERS) break;

        new sleepID, user_id, interior, vworld, active;
        new Float:x, Float:y, Float:z, Float:rot, Float:health, Float:armor, Float:hunger, Float:thirst;

        cache_get_value_name_int(i, "id", sleepID);
        cache_get_value_name(i, "name", SleepingPlayers[i][sleepName], MAX_PLAYER_NAME);
        cache_get_value_name_int(i, "user_id", user_id);
        cache_get_value_name_float(i, "x", x);
        cache_get_value_name_float(i, "y", y);
        cache_get_value_name_float(i, "z", z);
        cache_get_value_name_float(i, "rot", rot);
        cache_get_value_name_int(i, "interior", interior);
        cache_get_value_name_int(i, "virtualworld", vworld);
        cache_get_value_name_int(i, "active", active);
        cache_get_value_name_float(i, "health", health);
        cache_get_value_name_float(i, "armor", armor);
        cache_get_value_name_float(i, "hunger", hunger);
        cache_get_value_name_float(i, "thirst", thirst);

        SleepingPlayers[i][sleepUserID] = user_id;
        SleepingPlayers[i][sleepX] = x;
        SleepingPlayers[i][sleepY] = y;
        SleepingPlayers[i][sleepZ] = z;
        SleepingPlayers[i][sleepRot] = rot;
        SleepingPlayers[i][sleepInterior] = interior;
        SleepingPlayers[i][sleepVW] = vworld;
        SleepingPlayers[i][sleepActive] = bool:active;
        SleepingPlayers[i][sleepHealth] = health;
        SleepingPlayers[i][sleepArmor] = armor;
        SleepingPlayers[i][sleepHunger] = hunger;
        SleepingPlayers[i][sleepThirst] = thirst;

        SleepingPlayers[i][sleepObject] = CreateDynamicObject(1241,
            SleepingPlayers[i][sleepX],
            SleepingPlayers[i][sleepY],
            SleepingPlayers[i][sleepZ],
            0.0, 0.0, SleepingPlayers[i][sleepRot],
            SleepingPlayers[i][sleepVW],
            SleepingPlayers[i][sleepInterior]);

        new query[128];
        mysql_format(g_SQL, query, sizeof(query), "SELECT * FROM sleeping_inventory WHERE sleep_id = %d", sleepID);
        mysql_tquery(g_SQL, query, "OnSleepingInventoryLoad", "i", i);

        mysql_format(g_SQL, query, sizeof(query), "SELECT * FROM sleeping_materials WHERE sleep_id = %d", sleepID);
        mysql_tquery(g_SQL, query, "OnSleepingMaterialsLoad", "i", i);

        SleepingCount++;
    }

    printf("Loaded %d sleeping players", SleepingCount);

    return 1;
}

forward OnSleepingInventoryLoad(sleepindex);
public OnSleepingInventoryLoad(sleepindex)
{
    new rows;
    cache_get_row_count(rows);

    for(new i = 0; i < 30; i++)
    {
        SleepingPlayers[sleepindex][sleepInventory][i] = 0;
        SleepingPlayers[sleepindex][sleepInventoryAmount][i] = 0;
    }

    for(new i = 0; i < rows; i++)
    {
        new slot, item_id, amount;

        cache_get_value_name_int(i, "slot", slot);
        cache_get_value_name_int(i, "item_id", item_id);
        cache_get_value_name_int(i, "amount", amount);

        if(slot >= 0 && slot < 30)
        {
            SleepingPlayers[sleepindex][sleepInventory][slot] = item_id;
            SleepingPlayers[sleepindex][sleepInventoryAmount][slot] = amount;
        }
    }

    return 1;
}

forward OnSleepingMaterialsLoad(sleepindex);
public OnSleepingMaterialsLoad(sleepindex)
{
    new rows;
    cache_get_row_count(rows);

    if(rows > 0)
    {
        new wood, stone, metal, cloth, fuel;

        cache_get_value_name_int(0, "wood", wood);
        cache_get_value_name_int(0, "stone", stone);
        cache_get_value_name_int(0, "metal", metal);
        cache_get_value_name_int(0, "cloth", cloth);
        cache_get_value_name_int(0, "fuel", fuel);

        SleepingPlayers[sleepindex][sleepMaterials][0] = wood;
        SleepingPlayers[sleepindex][sleepMaterials][1] = stone;
        SleepingPlayers[sleepindex][sleepMaterials][2] = metal;
        SleepingPlayers[sleepindex][sleepMaterials][3] = cloth;
        SleepingPlayers[sleepindex][sleepMaterials][4] = fuel;
    }
    else
    {
        for(new i = 0; i < 5; i++)
        {
            SleepingPlayers[sleepindex][sleepMaterials][i] = 0;
        }
    }

    return 1;
}

public PlayerSleepSave(playerid)
{
    // Don't create sleeping player if health is too low
    if(PlayerInfo[playerid][pHealth] < 20.0) return 0;

    // Find free sleeping slot
    new sleepid = -1;

    for(new i = 0; i < MAX_SLEEPING_PLAYERS; i++)
    {
        if(!SleepingPlayers[i][sleepActive])
        {
            sleepid = i;
            break;
        }
    }

    if(sleepid == -1)
    {
        // No free slot
        return 0;
    }

    // Get player position
    new Float:x, Float:y, Float:z, Float:rot;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, rot);

    // Save sleeping player data
    GetPlayerName(playerid, SleepingPlayers[sleepid][sleepName], MAX_PLAYER_NAME);
    SleepingPlayers[sleepid][sleepUserID] = PlayerInfo[playerid][pID];
    SleepingPlayers[sleepid][sleepX] = x;
    SleepingPlayers[sleepid][sleepY] = y;
    SleepingPlayers[sleepid][sleepZ] = z;
    SleepingPlayers[sleepid][sleepRot] = rot;
    SleepingPlayers[sleepid][sleepInterior] = GetPlayerInterior(playerid);
    SleepingPlayers[sleepid][sleepVW] = GetPlayerVirtualWorld(playerid);
    SleepingPlayers[sleepid][sleepActive] = true;
    SleepingPlayers[sleepid][sleepHealth] = PlayerInfo[playerid][pHealth];
    SleepingPlayers[sleepid][sleepArmor] = PlayerInfo[playerid][pArmor];
    SleepingPlayers[sleepid][sleepHunger] = PlayerInfo[playerid][pHunger];
    SleepingPlayers[sleepid][sleepThirst] = PlayerInfo[playerid][pThirst];

    // Copy inventory
    for(new i = 0; i < 30; i++)
    {
        SleepingPlayers[sleepid][sleepInventory][i] = PlayerInfo[playerid][pInventory][i];
        SleepingPlayers[sleepid][sleepInventoryAmount][i] = PlayerInfo[playerid][pInventoryAmount][i];
    }

    // Copy materials
    for(new i = 0; i < 5; i++)
    {
        SleepingPlayers[sleepid][sleepMaterials][i] = PlayerInfo[playerid][pMaterials][i];
    }

    // Create sleeping player object
    SleepingPlayers[sleepid][sleepObject] = CreateDynamicObject(1241, x, y, z, 0.0, 0.0, rot,
        SleepingPlayers[sleepid][sleepVW], SleepingPlayers[sleepid][sleepInterior]);

    // Save to database
    new query[512];
    mysql_format(g_SQL, query, sizeof(query),
        "INSERT INTO sleeping_players (name, user_id, x, y, z, rot, interior, virtualworld, active, health, armor, hunger, thirst) VALUES ('%e', %d, %.4f, %.4f, %.4f, %.4f, %d, %d, 1, %.1f, %.1f, %.1f, %.1f)",
        SleepingPlayers[sleepid][sleepName],
        SleepingPlayers[sleepid][sleepUserID],
        SleepingPlayers[sleepid][sleepX],
        SleepingPlayers[sleepid][sleepY],
        SleepingPlayers[sleepid][sleepZ],
        SleepingPlayers[sleepid][sleepRot],
        SleepingPlayers[sleepid][sleepInterior],
        SleepingPlayers[sleepid][sleepVW],
        SleepingPlayers[sleepid][sleepHealth],
        SleepingPlayers[sleepid][sleepArmor],
        SleepingPlayers[sleepid][sleepHunger],
        SleepingPlayers[sleepid][sleepThirst]
    );
    mysql_tquery(g_SQL, query, "OnSleepingPlayerSave", "i", sleepid);

    SleepingCount++;

    return 1;
}

forward OnSleepingPlayerSave(sleepid);
public OnSleepingPlayerSave(sleepid)
{
    new sleepDBID = cache_insert_id();

    // Save inventory items
    new query[256];
    for(new i = 0; i < 30; i++)
    {
        if(SleepingPlayers[sleepid][sleepInventory][i] > 0)
        {
            mysql_format(g_SQL, query, sizeof(query),
                "INSERT INTO sleeping_inventory (sleep_id, slot, item_id, amount) VALUES (%d, %d, %d, %d)",
                sleepDBID, i, SleepingPlayers[sleepid][sleepInventory][i], SleepingPlayers[sleepid][sleepInventoryAmount][i]
            );
            mysql_tquery(g_SQL, query);
        }
    }

    // Save materials
    mysql_format(g_SQL, query, sizeof(query),
        "INSERT INTO sleeping_materials (sleep_id, wood, stone, metal, cloth, fuel) VALUES (%d, %d, %d, %d, %d, %d)",
        sleepDBID,
        SleepingPlayers[sleepid][sleepMaterials][0],
        SleepingPlayers[sleepid][sleepMaterials][1],
        SleepingPlayers[sleepid][sleepMaterials][2],
        SleepingPlayers[sleepid][sleepMaterials][3],
        SleepingPlayers[sleepid][sleepMaterials][4]
    );
    mysql_tquery(g_SQL, query);

    return 1;
}

IsPlayerInSafeZone(playerid)
{
    // Check if player is in a safe zone
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    // Safe zone coordinates - could be extended to a list
    if(GetDistanceBetweenPoints3D(x, y, z, 0.0, 0.0, 3.0) < 50.0) // Center of map is safe
    {
        return 1;
    }

    return 0;
}

// Helper functions
GetItemName(itemid, dest[], size = sizeof(dest))
{
    switch(itemid)
    {
        case ITEM_HATCHET: format(dest, size, "Hatchet");
        case ITEM_PICKAXE: format(dest, size, "Pickaxe");
        case ITEM_HAMMER: format(dest, size, "Hammer");
        case ITEM_FOOD: format(dest, size, "Food");
        case ITEM_WATER: format(dest, size, "Water");
        case ITEM_MEDKIT: format(dest, size, "Medkit");
        case ITEM_BANDAGE: format(dest, size, "Bandage");
        case ITEM_PISTOL: format(dest, size, "Pistol");
        case ITEM_RIFLE: format(dest, size, "Rifle");
        case ITEM_SHOTGUN: format(dest, size, "Shotgun");
        case ITEM_AMMO_PISTOL: format(dest, size, "Pistol Ammo");
        case ITEM_AMMO_RIFLE: format(dest, size, "Rifle Ammo");
        case ITEM_AMMO_SHOTGUN: format(dest, size, "Shotgun Ammo");
        case ITEM_RADIATION_SUIT: format(dest, size, "Radiation Suit");
        case ITEM_MAP: format(dest, size, "Map");
        case ITEM_SLEEPING_BAG: format(dest, size, "Sleeping Bag");
        case ITEM_FURNACE: format(dest, size, "Furnace");
        case ITEM_CAMPFIRE: format(dest, size, "Campfire");
        case ITEM_CODELOCK: format(dest, size, "Code Lock");
        case ITEM_KEYLOCK: format(dest, size, "Key Lock");
        case ITEM_KEY: format(dest, size, "Key");
        case ITEM_WOOD_DOOR: format(dest, size, "Wooden Door");
        case ITEM_METAL_DOOR: format(dest, size, "Metal Door");
        case ITEM_METAL_FRAGMENTS: format(dest, size, "Metal Fragments");
        case ITEM_CHARCOAL: format(dest, size, "Charcoal");
        case ITEM_GUNPOWDER: format(dest, size, "Gunpowder");
        case ITEM_EXPLOSIVE: format(dest, size, "Explosive");
        case ITEM_C4: format(dest, size, "C4");
        case ITEM_SULFUR: format(dest, size, "Sulfur");
        case ITEM_CRUDE_OIL: format(dest, size, "Crude Oil");
        case ITEM_WOOD: format(dest, size, "Wood");
        case ITEM_STONE: format(dest, size, "Stone");
        case ITEM_METAL: format(dest, size, "Metal");
        case ITEM_CLOTH: format(dest, size, "Cloth");
        default: format(dest, size, "Unknown Item");
    }
    return 1;
}

GetBuildingName(buildingType, dest[], size = sizeof(dest))
{
    switch(buildingType)
    {
        case 0: format(dest, size, "Foundation");
        case 1: format(dest, size, "Wall");
        case 2: format(dest, size, "Doorway");
        case 3: format(dest, size, "Door");
        case 4: format(dest, size, "Floor");
        case 5: format(dest, size, "Ceiling");
        case 6: format(dest, size, "Stairs");
        case 7: format(dest, size, "Window");
        case 8: format(dest, size, "Storage Box");
        case 16: format(dest, size, "Sleeping Bag");
        case 17: format(dest, size, "Furnace");
        case 18: format(dest, size, "Campfire");
        case 22: format(dest, size, "Wooden Door");
        case 23: format(dest, size, "Metal Door");
        default: format(dest, size, "Unknown Building");
    }
    return 1;
}

FindFreeInventorySlot(playerid, itemid)
{
    // First check if player already has this item in inventory
    for(new i = 0; i < 30; i++)
    {
        if(PlayerInfo[playerid][pInventory][i] == itemid)
        {
            return i;
        }
    }

    // If not found, look for empty slot
    for(new i = 0; i < 30; i++)
    {
        if(PlayerInfo[playerid][pInventory][i] == 0)
        {
            return i;
        }
    }

    // No free slot
    return -1;
}

GetCraftingRequirements(itemType, &wood, &stone, &metal, &cloth, &other, &otherItem)
{
    wood = 0;
    stone = 0;
    metal = 0;
    cloth = 0;
    other = 0;
    otherItem = 0;

    switch(itemType)
    {
        case ITEM_HATCHET:
        {
            wood = 50;
            metal = 25;
        }
        case ITEM_PICKAXE:
        {
            wood = 50;
            metal = 40;
        }
        case ITEM_HAMMER:
        {
            wood = 100;
            metal = 50;
        }
        case ITEM_BANDAGE:
        {
            cloth = 10;
        }
        case ITEM_MEDKIT:
        {
            cloth = 50;
            metal = 20;
        }
        case ITEM_SLEEPING_BAG:
        {
            cloth = 100;
            wood = 30;
        }
        case ITEM_FURNACE:
        {
            stone = 500;
            wood = 100;
            metal = 50;
        }
        case ITEM_CAMPFIRE:
        {
            wood = 200;
            stone = 20;
        }
        case ITEM_WOOD_DOOR:
        {
            wood = 200;
            metal = 50;
        }
        case ITEM_METAL_DOOR:
        {
            metal = 300;
            wood = 50;
        }
        case ITEM_CODELOCK:
        {
            metal = 100;
        }
        case ITEM_PISTOL:
        {
            metal = 150;
            wood = 50;
            other = 20;
            otherItem = ITEM_GUNPOWDER;
        }
        case ITEM_SHOTGUN:
        {
            metal = 200;
            wood = 100;
            other = 30;
            otherItem = ITEM_GUNPOWDER;
        }
        case ITEM_RIFLE:
        {
            metal = 300;
            wood = 150;
            other = 50;
            otherItem = ITEM_GUNPOWDER;
        }
        case ITEM_AMMO_PISTOL:
        {
            metal = 20;
            other = 10;
            otherItem = ITEM_GUNPOWDER;
        }
        case ITEM_AMMO_SHOTGUN:
        {
            metal = 30;
            other = 15;
            otherItem = ITEM_GUNPOWDER;
        }
        case ITEM_AMMO_RIFLE:
        {
            metal = 40;
            other = 20;
            otherItem = ITEM_GUNPOWDER;
        }
        case ITEM_GUNPOWDER:
        {
            other = 30;
            otherItem = ITEM_CHARCOAL;
            stone = 20; // Representing sulfur as stone for simplicity
        }
        case ITEM_EXPLOSIVE:
        {
            other = 100;
            otherItem = ITEM_GUNPOWDER;
            metal = 50;
            cloth = 20;
        }
        case ITEM_C4:
        {
            other = 5;
            otherItem = ITEM_EXPLOSIVE;
            metal = 100;
            cloth = 60;
        }
    }

    return 1;
}

GetCraftingTime(itemType)
{
    switch(itemType)
    {
        case ITEM_HATCHET, ITEM_PICKAXE, ITEM_HAMMER: return 5; // Basic tools
        case ITEM_BANDAGE: return 3;
        case ITEM_MEDKIT: return 10;
        case ITEM_SLEEPING_BAG: return 5;
        case ITEM_FURNACE: return 15;
        case ITEM_CAMPFIRE: return 8;
        case ITEM_WOOD_DOOR: return 10;
        case ITEM_METAL_DOOR: return 15;
        case ITEM_CODELOCK: return 8;
        case ITEM_PISTOL: return 20;
        case ITEM_SHOTGUN: return 25;
        case ITEM_RIFLE: return 30;
        case ITEM_AMMO_PISTOL, ITEM_AMMO_SHOTGUN, ITEM_AMMO_RIFLE: return 8;
        case ITEM_GUNPOWDER: return 10;
        case ITEM_EXPLOSIVE: return 15;
        case ITEM_C4: return 30;
        default: return 5;
    }
}

GetBuildingRequirements(buildType, &wood, &stone, &metal)
{
    wood = 0;
    stone = 0;
    metal = 0;

    switch(buildType)
    {
        case 0: // Foundation
        {
            wood = 500;
            stone = 300;
        }
        case 1: // Wall
        {
            wood = 200;
            stone = 100;
        }
        case 2: // Doorway
        {
            wood = 180;
            stone = 90;
        }
        case 3: // Door
        {
            wood = 100;
            metal = 20;
        }
        case 4: // Floor
        {
            wood = 150;
            stone = 80;
        }
        case 5: // Ceiling
        {
            wood = 150;
            stone = 80;
        }
        case 6: // Stairs
        {
            wood = 250;
            stone = 150;
        }
        case 7: // Window
        {
            wood = 160;
            stone = 80;
        }
        case 8: // Storage Box
        {
            wood = 100;
            metal = 20;
        }
    }

    return 1;
}

GetRandomBasicItem()
{
    new items[10] = {
        ITEM_HATCHET, ITEM_PICKAXE, ITEM_FOOD, ITEM_WATER, ITEM_BANDAGE,
        ITEM_CLOTH, ITEM_WOOD, ITEM_STONE, ITEM_METAL, ITEM_CHARCOAL
    };

    return items[random(sizeof(items))];
}

GetRandomMediumItem()
{
    new items[12] = {
        ITEM_HATCHET, ITEM_PICKAXE, ITEM_HAMMER, ITEM_FOOD, ITEM_WATER,
        ITEM_BANDAGE, ITEM_MEDKIT, ITEM_SLEEPING_BAG, ITEM_KEYLOCK,
        ITEM_METAL_FRAGMENTS, ITEM_GUNPOWDER, ITEM_AMMO_PISTOL
    };

    return items[random(sizeof(items))];
}

GetRandomHighTierItem()
{
    new items[10] = {
        ITEM_PISTOL, ITEM_SHOTGUN, ITEM_AMMO_PISTOL, ITEM_AMMO_SHOTGUN,
        ITEM_MEDKIT, ITEM_CODELOCK, ITEM_GUNPOWDER, ITEM_EXPLOSIVE,
        ITEM_WOOD_DOOR, ITEM_METAL_DOOR
    };

    return items[random(sizeof(items))];
}

GetRandomEliteItem()
{
    new items[8] = {
        ITEM_RIFLE, ITEM_SHOTGUN, ITEM_AMMO_RIFLE, ITEM_RADIATION_SUIT,
        ITEM_C4, ITEM_EXPLOSIVE, ITEM_METAL_DOOR, ITEM_FURNACE
    };

    return items[random(sizeof(items))];
}

FormatTimestamp(timestamp)
{
    new year, month, day, hour, minute, second;
    timestamp_to_date(timestamp, year, month, day, hour, minute, second);

    new result[32];
    format(result, sizeof(result), "%02d/%02d/%04d %02d:%02d", day, month, year, hour, minute);

    return result;
}

GetPlayerNameEx(playerid)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    return name;
}

// Time functions
timestamp_to_date(timestamp, &year, &month, &day, &hour, &minute, &second)
{
    new days_in_month[12] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    new seconds_in_day = 86400; // 24 * 60 * 60
    new seconds_in_hour = 3600; // 60 * 60
    new seconds_in_minute = 60;

    // Base time: 1970-01-01 00:00:00 UTC
    year = 1970;
    month = 1;
    day = 1;

    // Calculate year
    while(true)
    {
        new days_in_year = 365;
        if((year % 4 == 0 && year % 100 != 0) || year % 400 == 0) // Leap year
            days_in_year = 366;

        new seconds_in_year = days_in_year * seconds_in_day;

        if(timestamp < seconds_in_year)
            break;

        timestamp -= seconds_in_year;
        year++;
    }

    // Update February days for leap year
    if((year % 4 == 0 && year % 100 != 0) || year % 400 == 0)
        days_in_month[1] = 29;

    // Calculate month
    while(timestamp >= days_in_month[month-1] * seconds_in_day)
    {
        timestamp -= days_in_month[month-1] * seconds_in_day;
        month++;
    }

    // Calculate day
    day += timestamp / seconds_in_day;
    timestamp %= seconds_in_day;

    // Calculate hour, minute, second
    hour = timestamp / seconds_in_hour;
    timestamp %= seconds_in_hour;

    minute = timestamp / seconds_in_minute;
    second = timestamp % seconds_in_minute;

    return 1;
}

stock Float:GetDistanceBetweenPoints3D(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2)
{
    return VectorSize(x1-x2,y1-y2,z1-z2);
}
