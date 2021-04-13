# Better IP Banning(BIPB)

### Features

-   ULX Integration
-   SAM Integration
-   gBan Integration
-   Developer API
-   Optimized
-   Easy Integration

* * *

### Developer API

```lua
ply:IPBan(time)
```

Description: IP Ban player for set time.

Variables:

**Integer time** - Time to ban player in minutes
* * *
```lua
BIPB.IPBan(plyip, time, name, id)
```

Description: Ban an IP.

Variables:

**String plyip** - IP to ban

**Integer time** - Time in minutes to ban IP

**String name** - Name of player

**String id** - SteamID of player
* * *
```lua
BIPB.IsBanned(ip)
```

Description: Checks to see if IP is banned.

Variables:

**String ip** - IP to check ban

Returns:

Boolean - true if IP is banned or false if not banned.
* * *
```lua
BIPB.Time(ip)
```

Description: Unix Epoch time of unban.

Variables:

**String ip** - IP to see unban time in unix epoch

Returns:

String - Returns time in unix epoch for unban
      
* * *
```lua
BIPB.Unban(ip)
```

Description: Unban an IP.

Variables:

**String ip** - IP to unban
