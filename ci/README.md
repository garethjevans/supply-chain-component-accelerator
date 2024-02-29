# To configure the pipeline in your concourse team

```
fly --target cartographer-team login --team-name cartographer-team --concourse-url https://runway-ci.eng.vmware.com/
```

```
cd ci && ./set-pipeline.sh
```

## Vault Parameters

The generated build pipeline expects the following secrets to be available in these locations:

| Variable | Description |
| ------------- |-------------|
| ((woke-scan/github.token)) | |
| ((woke-scan/gitlab.build-project-user)) | |
| ((woke-scan/gitlab.build-project-token)) | |
| ((woke-scan/gitlab.repo-project-user)) | |
| ((woke-scan/gitlab.repo-project-token)) | |
| ((lever.prod-kubeconfig-yaml)) | |
| ((woke-scan/osspi.osm-product)) | |
| ((woke-scan/osspi.osm-apikey)) | |
| ((woke-scan/osspi.osm-username)) | |
| ((woke-scan/osspi.osm-version)) | |

There are some other things you may also want to change:

TODO

