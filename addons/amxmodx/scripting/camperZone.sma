/*
*
*	Camper Zone by RedSMURF
*
*
*	Description:
*
*	Cvars:
*		None
*
*	Commands:
*       say /cz        "Opens the Camper Zone menu."
*       say_team /cz   "Opens the Camper Zone menu."
*       cz_reload      "Reloads the configuration file."
*
*	Changelog:
*       v1.0: Initial release.
*
*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

#if !defined MAX_VALUE_LENGTH
    #define MAX_VALUE_LENGTH 64
#endif

#if !defined MAX_RESOURCE_PATH_LENGTH
    #define MAX_RESOURCE_PATH_LENGTH 128
#endif

#if !defined MAX_FILE_CELL_SIZE
    #define MAX_FILE_CELL_SIZE 192
#endif

#if !defined MAX_PLATFORM_PATH_LENGTH
    #define MAX_PLATFORM_PATH_LENGTH 256
#endif

#define MAX_ENT                     32
#define CAMPER_CHECK                10.0
#define CAMPER_OFFSET_BASE          90.0
#define CAMPER_OFFSET_MIN           42.0
#define CAMPER_OFFSET_MAX           900.0
#define CAMPER_OFFSET_STEP          10.0
#define CAMPER_GHOST_ALPHA          128
#define ADMIN_ACCESS                ADMIN_RCON
#define CAMPER_KEY                  294102
#define CAMPER_ARRAY_ITEM           pev_iuser1
#define PDATA_NEXT_ATTACK           83
#define XO_CBASEPLAYER              5
#define XO_CBASEPLAYERWEAPON        4
#define SOUND_NAV                   "buttons/blip1.wav"
#define SOUND_REMOVE                "buttons/button10.wav"
#define SOUND_ALERT                 "buttons/bell1.wav"

new const PLUGIN_VERSION[]          = "1.0"
new const Float:DELAY_ON_LOAD       = 1.0
new const ERROR_FILE[]              = "CamperZone_ERRORS.log"

enum
{
    SECTION_NONE,
    SECTION_MAIN_SETTINGS,
    SECTION_CAMPER
}

enum
{
    DTYPE_INT,
    DTYPE_FLOAT,
    DTYPE_FLAGS,
    DTYPE_STRING_MODEL,
    DTYPE_STRING_SOUND,
    DTYPE_ARRAY_MESSAGE,
    DTYPE_ARRAY_MODEL,
    DTYPE_ARRAY_SOUND,
    DTYPE_STRING_MODEL_ID,
    DTYPE_ARRAY_MODEL_ID
}

enum
{
    FLAG_WARNING_SLAP       = (1 << 0),
    FLAG_WARNING_MESSAGE    = (1 << 1),
    FLAG_DAMAGE_SLAP        = (1 << 2),

    FLAG_GHOST              = (1 << 3),
    FLAG_SELECT             = (1 << 4),
    FLAG_ACTIVE             = (1 << 5),
    FLAG_MESSAGE            = (1 << 6)
}

enum
{
    TARGET_GHOST,
    TARGET_SELECT,
    TARGET_HIDE,
    TARGET_CLEAR
}

enum _:MAIN_SETTINGS
{
    SETTING_DEFAULT_MODEL[MAX_RESOURCE_PATH_LENGTH],
    SETTING_DEFAULT_FLAGS,
    SETTING_DEFAULT_TEAM,
    Float:SETTING_DEFAULT_WARNING_DELAY,
    Float:SETTING_DEFAULT_WARNING_COOLDOWN[2],
    Array:SETTING_DEFAULT_WARNING_MESSAGE,
    SETTING_DEFAULT_WARNING_MESSAGE_COUNT,
    Float:SETTING_DEFAULT_DAMAGE[2],
    Float:SETTING_DEFAULT_DAMAGE_TICK[2],
    Float:SETTING_DEFAULT_DAMAGE_DELAY,
    Float:SETTING_DEFAULT_DAMAGE_RESET_DELAY,
    Float:SETTING_DEFAULT_DAMAGE_MULTIPLIER_DELAY,
    Float:SETTING_DEFAULT_DAMAGE_MULTIPLIER,
    SETTING_DEFAULT_DAMAGETYPE,

    bool:SETTING_CAMPER_LOAD,
    Float:SETTING_CAMPER_TASK,
    Float:SETTING_SIZE_BASE,
    Float:SETTING_SIZE_HEIGHT[2],
    Float:SETTING_SIZE_WIDTH[2],
    Float:SETTING_SIZE_DEPTH[2],

    SETTING_BEAM,
    SETTING_BEAM_WIDTH,
    SETTING_BEAM_ALPHA
}

enum _:CAMPER
{
    CAMPER_NAME[MAX_VALUE_LENGTH],
    CAMPER_ID,
    CAMPER_ITEM,
    CAMPER_FLAGS,
    CAMPER_TEAM,
    Float:CAMPER_WARNING_DELAY,
    Float:CAMPER_WARNING_COOLDOWN[2],
    Array:CAMPER_WARNING_MESSAGE,
    CAMPER_WARNING_MESSAGE_COUNT,
    Float:CAMPER_DAMAGE[2],
    Float:CAMPER_DAMAGE_TICK[2],
    Float:CAMPER_DAMAGE_DELAY,
    Float:CAMPER_DAMAGE_RESET_DELAY,
    Float:CAMPER_DAMAGE_MULTIPLIER_DELAY,
    Float:CAMPER_DAMAGE_MULTIPLIER,
    CAMPER_DAMAGETYPE,

    Float:CAMPER_SCALE[3],
    Float:CAMPER_ORIGIN[3],
    Float:CAMPER_CORNERS[24],
    Float:CAMPER_MINS[3],
    Float:CAMPER_MAXS[3]
}

enum _:PLAYER_DATA
{
    PDATA_CAMPER_GHOST,
    PDATA_CAMPER_MENU,
    bool:PDATA_CAMPER_ACTION,
    bool:PDATA_CAMPER_ZONE,
    bool:PDATA_SCALE_UP,
    PDATA_SCALE_FACTOR,
    Float:PDATA_OFFSET,
    Float:PDATA_NEXT_OFFSET,

    PDATA_MENU_TYPE,
    bool:PDATA_MENU_TRACE,

    bool:PDATA_TAKING_DAMAGE,
    Float:PDATA_NEXT_WARNING,
    Float:PDATA_NEXT_DAMAGE,
    Float:PDATA_NEXT_DAMAGE_MULTIPLIER,
    Float:PDATA_NEXT_RESET
}

enum
{
    SOUND_MENU_NAV,
    SOUND_MENU_REMOVE,
    SOUND_MENU_ALERT
}

enum
{
    MENU_ROOT,
    MENU_CREATE,
    MENU_EDIT,
    MENU_REMOVE,
    MENU_STATUS,
    MENU_SCALE
}

enum
{
    ROOT_CREATE,
    ROOT_EDIT,
    ROOT_REMOVE,
    ROOT_SAVE,

    ROOT_NOCLIP = 5,
    ROOT_GODMODE
}

enum
{
    EDIT_STATUS
}

enum
{
    REMOVE_NEXT,
    REMOVE_BACK,

    REMOVE_CURRENT = 3,
    REMOVE_ALL
}

enum
{
    STATUS_NEXT,
    STATUS_BACK,

    STATUS_CURRENT = 3,
    STATUS_ALL_ENABLE,
    STATUS_ALL_DISABLE
}

enum
{
    STATUS_NEXT,
    STATUS_BACK,

    STATUS_CURRENT = 3,
    STATUS_ALL_ENABLE,
    STATUS_ALL_DISABLE
}

enum
{
    REMOVE_NEXT,
    REMOVE_BACK,

    REMOVE_CURRENT = 3,
    REMOVE_ALL
}

enum
{
    SCALE_HEIGHT,
    SCALE_WIDTH,
    SCALE_DEPTH,

    SCALE_FACTOR = 4,
    SCALE_MODE,
    SCALE_PLACE
}

new g_szMenuHandler[][MAX_VALUE_LENGTH] =
{
    "menuHandlerRoot",
    "menuHandlerCreate",
    "menuHandlerEdit",
    "menuHandlerRemove",
    "menuHandlerStatus",
    "menuHandlerScale"
}

new Float:g_fScaleFactor[] = { 5.0, 10.0, 20.0, 30.0, 45.0, 60.0 }
new g_szCN[] = "camperzone"

new Array:g_aCamper, Array:g_aCamperConfig,
    g_eSettings[MAIN_SETTINGS],
    g_ePlayerData[MAX_PLAYERS + 1][PLAYER_DATA],
    bool:g_bFileWasRead, g_iActivePlayers,
    HamHook:g_iFwdPreThink, HamHook:g_iFwdKilled,
    g_iCamper, g_iCamperConfig,
    g_iMaxPlayers

public plugin_init()
{
    register_plugin("Camper Zone", PLUGIN_VERSION, "RedSMURF")
    register_cvar("RedSMURF_CamperZone", PLUGIN_VERSION, ADMIN_ACCESS)

    register_clcmd("say /cz",      "cmdMenu", ADMIN_ACCESS, "-- Opens the Camper Zone menu.")
    register_clcmd("say_team /cz", "cmdMenu", ADMIN_ACCESS, "-- Opens the Camper Zone menu.")
    register_concmd("cz_reload",   "cmdReload", ADMIN_ACCESS, "-- Reload the configuration file")
    register_dictionary("CamperZone.txt")

    g_iFwdPreThink = RegisterHam(Ham_Player_PreThink, "player", "fwdPreThink")
    g_iFwdKilled = RegisterHam(Ham_Killed, "player", "fwdKilled", 1)
    DisableForward()

    camperInit()
    g_iMaxPlayers = get_maxplayers()
}

public plugin_precache()
{
    g_aCamper = ArrayCreate(CAMPER)
    g_aCamperConfig = ArrayCreate(CAMPER)
    g_eSettings[SETTING_DEFAULT_WARNING_MESSAGE] = ArrayCreate(MAX_VALUE_LENGTH)

    ReadFile()
}

public plugin_end()
{
    ArrayDestroy(g_aCamper)
    ArrayDestroy(g_aCamperConfig)
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_WARNING_MESSAGE])
}

public cmdMenu(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    camperSound(id, SOUND_MENU_NAV)
    camperMenu(id, MENU_ROOT)

    return PLUGIN_HANDLED
}

public cmdReload(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    ReadFile()
    console_print(id, "The configuration file has been reloaded successfully !")

    return PLUGIN_HANDLED
}

public eventRoundStart()
{
    for ( new id = 1; id <= g_iMaxPlayers; id ++ )
        camperResetPlayer(id)
}

ReadFile()
{
    new eCamper[CAMPER]
    if ( g_bFileWasRead )
    {
        ArrayClear(g_eSettings[SETTING_DEFAULT_WARNING_MESSAGE])
        ArrayClear(g_aCamperConfig)
        g_iCamperConfig = 0
    }

    new g_szFileName[MAX_RESOURCE_PATH_LENGTH]
    get_configsdir(g_szFileName, charsmax(g_szFileName))
    add(g_szFileName, charsmax(g_szFileName), "/CamperZone.ini")

    new iFile
    iFile = fopen(g_szFileName, "rt")

    if ( !iFile )
    {
        set_fail_state("An error occured during the opening of the configuration file !")
    }

    new szData[MAX_FILE_CELL_SIZE],
        szKey[MAX_VALUE_LENGTH], szValue[MAX_RESOURCE_PATH_LENGTH],
        iSection = SECTION_NONE, iLine, iPos

    while( !feof(iFile) )
    {
        iLine ++
        fgets(iFile, szData, charsmax(szData))
        trim(szData)

        switch( szData[0] )
        {
            case EOS, ';', '#':
            {
                continue
            }
            case '[':
            {
                if ( szData[strlen(szData) - 1] == ']' )
                {
                    replace(szData, charsmax( szData ), "[", "")
                    replace(szData, charsmax( szData ), "]", "")
                    trim(szData)

                    if ( equali(szData, "Main Settings") )
                    {
                        iSection = SECTION_MAIN_SETTINGS
                        continue
                    }
                    else
                    {
                        if ( g_iCamperConfig )
                            ArrayPushArray(g_aCamperConfig, eCamper)

                        copy(eCamper[CAMPER_NAME], charsmax(eCamper[CAMPER_NAME]), szData)
                        eCamper[CAMPER_FLAGS]                       = g_eSettings[SETTING_DEFAULT_FLAGS]
                        eCamper[CAMPER_TEAM]                        = g_eSettings[SETTING_DEFAULT_TEAM]

                        eCamper[CAMPER_WARNING_DELAY]               = g_eSettings[SETTING_DEFAULT_WARNING_DELAY]
                        eCamper[CAMPER_WARNING_COOLDOWN][0]         = g_eSettings[SETTING_DEFAULT_WARNING_COOLDOWN][0]
                        eCamper[CAMPER_WARNING_COOLDOWN][1]         = g_eSettings[SETTING_DEFAULT_WARNING_COOLDOWN][1]
                        eCamper[CAMPER_WARNING_MESSAGE]             = ArrayClone(g_eSettings[SETTING_DEFAULT_WARNING_MESSAGE])
                        eCamper[CAMPER_WARNING_MESSAGE_COUNT]       = g_eSettings[SETTING_DEFAULT_WARNING_MESSAGE_COUNT]

                        eCamper[CAMPER_DAMAGE][0]                   = g_eSettings[SETTING_DEFAULT_DAMAGE][0]
                        eCamper[CAMPER_DAMAGE][1]                   = g_eSettings[SETTING_DEFAULT_DAMAGE][1]
                        eCamper[CAMPER_DAMAGE_TICK][0]              = g_eSettings[SETTING_DEFAULT_DAMAGE_TICK][0]
                        eCamper[CAMPER_DAMAGE_TICK][1]              = g_eSettings[SETTING_DEFAULT_DAMAGE_TICK][1]
                        eCamper[CAMPER_DAMAGE_DELAY]                = g_eSettings[SETTING_DEFAULT_DAMAGE_DELAY]
                        eCamper[CAMPER_DAMAGE_RESET_DELAY]          = g_eSettings[SETTING_DEFAULT_DAMAGE_RESET_DELAY]
                        eCamper[CAMPER_DAMAGE_MULTIPLIER_DELAY]     = g_eSettings[SETTING_DEFAULT_DAMAGE_MULTIPLIER_DELAY]
                        eCamper[CAMPER_DAMAGE_MULTIPLIER]           = g_eSettings[SETTING_DEFAULT_DAMAGE_MULTIPLIER]
                        eCamper[CAMPER_DAMAGETYPE]                  = g_eSettings[SETTING_DEFAULT_DAMAGETYPE]

                        iSection = SECTION_CAMPER
                        g_iCamperConfig ++
                    }
                }
                else
                {
                    LogConfigError(iLine, "Unclosed section name: %s", szData)
                    iSection = SECTION_NONE
                }
            }
            default:
            {
                strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
                iPos = contain(szValue, "#")
                if ( iPos != -1 )
                    szValue[iPos] = EOS

                trim(szKey)
                trim(szValue)

                switch( iSection )
                {
                    case SECTION_NONE:
                    {
                        LogConfigError(iLine, "Data is not in any defined section: %s", szData)
                    }
                    case SECTION_MAIN_SETTINGS:
                    {
                        strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
                        iPos = contain(szValue, "#")
                        if ( iPos != -1 )
                            szValue[iPos] = EOS

                        trim(szKey)
                        trim(szValue)

                        if ( equali(szKey, "SETTING_DEFAULT_MODEL") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_MODEL], charsmax(g_eSettings[SETTING_DEFAULT_MODEL]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FLAGS], charsmax(g_eSettings[SETTING_DEFAULT_FLAGS]))
                        else if ( equali(szKey, "SETTING_DEFAULT_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_TEAM], charsmax(g_eSettings[SETTING_DEFAULT_TEAM]))
                        else if ( equali(szKey, "SETTING_DEFAULT_WARNING_DELAY") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_WARNING_DELAY], charsmax(g_eSettings[SETTING_DEFAULT_WARNING_DELAY]))
                        else if ( equali(szKey, "SETTING_DEFAULT_WARNING_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_WARNING_COOLDOWN], charsmax(g_eSettings[SETTING_DEFAULT_WARNING_COOLDOWN]))
                        else if ( equali(szKey, "SETTING_DEFAULT_WARNING_MESSAGE") )
                        {
                            parseSetting(DTYPE_ARRAY_MESSAGE, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_WARNING_MESSAGE], charsmax(g_eSettings[SETTING_DEFAULT_WARNING_MESSAGE]))
                            g_eSettings[SETTING_DEFAULT_WARNING_MESSAGE_COUNT] ++
                        }
                        else if ( equali(szKey, "SETTING_DEFAULT_DAMAGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_DAMAGE], charsmax(g_eSettings[SETTING_DEFAULT_DAMAGE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_DAMAGE_TICK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_DAMAGE_TICK], charsmax(g_eSettings[SETTING_DEFAULT_DAMAGE_TICK]))
                        else if ( equali(szKey, "SETTING_DEFAULT_DAMAGE_DELAY") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_DAMAGE_DELAY], charsmax(g_eSettings[SETTING_DEFAULT_DAMAGE_DELAY]))
                        else if ( equali(szKey, "SETTING_DEFAULT_DAMAGE_RESET_DELAY") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_DAMAGE_RESET_DELAY], charsmax(g_eSettings[SETTING_DEFAULT_DAMAGE_RESET_DELAY]))
                        else if ( equali(szKey, "SETTING_DEFAULT_DAMAGE_MULTIPLIER_DELAY") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_DAMAGE_MULTIPLIER_DELAY], charsmax(g_eSettings[SETTING_DEFAULT_DAMAGE_MULTIPLIER_DELAY]))
                        else if ( equali(szKey, "SETTING_DEFAULT_DAMAGE_MULTIPLIER") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_DAMAGE_MULTIPLIER], charsmax(g_eSettings[SETTING_DEFAULT_DAMAGE_MULTIPLIER]))
                        else if ( equali(szKey, "SETTING_DEFAULT_DAMAGETYPE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_DAMAGETYPE], charsmax(g_eSettings[SETTING_DEFAULT_DAMAGETYPE]))
                        else if ( equali(szKey, "SETTING_CAMPER_LOAD") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_CAMPER_LOAD], charsmax(g_eSettings[SETTING_CAMPER_LOAD]))
                        else if ( equali(szKey, "SETTING_CAMPER_TASK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_CAMPER_TASK], charsmax(g_eSettings[SETTING_CAMPER_TASK]))
                        else if ( equali(szKey, "SETTING_SIZE_BASE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_SIZE_BASE], charsmax(g_eSettings[SETTING_SIZE_BASE]))
                        else if ( equali(szKey, "SETTING_SIZE_HEIGHT") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_SIZE_HEIGHT], charsmax(g_eSettings[SETTING_SIZE_HEIGHT]))
                        else if ( equali(szKey, "SETTING_SIZE_WIDTH") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_SIZE_WIDTH], charsmax(g_eSettings[SETTING_SIZE_WIDTH]))
                        else if ( equali(szKey, "SETTING_SIZE_DEPTH") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_SIZE_DEPTH], charsmax(g_eSettings[SETTING_SIZE_DEPTH]))
                        else if ( equali(szKey, "SETTING_BEAM") )
                            parseSetting(DTYPE_STRING_MODEL_ID, szValue, charsmax(szValue), g_eSettings[SETTING_BEAM], charsmax(g_eSettings[SETTING_BEAM]))
                        else if ( equali(szKey, "SETTING_BEAM_WIDTH") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_BEAM_WIDTH], charsmax(g_eSettings[SETTING_BEAM_WIDTH]))
                        else if ( equali(szKey, "SETTING_BEAM_ALPHA") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_BEAM_ALPHA], charsmax(g_eSettings[SETTING_BEAM_ALPHA]))
                    }
                    case SECTION_CAMPER:
                    {
                        if ( equali(szKey, "CAMPER_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), eCamper[CAMPER_FLAGS], charsmax(eCamper[CAMPER_FLAGS]))
                        else if ( equali(szKey, "CAMPER_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eCamper[CAMPER_TEAM], charsmax(eCamper[CAMPER_TEAM]))
                        else if ( equali(szKey, "CAMPER_DAMAGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eCamper[CAMPER_DAMAGE], charsmax(eCamper[CAMPER_DAMAGE]))
                        else if ( equali(szKey, "CAMPER_DAMAGE_TICK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eCamper[CAMPER_DAMAGE_TICK], charsmax(eCamper[CAMPER_DAMAGE_TICK]))
                        else if ( equali(szKey, "CAMPER_DAMAGE_DELAY") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eCamper[CAMPER_DAMAGE_DELAY], charsmax(eCamper[CAMPER_DAMAGE_DELAY]))
                        else if ( equali(szKey, "CAMPER_DAMAGE_RESET_DELAY") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eCamper[CAMPER_DAMAGE_RESET_DELAY], charsmax(eCamper[CAMPER_DAMAGE_RESET_DELAY]))
                        else if ( equali(szKey, "CAMPER_DAMAGE_MULTIPLIER_DELAY") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eCamper[CAMPER_DAMAGE_MULTIPLIER_DELAY], charsmax(eCamper[CAMPER_DAMAGE_MULTIPLIER_DELAY]))
                        else if ( equali(szKey, "CAMPER_DAMAGE_MULTIPLIER") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eCamper[CAMPER_DAMAGE_MULTIPLIER], charsmax(eCamper[CAMPER_DAMAGE_MULTIPLIER]))
                        else if ( equali(szKey, "CAMPER_WARNING_DELAY") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eCamper[CAMPER_WARNING_DELAY], charsmax(eCamper[CAMPER_WARNING_DELAY]))
                        else if ( equali(szKey, "CAMPER_WARNING_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eCamper[CAMPER_WARNING_COOLDOWN], charsmax(eCamper[CAMPER_WARNING_COOLDOWN]))
                        else if ( equali(szKey, "CAMPER_WARNING_MESSAGE") )
                        {
                            if ( !(eCamper[CAMPER_FLAGS] & FLAG_MESSAGE) )
                            {
                                ArrayClear(eCamper[CAMPER_WARNING_MESSAGE])

                                eCamper[CAMPER_FLAGS] |= FLAG_MESSAGE
                                eCamper[CAMPER_WARNING_MESSAGE_COUNT] = 0
                            }

                            parseSetting(DTYPE_ARRAY_MESSAGE, szValue, charsmax(szValue), eCamper[CAMPER_WARNING_MESSAGE], charsmax(eCamper[CAMPER_WARNING_MESSAGE]))
                            eCamper[CAMPER_WARNING_MESSAGE_COUNT] ++
                        }
                        else if ( equali(szKey, "CAMPER_DAMAGETYPE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eCamper[CAMPER_DAMAGETYPE], charsmax(eCamper[CAMPER_DAMAGETYPE]))
                    }
                }
            }
        }
    }

    if ( g_iCamperConfig )
        ArrayPushArray(g_aCamperConfig, eCamper)
    else
        set_fail_state("No Campers were found in the configuration file.")

    g_bFileWasRead = true
    fclose(iFile)
}

public client_disconnected(id)
{
    new eCamper[CAMPER], iItem
    if ((iItem = camperGet(eCamper, g_ePlayerData[id][PDATA_CAMPER_GHOST])) != -1 )
    {
        camperKill(eCamper[CAMPER_ID])
        camperRemove(iItem)
    }

    DisableAction(id)
    g_ePlayerData[id][PDATA_CAMPER_GHOST]   = 0
    g_ePlayerData[id][PDATA_CAMPER_MENU]    = 0
}

public camperInit()
{
    if ( g_eSettings[SETTING_CAMPER_LOAD] )
        set_task(DELAY_ON_LOAD, "loadData")
}

stock camperTerminate()
{
    new eCamper[CAMPER]
    for ( new i = 0; i < g_iCamper; i ++ )
    {
        ArrayGetArray(g_aCamper, i, eCamper)
        eCamper[CAMPER_FLAGS] &= ~FLAG_SELECT
        ArraySetArray(g_aCamper, i, eCamper)
    }
}

stock camperMenu(id, iType)
{
    if ( !is_user_connected(id) )
        return PLUGIN_HANDLED

    new szData[256], iMenu
    formatex(szData, charsmax(szData), "%L", id, "CAMPER_MENU_TITLE", PLUGIN_VERSION)
    iMenu = menu_create(szData, g_szMenuHandler[iType])
    switch( iType )
    {
        case MENU_ROOT:         { menuRoot(id, iMenu); }
        case MENU_CREATE:       { menuCreate(iMenu);            format(szData, charsmax(szData), "%s^n%L", szData, id, "CAMPER_ROOT_CREATE"); }
        case MENU_EDIT:         { menuEdit(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "CAMPER_ROOT_EDIT"); }
        case MENU_REMOVE:       { menuRemove(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "CAMPER_ROOT_REMOVE"); }
        case MENU_STATUS:       { menuStatus(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "CAMPER_ROOT_STATUS"); }
        case MENU_SCALE:        { menuScale(id, iMenu);         format(szData, charsmax(szData), "%s^n%L", szData, id, "CAMPER_ROOT_SCALE"); }
    }

    if ( menu_pages(iMenu) > 1 )
        format(szData, charsmax(szData), "%s^n%L", szData, id, "CAMPER_MENU_TITLE_PAGE")

    menu_setprop(iMenu, MPROP_TITLE, szData)
    menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
    menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\r")

    menu_display(id, iMenu)
    return PLUGIN_HANDLED
}

stock menuNav(id, iMenu)
{
    new szItem[64]

    formatex(szItem, charsmax(szItem), "%L", id, "CAMPER_NAV_NEXT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAMPER_NAV_BACK")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)
}

public menuRoot(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "CAMPER_ROOT_CREATE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAMPER_ROOT_EDIT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAMPER_ROOT_REMOVE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAMPER_ROOT_SAVE")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "CAMPER_ROOT_NOCLIP", id, (pev(id, pev_movetype) == MOVETYPE_NOCLIP) ? "CAMPER_ON" : "CAMPER_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAMPER_ROOT_GODMODE", id, (pev(id, pev_takedamage) == DAMAGE_NO) ? "CAMPER_ON" : "CAMPER_OFF")
    menu_additem(iMenu, szItem)
}

public menuHandlerRoot(id, menu, item)
{
    if ( item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROOT_CREATE:
        {
            if ( g_iCamper >= MAX_ENT )
            {
                client_print_color(id, id, "%L %L", id, "CAMPER_CHAT_TAG", id, "CAMPER_CHAT_LIMIT", MAX_ENT)

                camperSound(id, SOUND_MENU_REMOVE)
                camperMenu(id, MENU_ROOT)
            }
            else
            {
                camperSound(id, SOUND_MENU_NAV)
                camperMenu(id, MENU_CREATE)
            }
        }
        case ROOT_EDIT:
        {
            if ( !g_iCamper )
            {
                client_print_color(id, id, "%L %L", id, "CAMPER_CHAT_TAG", id, "CAMPER_CHAT_NO_CAMPER")

                camperSound(id, SOUND_MENU_REMOVE)
                camperMenu(id, MENU_ROOT)
            }
            else
            {
                camperSound(id, SOUND_MENU_NAV)
                camperMenu(id, MENU_EDIT)
            }
        }
        case ROOT_REMOVE:
        {
            if ( !g_iCamper )
            {
                client_print_color(id, id, "%L %L", id, "CAMPER_CHAT_TAG", id, "CAMPER_CHAT_NO_CAMPER")

                camperSound(id, SOUND_MENU_REMOVE)
                camperMenu(id, MENU_ROOT)
            }
            else
            {
                camperSound(id, SOUND_MENU_REMOVE)
                camperMenu(id, MENU_REMOVE)
            }
        }
        case ROOT_SAVE:
        {
            saveData(id)
        }
        case ROOT_NOCLIP:
        {
            camperNoClip(id)
        }
        case ROOT_GODMODE:
        {
            camperGodMode(id)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuCreate(iMenu)
{
    new eCamper[CAMPER], szItem[64]
    for ( new i = 0; i < g_iCamperConfig; i ++ )
    {
        ArrayGetArray(g_aCamperConfig, i, eCamper)

        copy(szItem, charsmax(szItem), eCamper[CAMPER_NAME])
        menu_additem(iMenu, szItem)
    }
}

public menuHandlerCreate(id, menu, item)
{
    if ( !is_user_alive(id) )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    else if ( item == MENU_EXIT )
    {
        camperSound(id, SOUND_MENU_NAV)
        camperMenu(id, MENU_ROOT)

        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    camperCreate(id, item)
    camperSound(id, SOUND_MENU_NAV)
    camperMenu(id, MENU_SCALE)

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuEdit(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "CAMPER_EDIT_STATUS")
    menu_additem(iMenu, szItem)
}

public menuHandlerEdit(id, menu, item)
{
    switch( item )
    {
        case EDIT_STATUS:
        {
            camperSound(id, SOUND_MENU_NAV)
            camperMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            camperSound(id, SOUND_MENU_NAV)
            camperMenu(id, MENU_ROOT)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRemove(id, iMenu)
{
    new szItem[64], eCamper[CAMPER]
    menuNav(id, iMenu)
    ArrayGetArray(g_aCamper, g_ePlayerData[id][PDATA_CAMPER_MENU], eCamper)

    formatex(szItem, charsmax(szItem), "%L", id, "CAMPER_REMOVE_CURRENT", eCamper[CAMPER_NAME])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAMPER_REMOVE_ALL")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    camperSelect(eCamper, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_REMOVE
    ArraySetArray(g_aCamper, g_ePlayerData[id][PDATA_CAMPER_MENU], eCamper)
}

public menuHandlerRemove(id, menu, item)
{
    new eCamper[CAMPER]
    ArrayGetArray(g_aCamper, g_ePlayerData[id][PDATA_CAMPER_MENU], eCamper)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
    {
        camperSelect(eCamper, eCamper[CAMPER_FLAGS] & FLAG_ACTIVE ? TARGET_HIDE : TARGET_GHOST)
        ArraySetArray(g_aCamper, g_ePlayerData[id][PDATA_CAMPER_MENU], eCamper)
    }

    switch( item )
    {
        case REMOVE_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_CAMPER_MENU] >= g_iCamper - 1 )
                g_ePlayerData[id][PDATA_CAMPER_MENU] = 0
            else
                g_ePlayerData[id][PDATA_CAMPER_MENU] ++

            camperSound(id, SOUND_MENU_NAV)
            camperMenu(id, MENU_REMOVE)
        }
        case REMOVE_BACK:
        {
            if ( g_ePlayerData[id][PDATA_CAMPER_MENU] <= 0 )
                g_ePlayerData[id][PDATA_CAMPER_MENU] = g_iCamper - 1
            else
                g_ePlayerData[id][PDATA_CAMPER_MENU] --

            camperSound(id, SOUND_MENU_NAV)
            camperMenu(id, MENU_REMOVE)
        }
        case REMOVE_CURRENT:
        {
            camperKill(eCamper[CAMPER_ID])
            camperRemove(g_ePlayerData[id][PDATA_CAMPER_MENU])

            client_print_color(id, id, "%L %L", id, "CAMPER_CHAT_TAG", id, "CAMPER_CHAT_REMOVE_CURRENT", eCamper[CAMPER_NAME])
            g_ePlayerData[id][PDATA_CAMPER_MENU] = 0

            camperSound(id, g_iCamper > 0 ? SOUND_MENU_REMOVE : SOUND_MENU_NAV)
            camperMenu(id, g_iCamper > 0 ? MENU_REMOVE : MENU_ROOT)
        }
        case REMOVE_ALL:
        {
            while( g_iCamper )
            {
                ArrayGetArray(g_aCamper, 0, eCamper)
                camperKill(eCamper[CAMPER_ID])
                camperRemove(0)
            }

            client_print_color(id, id, "%L %L", id, "CAMPER_CHAT_TAG", id, "CAMPER_CHAT_REMOVE_ALL")
            g_ePlayerData[id][PDATA_CAMPER_MENU] = 0

            camperSound(id, SOUND_MENU_ALERT)
            camperMenu(id, MENU_ROOT)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                camperSound(id, SOUND_MENU_NAV)
                camperMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_CAMPER_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_CAMPER_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuStatus(id, iMenu)
{
    new szItem[64], eCamper[CAMPER]
    menuNav(id, iMenu)
    ArrayGetArray(g_aCamper, g_ePlayerData[id][PDATA_CAMPER_MENU], eCamper)

    formatex(szItem, charsmax(szItem), "%L", id, "CAMPER_STATUS_CURRENT",
    eCamper[CAMPER_FLAGS] & FLAG_ACTIVE ? "\y" : "\r", eCamper[CAMPER_NAME], id, eCamper[CAMPER_FLAGS] & FLAG_ACTIVE ? "CAMPER_ENABLED" : "CAMPER_DISABLED")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAMPER_STATUS_ALL_ENABLE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAMPER_STATUS_ALL_DISABLE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    camperSelect(eCamper, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_STATUS
    ArraySetArray(g_aCamper, g_ePlayerData[id][PDATA_CAMPER_MENU], eCamper)
}

public menuHandlerStatus(id, menu, item)
{
    new eCamper[CAMPER]
    ArrayGetArray(g_aCamper, g_ePlayerData[id][PDATA_CAMPER_MENU], eCamper)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
    {
        camperSelect(eCamper, eCamper[CAMPER_FLAGS] & FLAG_ACTIVE ? TARGET_HIDE : TARGET_GHOST)
        ArraySetArray(g_aCamper, g_ePlayerData[id][PDATA_CAMPER_MENU], eCamper)
    }

    switch( item )
    {
        case STATUS_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_CAMPER_MENU] >= g_iCamper - 1 )
                g_ePlayerData[id][PDATA_CAMPER_MENU] = 0
            else
                g_ePlayerData[id][PDATA_CAMPER_MENU] ++

            camperSound(id, SOUND_MENU_NAV)
            camperMenu(id, MENU_STATUS)
        }
        case STATUS_BACK:
        {
            if ( g_ePlayerData[id][PDATA_CAMPER_MENU] <= 0 )
                g_ePlayerData[id][PDATA_CAMPER_MENU] = g_iCamper - 1
            else
                g_ePlayerData[id][PDATA_CAMPER_MENU] --

            camperSound(id, SOUND_MENU_NAV)
            camperMenu(id, MENU_STATUS)
        }
        case STATUS_CURRENT:
        {
            eCamper[CAMPER_FLAGS] ^= FLAG_ACTIVE

            client_print_color(id, id, "%L %L", id, "CAMPER_CHAT_TAG", id, "CAMPER_CHAT_STATUS_CURRENT", eCamper[CAMPER_NAME],
            id, eCamper[CAMPER_FLAGS] & FLAG_ACTIVE ? "CAMPER_CHAT_ENABLED" : "CAMPER_CHAT_DISABLED")
            ArraySetArray(g_aCamper, g_ePlayerData[id][PDATA_CAMPER_MENU], eCamper)

            camperSound(id, SOUND_MENU_NAV)
            camperMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_ENABLE:
        {
            for ( new i = 0; i < g_iCamper; i ++ )
            {
                ArrayGetArray(g_aCamper, i, eCamper)
                eCamper[CAMPER_FLAGS] |= FLAG_ACTIVE
                ArraySetArray(g_aCamper, i, eCamper)
            }

            client_print_color(id, id, "%L %L", id, "CAMPER_CHAT_TAG", id, "CAMPER_CHAT_STATUS_ALL_ENABLED")
            camperSound(id, SOUND_MENU_ALERT)
            camperMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_DISABLE:
        {
            for ( new i = 0; i < g_iCamper; i ++ )
            {
                ArrayGetArray(g_aCamper, i, eCamper)
                eCamper[CAMPER_FLAGS] &= ~FLAG_ACTIVE
                ArraySetArray(g_aCamper, i, eCamper)
            }

            client_print_color(id, id, "%L %L", id, "CAMPER_CHAT_TAG", id, "CAMPER_CHAT_STATUS_ALL_DISABLED")
            camperSound(id, SOUND_MENU_ALERT)
            camperMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                camperSound(id, SOUND_MENU_NAV)
                camperMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_CAMPER_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_CAMPER_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuScale(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "CAMPER_SCALE_HEIGHT", id, g_ePlayerData[id][PDATA_SCALE_UP] ? "CAMPER_ADD" : "CAMPER_REMOVE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAMPER_SCALE_WIDTH", id, g_ePlayerData[id][PDATA_SCALE_UP] ? "CAMPER_ADD" : "CAMPER_REMOVE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAMPER_SCALE_DEPTH", id, g_ePlayerData[id][PDATA_SCALE_UP] ? "CAMPER_ADD" : "CAMPER_REMOVE")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "CAMPER_SCALE_FACTOR", g_ePlayerData[id][PDATA_SCALE_UP] ? "\y" : "\r", g_fScaleFactor[g_ePlayerData[id][PDATA_SCALE_FACTOR]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAMPER_SCALE_MODE", id, g_ePlayerData[id][PDATA_SCALE_UP] ? "CAMPER_INCREASE" : "CAMPER_DECREASE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAMPER_SCALE_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerScale(id, menu, item)
{
    new eCamper[CAMPER], iItem
    if ( (iItem = camperGet(eCamper, g_ePlayerData[id][PDATA_CAMPER_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case SCALE_HEIGHT:
        {
            if ( g_ePlayerData[id][PDATA_SCALE_UP] )
            {
                eCamper[CAMPER_SCALE][2] += g_fScaleFactor[g_ePlayerData[id][PDATA_SCALE_FACTOR]]
                if (eCamper[CAMPER_SCALE][2] > g_eSettings[SETTING_SIZE_HEIGHT][1])
                    eCamper[CAMPER_SCALE][2] = g_eSettings[SETTING_SIZE_HEIGHT][1]
            }
            else
            {
                eCamper[CAMPER_SCALE][2] -= g_fScaleFactor[g_ePlayerData[id][PDATA_SCALE_FACTOR]]
                if (eCamper[CAMPER_SCALE][2] < g_eSettings[SETTING_SIZE_HEIGHT][0])
                    eCamper[CAMPER_SCALE][2] = g_eSettings[SETTING_SIZE_HEIGHT][0]
            }

            ArraySetArray(g_aCamper, iItem, eCamper)
            camperSound(id, SOUND_MENU_NAV)
            camperMenu(id, MENU_SCALE)
        }
        case SCALE_WIDTH:
        {
            if ( g_ePlayerData[id][PDATA_SCALE_UP] )
            {
                eCamper[CAMPER_SCALE][0] += g_fScaleFactor[g_ePlayerData[id][PDATA_SCALE_FACTOR]]
                if (eCamper[CAMPER_SCALE][0] > g_eSettings[SETTING_SIZE_WIDTH][1])
                    eCamper[CAMPER_SCALE][0] = g_eSettings[SETTING_SIZE_WIDTH][1]
            }
            else
            {
                eCamper[CAMPER_SCALE][0] -= g_fScaleFactor[g_ePlayerData[id][PDATA_SCALE_FACTOR]]
                if (eCamper[CAMPER_SCALE][0] < g_eSettings[SETTING_SIZE_WIDTH][0])
                    eCamper[CAMPER_SCALE][0] = g_eSettings[SETTING_SIZE_WIDTH][0]
            }

            ArraySetArray(g_aCamper, iItem, eCamper)
            camperSound(id, SOUND_MENU_NAV)
            camperMenu(id, MENU_SCALE)
        }
        case SCALE_DEPTH:
        {
            if ( g_ePlayerData[id][PDATA_SCALE_UP] )
            {
                eCamper[CAMPER_SCALE][1] += g_fScaleFactor[g_ePlayerData[id][PDATA_SCALE_FACTOR]]
                if (eCamper[CAMPER_SCALE][1] > g_eSettings[SETTING_SIZE_DEPTH][1])
                    eCamper[CAMPER_SCALE][1] = g_eSettings[SETTING_SIZE_DEPTH][1]
            }
            else
            {
                eCamper[CAMPER_SCALE][1] -= g_fScaleFactor[g_ePlayerData[id][PDATA_SCALE_FACTOR]]
                if (eCamper[CAMPER_SCALE][1] < g_eSettings[SETTING_SIZE_DEPTH][0])
                    eCamper[CAMPER_SCALE][1] = g_eSettings[SETTING_SIZE_DEPTH][0]
            }

            ArraySetArray(g_aCamper, iItem, eCamper)
            camperSound(id, SOUND_MENU_NAV)
            camperMenu(id, MENU_SCALE)
        }
        case SCALE_FACTOR:
        {
            g_ePlayerData[id][PDATA_SCALE_FACTOR] += 1
            if ( g_ePlayerData[id][PDATA_SCALE_FACTOR] >= sizeof(g_fScaleFactor) )
                g_ePlayerData[id][PDATA_SCALE_FACTOR] = 0

            camperSound(id, SOUND_MENU_NAV)
            camperMenu(id, MENU_SCALE)
        }
        case SCALE_MODE:
        {
            g_ePlayerData[id][PDATA_SCALE_UP] = !g_ePlayerData[id][PDATA_SCALE_UP]

            camperSound(id, SOUND_MENU_NAV)
            camperMenu(id, MENU_SCALE)
        }
        case SCALE_PLACE:
        {
            camperTrace(eCamper, id)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_CAMPER_GHOST] = 0

            eCamper[CAMPER_FLAGS] |= FLAG_ACTIVE
            camperSetSeq(eCamper[CAMPER_ID])
            camperSetSize(eCamper)
            ArraySetArray(g_aCamper, iItem, eCamper)

            client_print_color(id, id, "%L %L", id, "CAMPER_CHAT_TAG", id, "CAMPER_CHAT_CREATE_NEW", eCamper[CAMPER_NAME])
            camperSound(id, SOUND_MENU_NAV)
            camperMenu(id, MENU_ROOT)
        }
        case MENU_EXIT:
        {
            camperKill(eCamper[CAMPER_ID])
            camperRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_CAMPER_GHOST] = 0

            camperSound(id, SOUND_MENU_NAV)
            camperMenu(id, MENU_ROOT)
        }
        default:
        {
            camperKill(eCamper[CAMPER_ID])
            camperRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_CAMPER_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public camperTask()
{
    new eCamper[CAMPER]
    for ( new id = 1; id <= g_iMaxPlayers; id ++ )
    {
        if ( !is_user_alive(id) )
            continue

        if ( !g_ePlayerData[id][PDATA_CAMPER_GHOST] )
        {
            if ( g_ePlayerData[id][PDATA_CAMPER_ACTION] )
                camperCheck(id)
        }
        else if ( camperGet(eCamper, g_ePlayerData[id][PDATA_CAMPER_GHOST]) != -1 )
        {
            camperTrace(eCamper, id)
        }
    }

    for ( new i = 0; i < g_iCamper; i ++ )
    {
        ArrayGetArray(g_aCamper, i, eCamper)
        if ( eCamper[CAMPER_FLAGS] & FLAG_SELECT )
            camperBeam(eCamper)

        if ( eCamper[CAMPER_FLAGS] & FLAG_ACTIVE )
            camperPlayer(eCamper)
    }
}

public camperCreate(id, iItem)
{
    new iEnt = cs_create_entity("info_target")
    if ( !pev_valid(iEnt) )
        return

    new eCamper[CAMPER]
    ArrayGetArray(g_aCamperConfig, iItem, eCamper)
    eCamper[CAMPER_ID] = iEnt
    eCamper[CAMPER_SCALE][0] = eCamper[CAMPER_SCALE][1] = eCamper[CAMPER_SCALE][2] = g_eSettings[SETTING_SIZE_BASE]
    if ( id )
    {
        EnableAction(id)
        g_ePlayerData[id][PDATA_CAMPER_GHOST] = iEnt
        g_ePlayerData[id][PDATA_CAMPER_ACTION] = true
        g_ePlayerData[id][PDATA_SCALE_UP] = true
        g_ePlayerData[id][PDATA_SCALE_FACTOR] = 0
        g_ePlayerData[id][PDATA_OFFSET] = CAMPER_OFFSET_BASE
    }

    camperSelect(eCamper, TARGET_GHOST)
    set_pev(iEnt, pev_classname, g_szCN)
    set_pev(iEnt, pev_impulse, CAMPER_KEY)
    set_pev(iEnt, CAMPER_ARRAY_ITEM, g_iCamper)
    dllfunc(DLLFunc_Spawn, iEnt)
    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
    engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_DEFAULT_MODEL])

    ArrayPushArray(g_aCamper, eCamper)
    if ( ++ g_iCamper == 1 )
        set_task(g_eSettings[SETTING_CAMPER_TASK], "camperTask", CAMPER_KEY, .flags = "b")
}

stock camperRemove(iItem)
{
    new eCamper[CAMPER]
    ArrayDeleteItem(g_aCamper, iItem)

    if ( -- g_iCamper == 0 )
        remove_task(CAMPER_KEY)

    for ( new i = iItem; i < g_iCamper; i ++ )
    {
        ArrayGetArray(g_aCamper, i, eCamper)
        set_pev(eCamper[CAMPER_ID], CAMPER_ARRAY_ITEM, i)
    }
}

public saveData(id)
{
    new eCamper[CAMPER],
        szFile[128], iFile,
        szData[64]

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_CamperZone.ini", szFile)

    iFile = fopen(szFile, "wt")
    if ( !iFile )
        return PLUGIN_HANDLED

    camperTerminate()
    for ( new i = 0; i < g_iCamper; i ++ )
    {
        ArrayGetArray(g_aCamper, i, eCamper)

        formatex(szData, charsmax(szData), "[%d]^n", i)
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "item = %d^n", eCamper[CAMPER_ITEM])
        fputs(iFile, szData)

        eCamper[CAMPER_FLAGS] &= ~(FLAG_SELECT | FLAG_GHOST)
        formatex(szData, charsmax(szData), "flags = %d^n", eCamper[CAMPER_FLAGS])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "scale = %.2f %.2f %.2f^n",
        eCamper[CAMPER_SCALE][0], eCamper[CAMPER_SCALE][1], eCamper[CAMPER_SCALE][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "origin = %.2f %.2f %.2f^n",
        eCamper[CAMPER_ORIGIN][0], eCamper[CAMPER_ORIGIN][1], eCamper[CAMPER_ORIGIN][2])
        fputs(iFile, szData)

        for ( new j = 0; j < 8; j ++ )
        {
            formatex(szData, charsmax(szData), "corner_%d = %.2f %.2f %.2f^n",
            j + 1, eCamper[CAMPER_CORNERS][j * 3], eCamper[CAMPER_CORNERS][(j * 3) + 1], eCamper[CAMPER_CORNERS][(j * 3) + 2])
            fputs(iFile, szData)
        }
    }

    client_print_color(id, id, "%L %L", id, "CAMPER_CHAT_TAG", id, "CAMPER_CHAT_SAVE", szFile)
    fclose(iFile)

    camperSound(id, SOUND_MENU_NAV)
    camperMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public loadData()
{
    new szFile[128], iFile,
        szData[64], szKey[32], szValue[32],
        iItem, iFlags, Float:fScale[3], Float:fOrigin[3], Float:fCorners[24],
        iCorner, iCount = -1

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_CamperZone.ini", szFile)

    iFile = fopen(szFile, "rt")
    if ( !iFile )
        return PLUGIN_HANDLED

    while( !feof(iFile) )
    {
        fgets(iFile, szData, charsmax(szData))

        if ( szData[0] == '[' )
        {
            if ( iCount != -1 )
                loadDataCamper(iItem, iFlags, fOrigin, fScale, fCorners, iCount)

            iCount ++
        }
        else
        {
            strtok(szData, szKey, charsmax( szKey ), szValue, charsmax( szValue ), '=')
            trim(szKey)
            trim(szValue)

            if ( equal(szKey, "flags") )
            {
                iFlags = str_to_num(szValue)
            }
            else if ( equal(szKey, "item") )
            {
                iItem = str_to_num(szValue)
            }
            else if ( equal(szKey, "scale") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fScale[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fScale[1] = str_to_float(szKey)
                fScale[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "origin") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[1] = str_to_float(szKey)
                fOrigin[2] = str_to_float(szValue)
            }
            else if ( contain(szKey, "corner") != -1 )
            {
                iCorner = str_to_num(szKey[7])

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fCorners[(iCorner - 1) * 3] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fCorners[(iCorner - 1) * 3 + 1] = str_to_float(szKey)
                fCorners[(iCorner - 1) * 3 + 2] = str_to_float(szValue)
            }
        }
    }

    if ( iCount != -1 )
        loadDataCamper(iItem, iFlags, fOrigin, fScale, fCorners, iCount)

    fclose(iFile)
    return PLUGIN_HANDLED
}

stock loadDataCamper(iItem, iFlags, Float:fOrigin[3], Float:fScale[3], Float:fCorners[24], iCount)
{
    new eCamper[CAMPER]
    camperCreate(0, iItem)
    ArrayGetArray(g_aCamper, iCount, eCamper)

    eCamper[CAMPER_FLAGS] = iFlags
    xs_vec_copy(fScale, eCamper[CAMPER_SCALE])
    xs_vec_copy(fOrigin, eCamper[CAMPER_ORIGIN])
    for ( new i = 0; i < 24; i ++ )
        eCamper[CAMPER_CORNERS][i] = fCorners[i]

    camperSetSeq(eCamper[CAMPER_ID])
    camperSetBox(eCamper)
    camperSetSize(eCamper)
    ArraySetArray(g_aCamper, iCount, eCamper)
}

public camperNoClip(id)
{
    set_pev(id, pev_movetype, pev(id, pev_movetype) == MOVETYPE_NOCLIP ? MOVETYPE_WALK : MOVETYPE_NOCLIP)

    camperSound(id, SOUND_MENU_NAV)
    camperMenu(id, MENU_ROOT)
}

public camperGodMode(id)
{
    set_pev(id, pev_takedamage, pev(id, pev_takedamage) == DAMAGE_NO ? DAMAGE_AIM : DAMAGE_NO)

    camperSound(id, SOUND_MENU_NAV)
    camperMenu(id, MENU_ROOT)
}

public fwdPreThink(id)
{
    if ( !is_user_alive(id) )
        return HAM_IGNORED

    new iButton, Float:fCurrentTime
    iButton = pev(id, pev_button)
    fCurrentTime = get_gametime()

    if ( g_ePlayerData[id][PDATA_CAMPER_GHOST] )
    {
        if ( get_gametime() >= g_ePlayerData[id][PDATA_NEXT_OFFSET] )
        {
            if ( iButton & IN_ATTACK )
            {
                g_ePlayerData[id][PDATA_OFFSET]      += CAMPER_OFFSET_STEP
                g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], CAMPER_OFFSET_MIN, CAMPER_OFFSET_MAX)
                g_ePlayerData[id][PDATA_NEXT_OFFSET] = get_gametime() + 0.1
            }
            else if ( iButton & IN_ATTACK2 )
            {
                g_ePlayerData[id][PDATA_OFFSET]      -= CAMPER_OFFSET_STEP
                g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], CAMPER_OFFSET_MIN, CAMPER_OFFSET_MAX)
                g_ePlayerData[id][PDATA_NEXT_OFFSET] = get_gametime() + 0.1
            }
        }

        set_pdata_float(id, PDATA_NEXT_ATTACK, fCurrentTime + 0.1, XO_CBASEPLAYER, XO_CBASEPLAYER)
        iButton &= ~(IN_ATTACK | IN_ATTACK2)
        set_pev(id, pev_button, iButton)
    }

    return HAM_IGNORED
}

public fwdKilled(id, iAttacker, bGib)
{
    DisableAction(id)
    camperResetPlayer(id)
    if ( g_ePlayerData[id][PDATA_CAMPER_GHOST] )
    {
        new eCamper[CAMPER], iItem

        if ( (iItem = camperGet(eCamper, g_ePlayerData[id][PDATA_CAMPER_GHOST])) != -1 )
        {
            camperKill(eCamper[CAMPER_ID])
            camperRemove(iItem)
            g_ePlayerData[id][PDATA_CAMPER_GHOST] = 0
        }
    }

    return HAM_IGNORED
}

public camperTrace(eCamper[CAMPER], id)
{
    new Float:fVec1[3]
    pev(id, pev_origin, eCamper[CAMPER_ORIGIN])
    pev(id, pev_view_ofs, fVec1)
    xs_vec_add(eCamper[CAMPER_ORIGIN], fVec1, eCamper[CAMPER_ORIGIN])

    pev(id, pev_v_angle, fVec1)
    engfunc(EngFunc_MakeVectors, fVec1)
    global_get(glb_v_forward, fVec1)

    xs_vec_mul_scalar(fVec1, g_ePlayerData[id][PDATA_OFFSET], fVec1)
    xs_vec_add(fVec1, eCamper[CAMPER_ORIGIN], fVec1)

    engfunc(EngFunc_TraceLine, eCamper[CAMPER_ORIGIN], fVec1, IGNORE_MONSTERS, id, 0)
    get_tr2(0, TR_vecEndPos, eCamper[CAMPER_ORIGIN])

    camperSetBox(eCamper, true)
    camperSetOffset(eCamper)
    camperSetBox(eCamper, true)
    camperBeam(eCamper)
    set_pev(eCamper[CAMPER_ID], pev_origin, eCamper[CAMPER_ORIGIN])
}

stock camperCheck(id)
{
    new eCamper[CAMPER], Float:fVec1[3], Float:fVec2[3], Float:fVec3[3], Float:fMins[3], Float:fMaxs[3], Float:fNearest[3]
    new iBest, Float:fBestDist, Float:fDot, Float:fDist

    pev(id, pev_origin, fVec1)
    pev(id, pev_view_ofs, fVec2)
    xs_vec_add(fVec1, fVec2, fVec1)

    pev(id, pev_v_angle, fVec2)
    engfunc(EngFunc_MakeVectors, fVec2)
    global_get(glb_v_forward, fVec2)

    iBest = -1
    fBestDist = CAMPER_CHECK
    for ( new i = 0; i < g_iCamper; i ++ )
    {
        ArrayGetArray(g_aCamper, i, eCamper)
        xs_vec_sub(eCamper[CAMPER_ORIGIN], fVec1, fVec3)
        fDot = xs_vec_dot(fVec2, fVec3)

        if ( fDot < 0.0 )
            continue

        pev(eCamper[CAMPER_ID], pev_absmin, fMins)
        pev(eCamper[CAMPER_ID], pev_absmax, fMaxs)
        xs_vec_mul_scalar(fVec2, fDot, fVec3)
        xs_vec_add(fVec3, fVec1, fVec3)

        fNearest[0] = floatclamp(fVec3[0], fMins[0], fMaxs[0])
        fNearest[1] = floatclamp(fVec3[1], fMins[1], fMaxs[1])
        fNearest[2] = floatclamp(fVec3[2], fMins[2], fMaxs[2])
        fDist = vector_distance(fVec3, fNearest)
        if ( fDist < fBestDist )
        {
            fBestDist = fDist
            iBest = i
        }
    }

    if ( iBest != -1
    && g_ePlayerData[id][PDATA_CAMPER_MENU] != iBest )
    {
        ArrayGetArray(g_aCamper, g_ePlayerData[id][PDATA_CAMPER_MENU], eCamper)
        eCamper[CAMPER_FLAGS] &= ~FLAG_SELECT
        ArraySetArray(g_aCamper, g_ePlayerData[id][PDATA_CAMPER_MENU], eCamper)

        g_ePlayerData[id][PDATA_MENU_TRACE] = true
        g_ePlayerData[id][PDATA_CAMPER_MENU] = iBest
        camperMenu(id, g_ePlayerData[id][PDATA_MENU_TYPE])
    }
}

stock camperSetBox(eCamper[CAMPER], bool:bSetCorners = false)
{
    if ( bSetCorners )
        boxCorners(eCamper)

    xs_vec_copy(eCamper[CAMPER_CORNERS][0], eCamper[CAMPER_MINS])
    xs_vec_copy(eCamper[CAMPER_CORNERS][0], eCamper[CAMPER_MAXS])
    for ( new i = 1; i < 8; i ++ )
    {
        for ( new j = 0; j < 3; j ++ )
        {
            eCamper[CAMPER_MINS][j] = floatmin(eCamper[CAMPER_MINS][j], eCamper[CAMPER_CORNERS][i * 3 + j])
            eCamper[CAMPER_MAXS][j] = floatmax(eCamper[CAMPER_MAXS][j], eCamper[CAMPER_CORNERS][i * 3 + j])
        }
    }

    xs_vec_sub(eCamper[CAMPER_MINS], eCamper[CAMPER_ORIGIN], eCamper[CAMPER_MINS])
    xs_vec_sub(eCamper[CAMPER_MAXS], eCamper[CAMPER_ORIGIN], eCamper[CAMPER_MAXS])
}

public boxCorners(eCamper[CAMPER])
{
    eCamper[CAMPER_CORNERS][0]  = eCamper[CAMPER_ORIGIN][0] - eCamper[CAMPER_SCALE][0]
    eCamper[CAMPER_CORNERS][1]  = eCamper[CAMPER_ORIGIN][1] - eCamper[CAMPER_SCALE][1]
    eCamper[CAMPER_CORNERS][2]  = eCamper[CAMPER_ORIGIN][2] - eCamper[CAMPER_SCALE][2]

    eCamper[CAMPER_CORNERS][3]  = eCamper[CAMPER_ORIGIN][0] + eCamper[CAMPER_SCALE][0]
    eCamper[CAMPER_CORNERS][4]  = eCamper[CAMPER_ORIGIN][1] - eCamper[CAMPER_SCALE][1]
    eCamper[CAMPER_CORNERS][5]  = eCamper[CAMPER_ORIGIN][2] - eCamper[CAMPER_SCALE][2]

    eCamper[CAMPER_CORNERS][6]  = eCamper[CAMPER_ORIGIN][0] - eCamper[CAMPER_SCALE][0]
    eCamper[CAMPER_CORNERS][7]  = eCamper[CAMPER_ORIGIN][1] + eCamper[CAMPER_SCALE][1]
    eCamper[CAMPER_CORNERS][8]  = eCamper[CAMPER_ORIGIN][2] - eCamper[CAMPER_SCALE][2]

    eCamper[CAMPER_CORNERS][9]  = eCamper[CAMPER_ORIGIN][0] + eCamper[CAMPER_SCALE][0]
    eCamper[CAMPER_CORNERS][10] = eCamper[CAMPER_ORIGIN][1] + eCamper[CAMPER_SCALE][1]
    eCamper[CAMPER_CORNERS][11] = eCamper[CAMPER_ORIGIN][2] - eCamper[CAMPER_SCALE][2]

    eCamper[CAMPER_CORNERS][12] = eCamper[CAMPER_ORIGIN][0] - eCamper[CAMPER_SCALE][0]
    eCamper[CAMPER_CORNERS][13] = eCamper[CAMPER_ORIGIN][1] - eCamper[CAMPER_SCALE][1]
    eCamper[CAMPER_CORNERS][14] = eCamper[CAMPER_ORIGIN][2] + eCamper[CAMPER_SCALE][2]

    eCamper[CAMPER_CORNERS][15] = eCamper[CAMPER_ORIGIN][0] + eCamper[CAMPER_SCALE][0]
    eCamper[CAMPER_CORNERS][16] = eCamper[CAMPER_ORIGIN][1] - eCamper[CAMPER_SCALE][1]
    eCamper[CAMPER_CORNERS][17] = eCamper[CAMPER_ORIGIN][2] + eCamper[CAMPER_SCALE][2]

    eCamper[CAMPER_CORNERS][18] = eCamper[CAMPER_ORIGIN][0] - eCamper[CAMPER_SCALE][0]
    eCamper[CAMPER_CORNERS][19] = eCamper[CAMPER_ORIGIN][1] + eCamper[CAMPER_SCALE][1]
    eCamper[CAMPER_CORNERS][20] = eCamper[CAMPER_ORIGIN][2] + eCamper[CAMPER_SCALE][2]

    eCamper[CAMPER_CORNERS][21] = eCamper[CAMPER_ORIGIN][0] + eCamper[CAMPER_SCALE][0]
    eCamper[CAMPER_CORNERS][22] = eCamper[CAMPER_ORIGIN][1] + eCamper[CAMPER_SCALE][1]
    eCamper[CAMPER_CORNERS][23] = eCamper[CAMPER_ORIGIN][2] + eCamper[CAMPER_SCALE][2]
}

stock camperSetOffset(eCamper[CAMPER])
{
    new Float:fVec1[3], Float:fGap, Float:fCurrentGap
    fGap = -eCamper[CAMPER_MINS][2]

    xs_vec_mul_scalar(Float:{0.0, 0.0, -1.0}, 9999.9, fVec1)
    xs_vec_add(fVec1, eCamper[CAMPER_ORIGIN], fVec1)
    engfunc(EngFunc_TraceLine, eCamper[CAMPER_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eCamper[CAMPER_ID], 0)
    get_tr2(0, TR_vecEndPos, fVec1)
    fCurrentGap = xs_vec_distance(eCamper[CAMPER_ORIGIN], fVec1)

    if ( fCurrentGap < (fGap + 1.0) )
    {
        get_tr2(0, TR_vecPlaneNormal, fVec1)
        xs_vec_mul_scalar(fVec1, (fGap + 1.0) - fCurrentGap, fVec1)
        xs_vec_add(eCamper[CAMPER_ORIGIN], fVec1, eCamper[CAMPER_ORIGIN])
    }
}

stock camperSetSeq(iEnt)
{
    set_pev(iEnt, pev_sequence, 0)
    set_pev(iEnt, pev_frame, 0.0)
    set_pev(iEnt, pev_framerate, 1.0)
    set_pev(iEnt, pev_animtime, get_gametime())
}

stock camperSetSize(eCamper[CAMPER])
{
    camperSelect(eCamper, TARGET_HIDE)
    engfunc(EngFunc_SetOrigin, eCamper[CAMPER_ID], eCamper[CAMPER_ORIGIN])
    set_pev(eCamper[CAMPER_ID], pev_solid, SOLID_TRIGGER)
    set_pev(eCamper[CAMPER_ID], pev_movetype, MOVETYPE_NONE)

    engfunc(EngFunc_SetSize, eCamper[CAMPER_ID], eCamper[CAMPER_MINS], eCamper[CAMPER_MAXS])
    xs_vec_add(eCamper[CAMPER_MINS], eCamper[CAMPER_ORIGIN], eCamper[CAMPER_MINS])
    xs_vec_add(eCamper[CAMPER_MAXS], eCamper[CAMPER_ORIGIN], eCamper[CAMPER_MAXS])
}

stock camperSelect(eCamper[CAMPER], iAction)
{
    new iRender, iRenderFx, iRenderColor[3], iRenderAmt

    iRenderFx = kRenderFxNone
    if ( iAction == TARGET_SELECT )
    {
        if ( eCamper[CAMPER_FLAGS] & FLAG_ACTIVE )    { iRenderColor[0] = 0;      iRenderColor[1] = 255;     iRenderColor[2] = 0; }
        else                                            { iRenderColor[0] = 255;    iRenderColor[1] = 0;   iRenderColor[2] = 0; }

        iRender = kRenderTransColor
        iRenderFx = kRenderFxGlowShell
        iRenderAmt = 16

        eCamper[CAMPER_FLAGS] |= FLAG_SELECT
    }
    else if ( iAction == TARGET_GHOST )
    {
        iRender = kRenderTransAlpha
        iRenderAmt = CAMPER_GHOST_ALPHA
    }
    else if ( iAction == TARGET_HIDE )
    {
        iRender = kRenderTransAlpha
        iRenderAmt = 0

        eCamper[CAMPER_FLAGS] &= ~FLAG_SELECT
    }
    else if ( iAction == TARGET_CLEAR )
    {
        iRender = kRenderNormal
        iRenderAmt = 255

        eCamper[CAMPER_FLAGS] &= ~FLAG_SELECT
    }

    entitySetRendering(eCamper[CAMPER_ID], iRenderFx, iRenderColor[0], iRenderColor[1], iRenderColor[2], iRender, iRenderAmt)
}

stock camperSound(iEnt, iSound, bool:bPlayer = true)
{
    new szSample[64]
    switch( iSound )
    {
        case SOUND_MENU_NAV:    copy(szSample, charsmax(szSample), SOUND_NAV)
        case SOUND_MENU_REMOVE: copy(szSample, charsmax(szSample), SOUND_REMOVE)
        case SOUND_MENU_ALERT:  copy(szSample, charsmax(szSample), SOUND_ALERT)
    }

    if ( bPlayer )
        client_cmd(iEnt, "spk %s", szSample)
    else
        engfunc(EngFunc_EmitSound, iEnt, CHAN_ITEM, szSample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

stock camperBeam(eCamper[CAMPER])
{
    new Float:fCorners[8][3]
    xs_vec_copy(eCamper[CAMPER_CORNERS][0],  fCorners[0])
    xs_vec_copy(eCamper[CAMPER_CORNERS][3],  fCorners[1])
    xs_vec_copy(eCamper[CAMPER_CORNERS][6],  fCorners[2])
    xs_vec_copy(eCamper[CAMPER_CORNERS][9],  fCorners[3])
    xs_vec_copy(eCamper[CAMPER_CORNERS][12], fCorners[4])
    xs_vec_copy(eCamper[CAMPER_CORNERS][15], fCorners[5])
    xs_vec_copy(eCamper[CAMPER_CORNERS][18], fCorners[6])
    xs_vec_copy(eCamper[CAMPER_CORNERS][21], fCorners[7])

    beamDraw(fCorners[0], fCorners[1], eCamper[CAMPER_FLAGS] & FLAG_ACTIVE != 0)
    beamDraw(fCorners[1], fCorners[3], eCamper[CAMPER_FLAGS] & FLAG_ACTIVE != 0)
    beamDraw(fCorners[3], fCorners[2], eCamper[CAMPER_FLAGS] & FLAG_ACTIVE != 0)
    beamDraw(fCorners[2], fCorners[0], eCamper[CAMPER_FLAGS] & FLAG_ACTIVE != 0)

    beamDraw(fCorners[0], fCorners[4], eCamper[CAMPER_FLAGS] & FLAG_ACTIVE != 0)
    beamDraw(fCorners[1], fCorners[5], eCamper[CAMPER_FLAGS] & FLAG_ACTIVE != 0)
    beamDraw(fCorners[2], fCorners[6], eCamper[CAMPER_FLAGS] & FLAG_ACTIVE != 0)
    beamDraw(fCorners[3], fCorners[7], eCamper[CAMPER_FLAGS] & FLAG_ACTIVE != 0)

    beamDraw(fCorners[4], fCorners[5], eCamper[CAMPER_FLAGS] & FLAG_ACTIVE != 0)
    beamDraw(fCorners[5], fCorners[7], eCamper[CAMPER_FLAGS] & FLAG_ACTIVE != 0)
    beamDraw(fCorners[7], fCorners[6], eCamper[CAMPER_FLAGS] & FLAG_ACTIVE != 0)
    beamDraw(fCorners[6], fCorners[4], eCamper[CAMPER_FLAGS] & FLAG_ACTIVE != 0)
}

stock beamDraw(Float:fStart[3], Float:fEnd[3], bool:bActive)
{
    message_begin_f(MSG_PVS, SVC_TEMPENTITY, fStart)
    write_byte(TE_BEAMPOINTS)
    write_coord_f(fStart[0])
    write_coord_f(fStart[1])
    write_coord_f(fStart[2])
    write_coord_f(fEnd[0])
    write_coord_f(fEnd[1])
    write_coord_f(fEnd[2])
    write_short(g_eSettings[SETTING_BEAM])
    write_byte(0)
    write_byte(0)
    write_byte(1)
    write_byte(g_eSettings[SETTING_BEAM_WIDTH])
    write_byte(0)
    if ( bActive )
    {
        write_byte(0)
        write_byte(255)
        write_byte(0)
    }
    else
    {
        write_byte(255)
        write_byte(0)
        write_byte(0)
    }
    write_byte(g_eSettings[SETTING_BEAM_ALPHA])
    write_byte(0)
    message_end()
}

stock camperPlayer(eCamper[CAMPER])
{
    new Float:fDamage, Float:fCurrentTime = get_gametime()
    for ( new id = 1; id <= g_iMaxPlayers; id ++ )
    {
        if ( !is_user_alive(id) )
            continue

        if ( !isCamperActive(eCamper, id) )
        {
            if ( g_ePlayerData[id][PDATA_NEXT_DAMAGE] && !g_ePlayerData[id][PDATA_NEXT_RESET] )
            {
                g_ePlayerData[id][PDATA_NEXT_RESET] = fCurrentTime + eCamper[CAMPER_DAMAGE_RESET_DELAY]
            }
            else if ( fCurrentTime >= g_ePlayerData[id][PDATA_NEXT_RESET] )
            {
                camperResetPlayer(id)
            }

            continue
        }
        else if ( g_ePlayerData[id][PDATA_NEXT_RESET] )
        {
            g_ePlayerData[id][PDATA_NEXT_RESET] = 0.0
        }

        if ( !g_ePlayerData[id][PDATA_NEXT_DAMAGE] )
        {
            g_ePlayerData[id][PDATA_NEXT_DAMAGE] = fCurrentTime + eCamper[CAMPER_DAMAGE_DELAY]
        }
        else if ( fCurrentTime >= g_ePlayerData[id][PDATA_NEXT_DAMAGE] )
        {
            fDamage = random_float(eCamper[CAMPER_DAMAGE][0], eCamper[CAMPER_DAMAGE][1])
            if ( !g_ePlayerData[id][PDATA_NEXT_DAMAGE_MULTIPLIER] )
                g_ePlayerData[id][PDATA_NEXT_DAMAGE_MULTIPLIER] = fCurrentTime + eCamper[CAMPER_DAMAGE_MULTIPLIER_DELAY]
            else if ( fCurrentTime >= g_ePlayerData[id][PDATA_NEXT_DAMAGE_MULTIPLIER] )
                fDamage += ((fCurrentTime - g_ePlayerData[id][PDATA_NEXT_DAMAGE_MULTIPLIER]) * eCamper[CAMPER_DAMAGE_MULTIPLIER])

            ExecuteHamB(Ham_TakeDamage, id, 0, 0, fDamage, eCamper[CAMPER_DAMAGETYPE])
            if ( eCamper[CAMPER_FLAGS] & FLAG_DAMAGE_SLAP )
                camperSlap(id)

            g_ePlayerData[id][PDATA_TAKING_DAMAGE] = true
            g_ePlayerData[id][PDATA_NEXT_DAMAGE] = fCurrentTime + random_float(eCamper[CAMPER_DAMAGE_TICK][0], eCamper[CAMPER_DAMAGE_TICK][1])
            continue
        }

        if ( !g_ePlayerData[id][PDATA_TAKING_DAMAGE] )
        {
            if ( !g_ePlayerData[id][PDATA_NEXT_WARNING] )
            {
                g_ePlayerData[id][PDATA_NEXT_WARNING] = fCurrentTime + eCamper[CAMPER_WARNING_DELAY]
            }
            else if ( fCurrentTime >= g_ePlayerData[id][PDATA_NEXT_WARNING] )
            {
                if ( eCamper[CAMPER_FLAGS] & FLAG_WARNING_SLAP )
                    camperSlap(id)

                if ( eCamper[CAMPER_FLAGS] & FLAG_WARNING_MESSAGE )
                    client_print(id, print_center, "%a", ArrayGetStringHandle(eCamper[CAMPER_WARNING_MESSAGE], random(eCamper[CAMPER_WARNING_MESSAGE_COUNT])))

                g_ePlayerData[id][PDATA_NEXT_WARNING] = fCurrentTime + random_float(eCamper[CAMPER_WARNING_COOLDOWN][0], eCamper[CAMPER_WARNING_COOLDOWN][1])
            }
        }
    }
}

stock bool:isCamperActive(eCamper[CAMPER], id)
{
    new Float:fOrigin[3]
    pev(id, pev_origin, fOrigin)

    if ( eCamper[CAMPER_FLAGS] & FLAG_ACTIVE
    && CsTeams:eCamper[CAMPER_TEAM] & cs_get_user_team(id)
    && fOrigin[0] >= eCamper[CAMPER_MINS][0] && fOrigin[0] <= eCamper[CAMPER_MAXS][0]
    && fOrigin[1] >= eCamper[CAMPER_MINS][1] && fOrigin[1] <= eCamper[CAMPER_MAXS][1]
    && fOrigin[2] >= eCamper[CAMPER_MINS][2] && fOrigin[2] <= eCamper[CAMPER_MAXS][2] )
        return true

    return false
}

stock camperResetPlayer(id)
{
    g_ePlayerData[id][PDATA_TAKING_DAMAGE] = false
    g_ePlayerData[id][PDATA_NEXT_RESET] = 0.0
    g_ePlayerData[id][PDATA_NEXT_WARNING] = 0.0
    g_ePlayerData[id][PDATA_NEXT_DAMAGE] = 0.0
    g_ePlayerData[id][PDATA_NEXT_DAMAGE_MULTIPLIER] = 0.0
}

stock camperGet(eCamper[CAMPER], iEnt)
{
    if ( !isCamper(iEnt) )
        return -1

    new iItem
    iItem = pev(iEnt, CAMPER_ARRAY_ITEM)
    if ( iItem < 0 || iItem >= g_iCamper )
        return -1

    ArrayGetArray(g_aCamper, iItem, eCamper)
    return iItem
}

stock bool:isCamper(iEnt)
{
    return pev_valid(iEnt) && pev(iEnt, pev_impulse) == CAMPER_KEY
}

stock camperKill(iEnt)
{
    if ( pev_valid(iEnt) )
        set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
}

stock parseSetting(iType, szValue[], iValueLen, any:aOutput[], iOutputLength)
{
    switch ( iType )
    {
        case DTYPE_INT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_num(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLOAT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_float(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLAGS:
        {
            aOutput[0] = read_flags(szValue)
        }
        case DTYPE_STRING_MODEL:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_model(szValue)
        }
        case DTYPE_STRING_SOUND:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_ARRAY_MESSAGE:
        {
            replace_all(szValue, iValueLen, "^"", " ")
            replace_all(szValue, iValueLen, "^^n", "^n")
            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_MODEL:
        {
            if ( !g_bFileWasRead )
                precache_model(szValue)

            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_SOUND:
        {
            ArrayPushString(aOutput[0], szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                aOutput[0] = precache_model(szValue)
        }
        case DTYPE_ARRAY_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                ArrayPushCell(aOutput[0], precache_model(szValue))
        }
    }
}

stock EnableAction(id)
{
    if ( !g_ePlayerData[id][PDATA_CAMPER_ACTION] )
    {
        new eCamper[CAMPER]
        for ( new i = 0; i < g_iCamper; i ++ )
        {
            ArrayGetArray(g_aCamper, i, eCamper)
            camperSelect(eCamper, TARGET_GHOST)
        }

        g_ePlayerData[id][PDATA_CAMPER_ACTION] = true
        if ( ++ g_iActivePlayers == 1 )
            EnableForward()
    }
}

stock DisableAction(id)
{
    if ( g_ePlayerData[id][PDATA_CAMPER_ACTION] )
    {
        new eCamper[CAMPER]
        for ( new i = 0; i < g_iCamper; i ++ )
        {
            ArrayGetArray(g_aCamper, i, eCamper)
            camperSelect(eCamper, TARGET_HIDE)
            ArraySetArray(g_aCamper, i, eCamper)
        }

        g_ePlayerData[id][PDATA_CAMPER_ACTION] = false
        if ( -- g_iActivePlayers == 0 )
            DisableForward()
    }
}

stock EnableForward()
{
    EnableHamForward(g_iFwdPreThink)
    EnableHamForward(g_iFwdKilled)
}

stock DisableForward()
{
    DisableHamForward(g_iFwdPreThink)
    DisableHamForward(g_iFwdKilled)
}

stock LogConfigError(const iLine, const szText[], any:...)
{
    new szError[MAX_PLATFORM_PATH_LENGTH]
    vformat(szError, charsmax(szError), szText, 3)

    log_to_file(ERROR_FILE, "^nLine %d: %s", iLine, szError)
}
stock entitySetRendering(iEntity, iRenderFx, iRed, iGreen, iBlue, iRenderMode, iRenderAmt)
{
    new Float:fRenderColor[3]
    fRenderColor[0] = float(iRed)
    fRenderColor[1] = float(iGreen)
    fRenderColor[2] = float(iBlue)

    set_pev(iEntity, pev_renderfx, iRenderFx)
    set_pev(iEntity, pev_rendercolor, fRenderColor)
    set_pev(iEntity, pev_rendermode, iRenderMode)
    set_pev(iEntity, pev_renderamt, float(iRenderAmt))
}

stock camperSlap(id)
{
    new Float:fVelocity[3]
    fVelocity[0] = random_float(-100.0, 100.0)
    fVelocity[1] = random_float(-100.0, 100.0)
    fVelocity[2] = random_float(100.0, 300.0)
    set_pev(id, pev_velocity, fVelocity)
}
