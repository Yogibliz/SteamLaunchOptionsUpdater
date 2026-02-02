import sys
import os
import shutil
import vdf

# ---------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------

# The internal path Steam uses for game configs
# Structure: UserLocalConfigStore -> Software -> Valve -> Steam -> apps
PATH_KEYS = ["UserLocalConfigStore", "Software", "Valve", "Steam", "apps"]

# ---------------------------------------------------------
# SCRIPT
# ---------------------------------------------------------

def update_config(file_path, launch_options, target_ids):
    if not os.path.exists(file_path):
        print(f"Error: File not found at {file_path}")
        sys.exit(1)

    # Create a Backup, in case something breaks.
    file_size_bytes = os.path.getsize(file_path)
    file_size_kib = file_size_bytes / (2**10) # Get in KiB
    
    backup_path = file_path + ".bak"
    shutil.copyfile(file_path, backup_path)
    print(f"Backup created: {backup_path} ({file_size_kib:.2f} KiB)")

    # Open and Parse the VDF file
    print("Parsing VDF file structure...")
    with open(file_path, 'r', encoding='utf-8') as f:
        data = vdf.load(f)

    # Navigate to the 'apps' section
    current_section = data
    try:
        for key in PATH_KEYS:
            current_section = current_section[key]
    except KeyError as e:
        print(f"Error: Could not find section '{e}' in the config file.")
        sys.exit(1)

    # Update the Target Games
    updates_count = 0
    for app_id in target_ids:
        # Check if the game exists in this config file
        if app_id in current_section:
            # Update the dictionary key directly
            current_section[app_id]['LaunchOptions'] = launch_options
            print(f"  [+] Updated AppID {app_id}")
            updates_count += 1
        else:
            print(f"  [-] Skipped AppID {app_id} (Not found in config)")

    # Save the file
    if updates_count > 0:
        print(f"Saving changes for {updates_count} games...")
        with open(file_path, 'w', encoding='utf-8') as f:
            vdf.dump(data, f, pretty=True) 
        print("Success.")
    else:
        print("No changes were necessary.")

if __name__ == "__main__":
    # Expects: script.py <path_to_vdf> <launch_options> <appid_1> <appid_2> ...
    update_config(sys.argv[1], sys.argv[2], sys.argv[3:])
