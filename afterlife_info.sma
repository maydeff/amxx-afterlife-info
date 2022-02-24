#include <amxmodx>
#include <amxmodx>
#include <colorchat>
#include <fakemeta>

#define PLUGIN "Afterlife Info"
#define VERSION "0.0.1"
#define AUTHOR "maydeff"

new maxPlayers,
Float: infoDuration,
bool:infoFeatureFlag[33];

public plugin_config()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    register_cvar("afterlife_info_duration", "5.0");
    infoDuration = get_cvar_float("afterlife_info_duration");
}

public plugin_init()
{
    plugin_config();

    register_event("DeathMsg", "onPlayerDeath", "a")
    register_clcmd("say", "sayHandle")
    register_clcmd("say_team", "sayHandle")

    register_forward(FM_Voice_SetClientListening, "Forward_SetClientListening");

    maxPlayers = get_maxplayers();
}

public sayHandle(id)
{
    if (!infoFeatureFlag[id])
    {
        return PLUGIN_CONTINUE;
    }

    new messageTmp[256],
        formattedMessage[190],
        username[64];

    read_argv(1, messageTmp, charsmax(messageTmp));
    trim(messageTmp)

    get_user_name(id, username, charsmax(username));

    formatex(formattedMessage, charsmax(formattedMessage), "[Info od %s] ^x01 %s", username, messageTmp);

    ColorChat(id, GREEN, formattedMessage);

    for (new playerId = 1; playerId <= maxPlayers; playerId++)
    {
        if (!is_user_alive(playerId) || get_user_team(playerId) != get_user_team(id))
        {
            continue;
        }

        ColorChat(playerId, GREEN, formattedMessage);
    }

    return PLUGIN_HANDLED;
}

public onPlayerDeath()
{
    new victimPlayerId = read_data(2);

    if (!is_user_connected(victimPlayerId) || is_user_alive(victimPlayerId))
    {
        return PLUGIN_CONTINUE;
    }

    new szText[128];
    formatex(szText, charsmax(szText), "Nie żyjesz, możesz dać info przez %.1f sekund.", infoDuration);

    set_hudmessage(255, 0, 0, -1.0, 0.01);
    show_hudmessage(victimPlayerId, szText);

    activateFeatureForSeconds(victimPlayerId, infoDuration);
    return PLUGIN_CONTINUE;
}

public activateFeatureForSeconds(playerId, Float: seconds)
{
    infoFeatureFlag[playerId] = true;

    remove_task(playerId);
    set_task(seconds, "deactiveFeature", playerId);
}

public deactiveFeature(playerId)
{
    infoFeatureFlag[playerId] = false;

    for (new otherPlayerId = 1; otherPlayerId <= maxPlayers; otherPlayerId++)
    {
        if (!is_user_alive(playerId))
        {
            continue;
        }

        engfunc(EngFunc_SetClientListening, playerId, otherPlayerId, false);
    }
}

public Forward_SetClientListening(iReceiver, iSender, bool:bListen)
{
    if (!is_user_connected(iSender) || !is_user_connected(iReceiver))
    {
        return FMRES_IGNORED;
    }

    if (get_user_team(iSender) != get_user_team(iReceiver))
    {
        return FMRES_IGNORED;
    }

    if (!infoFeatureFlag[iSender])
    {
        return FMRES_IGNORED;
    }

    engfunc(EngFunc_SetClientListening, iReceiver, iSender, true);
    forward_return(FMV_CELL, true);

    return FMRES_SUPERCEDE
}