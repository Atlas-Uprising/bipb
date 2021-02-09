--[[ SETUP ]]
local ply = FindMetaTable("Player")
BIPB = {}
include("bipb/sv_config.lua")
BIPB.AutoDetect = true

--[[ LOCAL FUNCTIONS ]]
local function prnt(msg)
    print("[BIPB] " .. msg)
end
local function storeip(ip, minutes, nick, steamid)
    sql.Query("INSERT INTO bipb_bans(ip, minutes, nick, steamid) VALUES('".. ip .."', ".. minutes ..", '".. NICK .."', '".. steamid .."')")
end

--[[ GLOBAL FUNCTIONS ]]
function BIPB.Init()
    if not sql.TableExists("bipb_bans") then
        sql.Query("CREATE TABLE bipb_bans(ip TEXT, minutes INTEGER, nick TEXT, steamid TEXT)")
    end
end
local plyip, name, id
function ply:ipban(time)
    if not ply:IsPlayer() then prnt("You need to IP ban a player!") return end
    plyip = ply:IPAddress()
    name = ply:Nick()
    id = ply:SteamID()
    storeip(plyip, time, name, id)
end
function BIPB.IPBan(plyip, time, name, id)
    if not IsValid(plyip) then return end
    if not IsValid(time) then return end
    if not IsValid(name) then return end
    if not IsValid(id) then return end
    if not isnumber(time) then prnt("You need to include a time to IP Ban for.") return end
    storeip(plyip, time, name, id)
end
function BIPB.IsBanned(ip)
    sql.Query("SELECT * FROM bipb_bans WHERE ip='"..ip.."'")
end
function BIPB.Auth(ply)
    
end

--[[ INTEGRATIONS ]]
if BIPB.AutoDetect then
    if istable(ULib) then
        ULib.ban = function(ply, time, reason, admin) 
            if not time or type( time ) ~= "number" then
                time = 0
            end
        
            if ply:IsListenServerHost() then
                return
            end
            ply:ipban(time)
            ULib.addBan( ply:SteamID(), time, reason, ply:Name(), admin )
        end
    elseif istable(sam) then
        sam.player.ban = function(ply, length, reason, admin_steamid)
            if sam.type(ply) ~= "Player" or not ply:IsValid() then
                error("invalid player")
            end
        
            if ply.sam_is_banned then return end
        
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
        
            if not sam.is_steamid(admin_steamid) then -- f71ca7c48b4ddc71be53580cf8ce0f1bef4aef10af1161f19c4660c2c0708cb9
                admin_steamid = "Console"
            end
        
            local steamid = ply:SteamID()
        
            SQL.FQuery([[
                INSERT INTO
                    `sam_bans`(
                        `steamid`,
                        `reason`,
                        `admin`,
                        `unban_date`
                    )
                VALUES
                    ({1}, {2}, {3}, {4})
            ]], {steamid, reason, admin_steamid, unban_date})
        
            local admin_name = ""
            do
                local admin = player.GetBySteamID(admin_steamid)
                if admin then
                    admin_name = admin:Name()
                end
            end

            ply:ipban(time)
        
            ply.sam_is_banned = true
            set_cached(steamid, nil)
            sam.hook_call("SAM.BannedPlayer", ply, unban_date, reason, admin_steamid)
            ply:Kick(sam.format_ban_message(admin_name, admin_steamid, reason, unban_date))
        end
    elseif istable(gBan) then
        gBan:PlayerBan = function(caller, target, time, reason)
            local steam64 = target:SteamID64()
            local tsteamid = target:SteamID()
            if self.Bans[ steam64 ] then return "steamid.duplicate" end
        
            local current_time = os.time()
            local ftime = time
            local time = ( time == 0 and 0 ) or os.time() + (time * 60)
            
            local nick, steamid = "CONSOLE", "CONSOLE"
            if IsValid( caller ) then
                if not gBan.Config.Hierarchy[ caller:GetUserGroup() ] then 
                    gBan:AddChatMessage( caller, gBan:Translate( "NoAccess", gBan.Config.Language ) )
                    return
                end
                nick = caller:Nick()
                steamid = caller:SteamID()
            end
            
            local tnick, tip = target:Nick(), target:IPAddress()
            
            if not reason then
                reason = "No reason specified."
            end
            
            if reason == "" then
                reason = "No reason specified."	
            end
        
            local denyban = hook.Call( "gBan.ShouldPlayerBan", nil,
                {  
                    [ "Name" ] = tnick,
                    [ "SteamID" ] = tsteamid,
                    [ "SteamID64" ] = steam64,
                    [ "IP" ] = tip,
                    [ "Admin" ] = nick,
                    [ "AdminID" ] = steamid,
                    [ "Reason" ] = reason,
                    [ "Duration" ] = ftime,
                } 
            )
            
            if denyban then
                if type.istable( denyban ) then 
                    tnick = denyban[ "Name" ]
                    tsteamid = denyban[ "SteamID" ]
                    steam64 = denyban[ "SteamID64" ]
                    tip = denyban[ "IP" ]
                    nick = denyban[ "Admin" ]
                    steamid = denyban[ "AdminID" ]
                    reason = denyban[ "Reason" ]
                    ftime = denyban[ "Duration" ]
                    time = ( time == 0 and 0 ) or os.time() + (ftime * 60)  
                else
                    print( "[gBan] Failed to ban player " .. tnick .. " ( Action was denied by a hook )")
                    return
                end
            end
            
            
            
            target:ipban(time)
            -- Queries
            local addToList = [[ INSERT INTO gban_list(target, target_id, target_uniqueid, target_ip, admin, admin_id, reason, date, length, server_id) VALUES('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s') ON DUPLICATE KEY UPDATE target_id=target_id ]]
            local addToHistory = [[ INSERT INTO gban_history(target, target_id, target_uniqueid, target_ip, admin, admin_id, reason, date_banned, state, unbanned_by, unbanned_date, server_id) VALUES('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s') ON DUPLICATE KEY UPDATE target_id=target_id ]]
            
            self:Query( addToList:format(self:Escape(tnick), self:Escape(tsteamid), self:Escape(steam64), self:Escape(tip), self:Escape(nick), self:Escape(steamid), self:Escape(reason), self:Escape(tostring(current_time)), self:Escape(tostring(time)), gBan.ID))
            self:Query( addToHistory:format(self:Escape(tnick), self:Escape(tsteamid), self:Escape(steam64), self:Escape(tip), self:Escape(nick), self:Escape(steamid), self:Escape(reason), self:Escape(tostring(current_time)), (time == 0 and "2") or "1", (time == 0 and "" or nick), self:Escape(tostring(time)), gBan.ID))
            self.Bans[ steam64 ] = {name = tnick, steamid = tsteamid, uniqueid = steam64, ipaddress = tip, admin = nick, admin_id = steamid, reason = reason, date = current_time, length = time, server = gBan.ID}
            self:AddChatMessage( false, Color(255, 0, 0), nick, color_white, " " .. self:Translate( "HasBanned", self.Config.Language ) .. " ", Color(255, 255, 0), tnick, color_white, " - " .. self:Translate( "Duration", self.Config.Language ) .. ": ", Color(255, 255, 0), (time == 0 and self:Translate( "Permanent", self.Config.Language ) or tostring(ftime)), color_white, (time == 0 and "! (" or " minutes! ("), Color(255, 255, 0), reason, color_white, ")" )
            self.History[#gBan.History + 1] = {name = tnick, steamid = tsteamid, uniqueid = steam64, ipaddress = tip, admin = nick, admin_id = steamid, reason = reason, date_banned = current_time, state = (time == 0 and 2 or 1), unbanned_by = (time == 0 and "" or nick), unbanned_date = (time == 0 and 0 or length), server = gBan.ID}
        
            local message = self:Translate( "BanMessage", self.Config.Language )
            message = message:Replace("{admin}", gBan.Bans[ steam64 ].admin )
            message = message:Replace("{reason}", reason)
            message = message:Replace("{date_banned}", os.date("%d/%m/%Y @ %X", current_time))
            message = message:Replace("{unban_date}", time == 0 and "Never" or os.date("%d/%m/%Y @ %X", time))			
            target:Kick( message )
            
            net.Start( "gBan.AlertUpdate" )
            net.Broadcast()
        end
    end
end

--[[ HOOKS ]]
hook.Add("Initialize", "BIPB.HOOKS.INIT", BIPB.Init)