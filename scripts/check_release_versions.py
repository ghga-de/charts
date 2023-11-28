#!/usr/bin/python3

import requests
from pathlib import Path

# Base directory for charts
CHARTS_DIR = "charts"

# Optional GitHub token to increase API rate limit
TOKEN = ""

UPDATES = False

# Parse command-line arguments
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--token", help="GitHub token")
parser.add_argument(
    "--updates", help="Should config updates been shown", action="store_true"
)
args = parser.parse_args()

if args.token:
    TOKEN = args.token

current_directory = Path(".")  # Change to the script's directory
charts_directory = current_directory / CHARTS_DIR


def has_values_yaml(service_path):
    return (service_path / "values.yaml").is_file()


def extract_app_version(service_path):
    with open(service_path / "Chart.yaml") as chart_file:
        for line in chart_file:
            if line.startswith("appVersion:"):
                return line.split('"')[1].strip()
    return None


def extract_github_repo_name(service_path):
    with open(service_path / "values.yaml") as values_file:
        for line in values_file:
            if "image:" in line:
                repo_name = next(values_file).split("/")[-1].strip().replace('"', "")
                return repo_name
    return None


def get_latest_github_release(repo_name):
    headers = {}
    if TOKEN:
        headers["Authorization"] = f"Bearer {TOKEN}"

    url = f"https://api.github.com/repos/ghga-de/{repo_name}/releases/latest"
    response = requests.get(url, headers=headers)

    if "rate limit exceeded" in response.text.lower():
        return "RateLimitExceeded"
    elif "not found" in response.text.lower():
        return "NotFound"
    else:
        return response.json().get("tag_name", None)


def download_config(repo_name, version):
    headers = {}
    if TOKEN:
        headers["Authorization"] = f"Bearer {TOKEN}"
    url = f"https://raw.githubusercontent.com/ghga-de/{repo_name}/{version}/config_schema.json"

    response = requests.get(url, headers=headers)
    if response.status_code == 404:
        return None
    else:
        return response.json()


def compare_parameters(
    dict_old: dict, dict_new: dict, only_required=True
) -> dict[str, list]:
    changes: dict[str, list] = {"added": [], "removed": [], "updated": []}
    properties_old = dict_old["properties"]
    properties_new = dict_new["properties"]
    required = dict_new.get("required", []) if only_required else []
    old_keys = properties_old.keys()
    new_keys = properties_new.keys()

    for key in old_keys:
        if key not in new_keys:
            changes["removed"].append(key)

    for key in new_keys:
        if key not in old_keys and key in required:
            changes["added"].append(key)

    for key in new_keys:
        if key in old_keys:
            if properties_old[key] != properties_new[key]:
                changes["updated"].append(key)

    return changes


skipped_services = []
updated_services = []
updated_configs = []

for service in charts_directory.iterdir():
    if service.is_dir() and has_values_yaml(service):
        service_name = service.name
        github_repo_name = extract_github_repo_name(service)

        configured_version = extract_app_version(service)
        latest_version = get_latest_github_release(github_repo_name)

        # If API Rate limit exceeded, exit
        if latest_version == "RateLimitExceeded":
            print("API Rate limit exceeded")
            exit(1)

        # If the GitHub API returns 404
        if latest_version == "NotFound":
            if configured_version == "0.0.0":
                skipped_services.append(f"{service_name}: No release (0.0.0)")
            else:
                skipped_services.append(f"{service_name}: Repository not found")
            continue

        if latest_version != configured_version:
            updated_services.append(
                f"{service_name}: {configured_version} < {latest_version}"
            )

        # Detect changes in config.json
        old_config = download_config(github_repo_name, configured_version)
        new_config = download_config(github_repo_name, latest_version)

        if old_config and new_config:
            comparison = compare_parameters(old_config, new_config)
            out_str: str = f"{service_name}:\n"
            has_changes: bool = False

            if UPDATES:
                events: list[str] = ["added", "removed", "updated"]
            else:
                events: list[str] = ["added", "removed"]

            for event in events:
                changes = comparison.get(event, [])
                if changes:
                    has_changes = True
                    out_str += f"\t{event}:\n"
                    for entry in changes:
                        if entry:
                            out_str += "\t\t" + entry + "\n"
            if has_changes:
                updated_configs.append(out_str)
    else:
        skipped_services.append(f"{service}: values.yaml not found")

# Report skipped services
print("Skipped:")
for service in skipped_services:
    print(f" {service}")

# Report updated services
print("New release available:")
for service in updated_services:
    print(f" {service}")

print("Configs changed:")
for service in updated_configs:
    print(service)
