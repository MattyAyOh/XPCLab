# XPCLab
Sample App for XPC (an API for Inter-Process Communication in macOS)


## NOTE FOR DEVELOPMENT:

Whenever you want to rebuild the daemon, you have to unload it from launchd.  Use these bash commands:

```
~/dev/XPCLab
 👉  sudo launchctl unload /Library/LaunchDaemons/com.techsmith.snagitendpointdaemon.plist
~/dev/XPCLab
 👉  sudo rm /Library/PrivilegedHelperTools/com.techsmith.snagitendpointdaemon            
~/dev/XPCLab
 👉  sudo rm /Library/LaunchDaemons/com.techsmith.snagitendpointdaemon.plist         
 ```

This is because once the daemon is loaded into launchd, it apparently isn't overwritten even if you re-build it, and try to load it with `SMJobBless`.  So unloading it is the only way you can reload the new binaries

 
