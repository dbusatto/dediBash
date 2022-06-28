# dediBash

Set of bash scripts that make running a dedicated server easier.
The idea is to log in via ssh to the appropriate user and
have access to simple 'start' 'stop' 'status' 'backup' 'update' commands,
that deal with the whole "launch a screen and run your server application inside" apparatus.

This means that once setup is done you don't need to remember how to launch
or stop this particular application, where the important files are, etc.
The backup utility is meant with automatic scheduled backups in mind,
in particular if the server is running it will stop it and launch it again once
the backup is done to avoid corruptions.

I tested and used this with dedicated servers for a number of games,
the corresponding `config.cfg` files can be found in `/examples`.

## Instructions:

### For start / stop and status

1) Install your server in `serverFiles`
2) Make a copy of `config_model.cfg` named `config.cfg`
3) Find out a sequence of command lines that launch your server in console from the dediBash folder (cd somewhere else if needed)
4) Find out what you need to do to stop it once it is running (press 'q', type '/quit' then press enter, ctrl+c etc)
5) fill `config.cfg` accordingly (startCmd, stopCmd)
6) if you plan on running multiple instances of dediBash in parallel, change the screenName variable in `config.cfg` to avoid conflicts

You can now test `serverScripts/dediBash.sh start`, `serverScripts/dediBash.sh stop` and `serverScripts/dediBash.sh status`.
Status tells you if the server is currently running and prints its last cmd line output.

### For backup

You need to fill `config.cfg` (backupTarget) to point dediBash to the target to back up (save file, saves directory, etc).
There is also a full-backup option meant to save the entire `serverFiles` folder (before updates for example)

Running `serverScripts/backupSequence.sh` will do the backup.
If the server was already running, then the script will stop the server, will do the backup then start the server again.
Scheduling `serverScripts/backupSequence.sh --if-needed` (as cron jobs for example) will only do a backup if the server is running.

The backups are stored in the backup folder, under different directories for standard backups and full backups of `serverFiles`.
These folders can be equipped with `config_backups.cfg` files to specify limits on how many backups to keep (minimum and maximum),
as well as a size limit for the entire folders. By default (if such a config file isn't found), min is 10 max is 100 and the size limit is 50 G.

Running `serverScripts/readBackups.sh` will display all available backups, and specify those that should be deleted
in order to be consistent with `config_backups.cfg` (oldest ones first). This deletion is not automated (to avoid mistakes),
but a script `clean_backups.sh` will be generated. Running it will delete the backups that were marked "to delete" by `readBackups.sh`.

### For update

You need to fill `config.cfg` (updateCmd) to tell dediBash how to update the server automatically (for example with SteamCmd for steam games).

Running `serverScripts/updateSequence.sh` will backup `serverFiles` then do the update.
If the server was already running, then the script will stop the server, will do the update then start the server again.

#
