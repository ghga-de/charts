# GHGA Chart Update Helper Script
## TL;DR
```shell
python scripts/update_charts/update_charts.py --token $GITHUB_TOKEN
```

> [!CAUTION]
> This script modifies Chart.yaml and values.yaml in place.

## Description

This script is intended to accelerate the process of comparing GHGA Charts and service releases. It performs the following tasks:

1. Compares the Charts and service releases to identify if there is a new service release.
2. If a new release is detected, it automatically creates a new version in the Chart.yaml file and dumps the Chart version minor.
3. Updates the service parameters in the values.yaml file with the default configuration `example_config.yaml` from the service repository.
4. The script modifies Chart.yaml and values.yaml in place to facilitate easier tracking of changes using `git diff`.

    
> [!NOTE]
> The script relies on proper versioning and structure of the charts and service releases. Make sure your repository follows the expected format for accurate comparison and updating.

> [!NOTE]
> The update of the service parameters in  `values.yaml` is not always carried out accurately. This needs to be manually reviewed.
