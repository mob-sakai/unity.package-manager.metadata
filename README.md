# Unity Package Manager (UPM) Metadata

This package is used to store metadata about other Unity packages.  
It is used by the Package Manager server to fulfill client requests.

<br><br><br>

## Description

### Scoped package registry

In Unity 2018.3, UPM supported [**scoped package registry**](https://docs.unity3d.com/Manual/upm-scoped.html).  
A scoped registry allows you to use a registry in addition to the Unity default registry where you can host your own packages.

In addition, you can use 3rd-party registries such as [openupm](https://openupm.com/), [xcrew.dev](https://xcrew.dev/) and [upm-packages.dev](https://upm-packages.dev/).

However, to use a scoped registry, you must add a `scopedRegistries` field in `Packages/manifest.json`.  
You also need to add a `scopes` field depending on the package domains.  
This feels a little annoying.

```json
{
  "scopedRegistries": [
    {
      "name": "YourPackageRegistry",
      "url": "https://your.package.registry.com",
      "scopes": [
        "com.your.package-one",
        "com.another.package-two",
        ...
      ]
    }
  ],
  "dependencies": {
    "com.your.package-one": "1.0.0",
    "com.another.package-two": "2.0.0",
    ...
  }
}
```

### A Metadata Package for UPM

The UPM system searches the packages based on a metadata package **`com.unity.package-manager.metadata`**.  
The package contains a list of all packages searchable in the UI.  
See `searchablePackages` field.

- https://packages.unity.com/com.unity.package-manager.metadata
- https://download.packages.unity.com/com.unity.package-manager.metadata/-/com.unity.package-manager.metadata-0.0.78.tgz

### What are the benefits?

If you use [verdaccio](https://verdaccio.org/) for package registry, this repository will benefit you.

- You can access all packages in your package registry.
  - Of course, the official package is also included.
- Search, install, update, and remove packages in your package registry from the `Package Manager UI` without any editor extensions.
- The `scopedRegistories` field in `manifest.json` is no longer needed.
  - Instead, use the `registry` field (supported in Unity 2017.x or later.)
  - Just edit as below:

```json
{
  "registry": "https://your.package.registry.com",
  "dependencies": {
    "com.your.package-one": "1.0.0",
    "com.another.package-two": "2.0.0",
    ...
  }
}
```

<br><br><br>

## System Requirement

- bash
- node 10.18 or later
- jq

<br><br><br>

## Usage

1. Configure your verdaccio according to [Verdaccio Configuration](#verdaccio-configuration).
2. Fork this repository and clone it.
3. Change `publishConfig.registry` field in `package.json` to **the URL of your package registry**.

```json
"publishConfig": {
  "registry": "https://your.package.registry.com"
},
```

4. You can schedule **the workflow to check the official package registry** to run at specific UTC times using [POSIX cron syntax](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/crontab.html#tag_20_25_07).  
   Edit `.github/workflows/update.yml` as following to change the schedule:

```yml
on:
  schedule:
    # check the official package registry daily.
    - cron: "* 0 * * *"
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

## Verdaccio Configuration

[Verdaccio](https://verdaccio.org) has a feature called [uplinks](https://verdaccio.org/docs/en/uplinks).  
Packages that do not exist in your package registry can be found from an proxy registry.  
For example, the `com.unity.*` packages will be found from Unity official package registry.

In addition, multiple proxies can be configured using uplinks.

Edit the verdaccio configuration file `config.yml` as follows:

```yml
uplinks:
  # the official package registry
  unity:
    url: https://packages.unity.com
  
  # the third party package registry (e.g. openupm)
  third_party:
    url: https://packages.third.party.com

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

    # if package is not available locally, proxy requests to other registries
    proxy:
      - third_party
      - unity

# notify to GitHub Actions on published a new package
notify:
  method: POST
  headers: [
    {'Content-Type': 'application/json'},
    {'Accept': 'application/vnd.github.v3+json'},
    {'User-Agent': 'verdaccio'},
    {'Authorization': "token {GITHUB_TOKEN}"}
  ]
  endpoint: 'https://api.github.com/repos/{OWNER}/unity.package-manager.metadata/dispatches'
  content: '{ "event_type":"package_published", "client_payload": {"name": "{{ name }}" } }'
```

* **NOTE: (2020/02/21) Verdaccio v4.4.2 does not support environment variables.**  
**Please correct `{OWNER}` and `{GITHUB_TOKEN}` to the correct values.**

* **NOTE: (2020/02/21) DO NOT use OpenUPM as a uplink registry**  
**For details, see https://github.com/openupm/openupm/issues/68.**

<br><br><br>

## Creating secrets in GitHub

- On GitHub, navigate to the main page of the repository.
- Under your repository name, click `Settings`.
  ![](https://help.github.com/assets/images/help/repository/repo-actions-settings.png)
- In the left sidebar, click `Secrets`.
- Type a name for your secret in the `Name` input box.
- Type the value for your secret.
- Click `Add secret`.

| Variable    | Description                                                                                                                                                                           |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `GH_TOKEN`  | **Required.** The token created via [GitHub personal access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line). |
| `NPM_TOKEN` | Npm token created via [npm token create](https://docs.npmjs.com/getting-started/working_with_tokens#how-to-create-new-tokens)                                                         |

<br><br><br>

## Update Searchable Packages Manually

If you do not need GitHub Actions, you can remove `.github/workflows/update.yml`.  
To update searchable packages manually, execute the following commands:

```sh
export GH_TOKEM=*********
export NPM_TOKEM=********* # optional
npm ci
npm run update:manually
```

**NOTE: Execute these commands each time a new package is added to your package registry.**

<br><br><br>

## Development Notes

- The official staging package registry (https://staging-packages.unity.com) has been decommissioned.  
  https://forum.unity.com/threads/how-to-use-both-packages-and-staging-packages.534115/
- Huge registries such as https://registry.npmjs.org and https://npm.pkg.github.com are not supported.
- To update searchable packages on Circle CI, Travis CI, Jenkins, etc., please refer to `.github/workflows/update.yml`.

<br><br><br>

## Support

This is an open-source project that I am developing in my free time.  
If you like it, you can support me.  
By supporting, you let me spend more time working on better tools that you can use for free. :)

[![become_a_patron_on_patreon](https://user-images.githubusercontent.com/12690315/50731629-3b18b480-11ad-11e9-8fad-4b13f27969c1.png)](https://www.patreon.com/join/2343451?)  
[![become_a_sponsor_on_github](https://user-images.githubusercontent.com/12690315/66942881-03686280-f085-11e9-9586-fc0b6011029f.png)](https://github.com/users/mob-sakai/sponsorship)

<br><br><br>

## License

- MIT

## Author

[mob-sakai](https://github.com/mob-sakai)
[![](https://img.shields.io/twitter/follow/mob_sakai.svg?label=Follow&style=social)](https://twitter.com/intent/follow?screen_name=mob_sakai)

## See Also

- GitHub page : https://github.com/mob-sakai/unity.package-manager.metadata
- OpenUPM : https://openupm.com/
