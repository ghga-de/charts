#!/usr/bin/python3

import requests
import logging
import shutil
import argparse
import yaml
import textwrap
from pathlib import Path
from typing import Any
from semver import Version


CHARTS_DIR = "charts"

# Optional GitHub token to increase API rate limit
TOKEN = ""


parser = argparse.ArgumentParser()
parser.add_argument("--token", help="GitHub token")
args = parser.parse_args()

if args.token:
    TOKEN = args.token

current_directory = Path(".")  # Change to the script's directory
charts_directory = current_directory / CHARTS_DIR


def has_values_yaml(service_path: Path) -> bool:
    return (service_path / "values.yaml").is_file()


def read_chart_yaml(service_path: Path) -> str | None:
    with open(service_path / "Chart.yaml") as chart_file:
        return yaml.safe_load(chart_file)


def extract_version_from_chart(service_path: Path, version: str) -> Version:
    return Version.parse(read_chart_yaml(service_path)[version])


def extract_github_repo_name(service_path: Path) -> str:
    with open(service_path / "values.yaml") as values_file:
        values = yaml.safe_load(values_file)
        repo_name = values["image"]["name"].split("/")[-1].strip().replace('"', "")
        return repo_name


def get_latest_github_release(repo_name: str) -> Version | None:
    headers = {}
    if TOKEN:
        headers["Authorization"] = f"Bearer {TOKEN}"

    url = f"https://api.github.com/repos/ghga-de/{repo_name}/releases/latest"
    response = requests.get(url, headers=headers)

    if "rate limit exceeded" in response.text.lower():
        logging.info("API Rate limit exceeded")
    elif response.status_code == 404:
        logging.info(f"Repository '{repo_name}' not found.")
    else:
        return Version.parse(response.json().get("tag_name", None))


def get_example_config_yaml(repo_name: str, version: str) -> None | Any:
    """Fetch example_config.yaml from service repository."""
    headers = {}
    if TOKEN:
        headers["Authorization"] = f"Bearer {TOKEN}"
    url = f"https://raw.githubusercontent.com/ghga-de/{repo_name}/{version}/example_config.yaml"

    response = requests.get(url, headers=headers)
    if response.status_code == 404:
        return None
    else:
        return yaml.safe_load(response.content)


def update_chart_yaml(
    service_path: Path, latest_app_version: str, new_chart_version: str
) -> None:
    """Replace version and appVersion in Chart.yaml"""
    new_file_content = []
    with open(service_path / "Chart.yaml") as chart_yaml:
        for line in chart_yaml.readlines():
            if line.startswith("appVersion:"):
                line = f'appVersion: "{latest_app_version}"\n'
            if line.startswith("version:"):
                line = f"version: {new_chart_version}\n"
            new_file_content.append(line)

    with open(service_path / "Chart.yaml", "w") as chart_yaml:
        for line in new_file_content:
            chart_yaml.write(line)


def update_values_yaml(service_path: Path, new_parameters: Any) -> None:
    """Replace service parameters in values.yaml"""
    # determine start and end line number of parameters map
    values_file = service_path / "values.yaml"
    tmp_file = service_path / ".values.yaml"

    with open(values_file) as values_yaml:
        found_start = False
        for event in yaml.parse(values_yaml):
            try:
                value = event.value
            except AttributeError:
                value = None
            # simplified, no other key default should exists
            if isinstance(event, yaml.ScalarEvent) and value == "default":
                start_line = event.start_mark.line
                found_start = True
                nested_maps = []
            if isinstance(event, yaml.MappingStartEvent) and found_start:
                nested_maps.append(event)
            if isinstance(event, yaml.MappingEndEvent) and found_start:
                if len(nested_maps) == 1:
                    end_line = event.end_mark.line
                    found_start = False
                else:
                    nested_maps.pop()

    with open(tmp_file, "w") as values_yaml_tmp, open(values_file) as values_yaml:
        for nested_maps, line in enumerate(values_yaml):
            if nested_maps > start_line and nested_maps < end_line:
                if nested_maps == end_line - 1:
                    values_yaml_tmp.write(
                        textwrap.indent(yaml.dump(new_parameters), prefix=" " * 4)
                    )
            else:
                values_yaml_tmp.write(line)
    shutil.copy(tmp_file, (service_path / "values.yaml"))
    tmp_file.unlink()


def get_new_chart_version(
    old_chart_version: Version, latest_app_version: Version, configured_version: Version
) -> Version:
    """Bump Chart version synchronous to AppVersion."""
    if latest_app_version > configured_version:
        return old_chart_version.bump_minor()


for service in charts_directory.iterdir():
    if service.is_dir() and has_values_yaml(service):
        github_repo_name = extract_github_repo_name(service)
        configured_version = extract_version_from_chart(service, "appVersion")
        latest_version = get_latest_github_release(github_repo_name)
        if (
            latest_version
            and configured_version
            and latest_version != configured_version
        ):
            old_chart_version = extract_version_from_chart(service, "version")
            new_chart_version = get_new_chart_version(
                old_chart_version, latest_version, configured_version
            )
            update_chart_yaml(service, latest_version, new_chart_version)
            new_config_parameters = get_example_config_yaml(
                github_repo_name, latest_version
            )
            update_values_yaml(service, new_config_parameters)
