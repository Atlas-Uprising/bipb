
# Better IP Banning(BIPB)

### Features

 - ULX Integration
 - SAM Integration
 - gBan Integration
 - Developer API
 - Optimized
___
### Developer API

    ply:IPBan(time)
   Description: IP Ban player for set time.
   Variables:
   **Integer time** - Time to ban player in minutes

    BIPB.IPBan(plyip, time, name, id)

   Description: Ban an IP.
   Variables:
   **String plyip** - IP to ban
   **Integer time** - Time in minutes to ban IP
   **String name** - Name of player
   **String id** - SteamID of player

    BIPB.IsBanned(ip)

   Description: Ban an IP.
   Variables:
   **String ip** - IP to check ban
      Returns:
      Boolean - true if IP is banned or false if not banned.

    BIPB.Time(ip)

   Description: Ban an IP.
   Variables:
   **String ip** - IP to see unban time in unix epoch
      Returns:
      String - Returns time in unix epoch for unban
      
    BIPB.Unban(ip)

   Description: Ban an IP.
   Variables:
   **String ip** - IP to unban
