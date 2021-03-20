--[[ CONFIG ]]
BIPB.AutoDetect = true -- If you want integration with your admin system then set this to true. 

--[[ SETUP ]]
local player = FindMetaTable("Player")
BIPB = {}

--[[ LOCAL FUNCTIONS ]]
local function prnt(msg)
    print("[BIPB] " .. msg)
end
local function storeip(ip, minutes, nick, steamid)
    sql.Query(
        "INSERT INTO bipb_bans(ip, minutes, nick, steamid) VALUES('" ..
            ip .. "', " .. minutes .. ", '" .. NICK .. "', '" .. steamid .. "')"
    )
end
local function bootPly(ply)
    if IsValid(ply) then
        ply:Kick("BIPB: IP Banned")
    end
end
local function queuePly(ply)
    timer.Create(
        "BIPB.Queue",
        1,
        1,
        function()
            bootPly(ply)
        end
    )
end
local function IPSniff(ip)
    for _, v in ipairs(player.GetAll()) do
        if v:IPAddress() == ip then
            bootPly(v)
        end
    end
end

--[[ GLOBAL FUNCTIONS ]]
local plyip, name, id
function player:IPBan(time)
    if not player:IsPlayer() then
        prnt("You need to IP ban a player!")
        return
    end
    plyip = player:IPAddress()
    name = player:Nick()
    id = player:SteamID()
    unban = math.min(time, 31536000) * 60 + os.time()
    storeip(plyip, unban, name, id)
    queuePly(ply)
end
function BIPB.IPBan(ip, time, nick, sid)
    if not isstring(ip) then
        return
    end
    if not IsValid(ip) then
        return
    end
    if not IsValid(time) then
        return
    end
    if not IsValid(nick) then
        return
    end
    if not IsValid(sid) then
        return
    end
    if not isnumber(time) then
        prnt("Error: You need to include a time to IP Ban for.")
        return
    end
    storeip(ip, time, nick, sid)
    IPSniff(ip)
end
function BIPB.IsBanned(ip)
    if not isstring(ip) then
        return
    end
    return istable(sql.Query("SELECT * FROM bipb_bans WHERE ip='" .. ip .. "'"))
end
function BIPB.Time(ip)
    if not isstring(ip) then
        return
    end
    local result = sql.Query("SELECT * FROM bipb_bans WHERE ip='" .. ip .. "'")
    if not IsValid(result) then
        return 0
    end
    if not result then
        return 0
    end
    return result[2]
end
function BIPB.Unban(ip)
    if not isstring(ip) then
        return
    end
    if BIPB.IsBanned(ip) then
        sql.Query("DELETE FROM bipb_bans WHERE ip = '" .. ip .. "'")
    end
end

--[[ Hook Functions ]]
local function BIPBInit()
    if not sql.TableExists("bipb_bans") then
        sql.Query("CREATE TABLE bipb_bans(ip TEXT, minutes INTEGER, nick TEXT, steamid TEXT)")
    end
end
local function BIPBAuth(_, ip)
    if BIPB.IsBanned(ip) then
        if BIPB.Time(ip) >= os.time() then
            BIPB.Unban(ip)
            return
        else
            return false, "IP Banned"
        end
    end
end

--[[ INTEGRATIONS ]]
if BIPB.AutoDetect then
    if istable(ULib) then
        ULib.ban = function(ply, time, reason, admin)
            if not time or type(time) ~= "number" then
                time = 0
            end

            if ply:IsListenServerHost() then
                return
            end
            ply:IPBan(time)
            ULib.addBan(ply:SteamID(), time, reason, ply:Name(), admin)
        end
    elseif istable(sam) then
        sam.player.ban = function(ply, length, reason, admin_steamid)
            if sam.type(ply) ~= "Player" or not ply:IsValid() then
                error("invalid player")
            end

            if ply.sam_is_banned then
                return
            end

            local unban_date
            if not sam.isnumber(length) or length <= 0 then
                unban_date = 0
            else
                unban_date = (math.min(length, 31536000) * 60) + os.time()
            end

            if not sam.isstring(reason) then
                reason = DEFAULT_REASON
            end

            if ply:IsBot() then -- you can't ban bots!
                return ply:Kick(reason)
            end

            if not sam.is_steamid(admin_steamid) then
                admin_steamid = "Console"
            end

            local steamid = ply:SteamID()

            SQL.FQuery(
                [[
                INSERT INTO
                    `sam_bans`(
                        `steamid`,
                        `reason`,
                        `admin`,
                        `unban_date`
                    )
                VALUES
                    ({1}, {2}, {3}, {4})
            ]],
                {steamid, reason, admin_steamid, unban_date}
            )

            local admin_name = ""
            do
                local admin = player.GetBySteamID(admin_steamid)
                if admin then
                    admin_name = admin:Name()
                end
            end

            ply:IPBan(time)

            ply.sam_is_banned = true
            set_cached(steamid, nil)
            sam.hook_call("SAM.BannedPlayer", ply, unban_date, reason, admin_steamid)
            ply:Kick(sam.format_ban_message(admin_name, admin_steamid, reason, unban_date))
        end
    elseif istable(gBan) then
        GBAN_PLAYER = function(caller, target, time, reason)
            time = time or 0
            reason = (reason:len() > 1 and reason) or "Reason not specified."

            local nick = "CONSOLE"
            if caller:IsValid() then
                if not gBan.Config.Hierarchy[caller:GetUserGroup()] then
                    gBan:AddChatMessage(caller, gBan:Translate("NoAccess", gBan.Config.Language))
                    return
                end
                nick = caller:Nick()
                if not gBan.Config.CanBan(caller, target) then
                    gBan:AddChatMessage(caller, gBan:Translate("TargetHigh", gBan.Config.Language))
                    return
                end
            end
            local ip = caller:IPAddress()
            local nickname = caller:Nick()
            local sid = caller:SteamID()

            gBan:PlayerBan(caller, target, tonumber(time), reason)
            BIPB.IPBan(ip, time, nickname, sid)

            if not gBan.Config.EnableLogging then
                return
            end
            local text = gBan:Translate("LogBan", gBan.Config.Language)
            text = text:Replace("{name}", nick)
            text = text:Replace("{steamid}", target:Nick())
            text = text:Replace("{time}", tostring(time))
            text = text:Replace("{reason}", reason)
            print("[gBan] (LOG) " .. text)
        end
    end
end

--[[ HOOKS ]]
hook.Add("Initialize", "BIPB.HOOKS.INIT", BIPBInit)
hook.Add("CheckPassword", "BIPB.HOOKS.AUTH", BIPBAuth)
