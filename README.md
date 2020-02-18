# Unity Package Manager (UPM) Metadata:<br>For Custom Package Registry

This package is used to store metadata about other Unity packages.  
It is used by the Package Manager server to fulfill client requests.

<br><br><br>

## Description

The UPM system searches the packages based on a metadata package.
The package contains a list of all packages searchable in the UI.
https://packages.unity.com/com.unity.package-manager.metadata
https://download.packages.unity.com/com.unity.package-manager.metadata/-/com.unity.package-manager.metadata-0.0.77.tgz

If you are using a [verdaccio-based package registry](https://verdaccio.org/) for UPM, this repository will benefit.

- You can access all packages in your package registry.
  - Of course, the official package is also included.
- Search, install, update, and remove packages in your package registry from the `Package Manager UI` without any editor extensions.
- The `scopedRegistories` field will be no longer required. Just edit `manifest.json` as below:

```json
{
  "dependencies": {
    ...
  },
  "registry": "https://your.package.registry.com"
}
```

For details, see https://github.com/openupm/openupm/issues/61.

<br><br><br>

## System Requirement

- node 10.18
- jq

<br><br><br>

## Usage

1. Fork this repository and clone it.
2. Change `publishConfig.registry` field in `package.json` to **the URL of your package registry**.

```json
"publishConfig": {
  "registry": "https://your.package.registry.com"
},
```

3. Remove `searchablePackages` field in `package.json`.  
   Or, execute the following command:

```
npm run init
```

4. You can schedule the workflow to run at specific UTC times using [POSIX cron syntax](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/crontab.html#tag_20_25_07).  
   Edit `.github/workflows/update.yml` as following to change the schedule:

```yml
on:
  schedule:
    # run At every 30th minute.
    - cron: "*/30 * * * *"
```

5. The workflow will push updates to the repository.  
   See [Creating secrets in GitHub](#creating-secrets-in-github) and add `GH_TOKEN` secret on GitHub.

6. (Optional) To publish this package to your package registry, follow these steps:
   1. add `NPM_TOKEN` secret on GitHub. For details, see [Creating secrets in GitHub](#creating-secrets-in-github).
   2. Edit `.releaserc` as follows:

```json
{
  "plugins": [
    [
      "@semantic-release/npm",
      {
        "npmPublish": true
      }
    ],
    ...
  ]
}
```

7. (Optional) [Update searchable packages manually](#update-searchable-packages-manually)

<br><br><br>

## Creating secrets in GitHub

- On GitHub, navigate to the main page of the repository.
- Under your repository name, click `Settings`.
  ![](https://help.github.com/assets/images/help/repository/repo-actions-settings.png)
- In the left sidebar, click `Secrets`.
- Type a name for your secret in the `Name` input box.
- Type the value for your secret.
- Click `Add secret`.

| Variable    | Description                                                                                                                   |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `GH_TOKEN`  | **Required.** The token used to authenticate with GitHub.<br>The token requires the permission to push to the repository.     |
| `NPM_TOKEN` | Npm token created via [npm token create](https://docs.npmjs.com/getting-started/working_with_tokens#how-to-create-new-tokens) |

<br><br><br>

## Update Searchable Packages Manually

To update searchable packages manually, execute the following commands:

```sh
export GH_TOKEM=*********
export NPM_TOKEM=********* # optional
npm ci
npm run update:local
```

If you don't need GitHub Actions, remove `.github/workflows/update.yml`.

<br><br><br>

## Verdaccio Settings

Verdaccio has a feature called [uplinks](https://verdaccio.org/docs/en/uplinks).  
Packages that do not exist in your package registry can be found from an proxy registry.  
For example, the `com.unity.*` packages will be found from Unity official package registry.

Edit the verdaccio configuration file `config.yml` as follows:

```yml
uplinks:
  # unity official package registry
  unity:
    url: https://packages.unity.com

packages:
  # the metadata package should be found in your package registry
  "com.unity.package-manager.metadata":
    access: $all
    publish: $authenticated

  # unity official packages should be found in official package registry
  "com.unity.*":
    access: $all
    proxy: unity

  # other packages
  "**":
    access: $all
    publish: $authenticated
    unpublish: $authenticated

    # if package is not available locally, proxy requests to 'unity' registry
    proxy: unity
```

<br><br><br>

## License

- MIT

## Author

[mob-sakai](https://github.com/mob-sakai)
[![](https://img.shields.io/twitter/follow/mob_sakai.svg?label=Follow&style=social)](https://twitter.com/intent/follow?screen_name=mob_sakai)
