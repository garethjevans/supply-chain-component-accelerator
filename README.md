# source-test-scan-to-url

This repository contains the source and build templates for a cartographer v2 component ready to be packaged into a carvel package.

## To Build

```shell
make carvel package
```

## To Install

```shell
make install-from-package
```

# To setup CI/CD on Runway

Follow the guide on the [CI page](./ci/)

# What to do next?

Now that your repository has been created, the next steps are to configure the build.

## Things you might want to do

Below is a list of common tasks we think that teams may want to do when the build their own component.

### Use a shared/existing namespace

To use an existing namespace, we need to stop the namespace resource from being created:

1. Remove the file `config/common/namespace.yaml`
2. Remove the reference to that file inside `config/common/kustomization.yaml`

### Add an additional docker image

Any images that need to be built as part of this package are stored within the `images` directory.  When a new image is added you'll
also need to add some configuration to ensure that it's built locally, and by lever.

Add an entry in `build-templates/kbld-config.yaml` that looks similar to:

```yaml
sources:
  - image: woke:latest
    path: images/woke
    docker:
      buildx:
        rawOptions: ["--platform", "linux/amd64"]
```

and a destination to ensure that it's pushed to the correct location:

```yaml
destinations:
  - image: woke:latest
    newImage: #@ data.values.build.registry_host + "/" + data.values.build.registry_project + "/woke"
```

to ensure that lever builds the new docker image add a new request in the file `ci/lever/manifests/request.yaml`:

```yaml
apiVersion: supplychain.cc.build/v1alpha2
kind: Request
metadata: #@ metadata("woke-image")
spec:
  artifacts:
    images:
      - name: #@ image("woke-image")
  buildType: kaniko
  buildConfig:
    kanikoBuildConfig:
      subPath: images/woke
      dockerfile: Dockerfile
      extraArgs: []
  source: #@ git()
  isOfficial: #@ data.values.official
```

and configure that as a dependant build to the main package build in `ci/lever/manifests/package-request.yaml`:

```yaml
    - imageName: #@ image("woke-image")
      kbldSource: woke:latest
      requestName: #@ namespace_name("woke-image")
```

### Use an existing docker image

To use an existing image, we need to ensure that it's relocated to the correct repository, do this by adding an entry to `build-templates/kbld-config.yaml`

```yaml
destinations:
  - image: gcr.io/my-project/my-tool:latest
    newImage: #@ data.values.build.registry_host + "/" + data.values.build.registry_project + "/my-tool"
```

### Load / Persist data from the oci-store

The following tasks can be used to load and persist a workspace to an oci registry.

```yaml
    - name: fetch
      workspaces:
        - name: store
          workspace: shared-data
      params:
        - name: url
          value: $(params.config-url)
      taskRef:
        name: fetch-tgz-content-oci
```

```yaml
    - name: store
      runAfter:
        - carvel-package
      params:
        - name: workload-name
          value: $(params.workload-name)
      taskRef:
        name: store-content-oci
      workspaces:
        - name: input
          workspace: shared-data
```

### Use a resumption to retrigger a supplychain

TODO

### Display debug information to the application developer

There is a special result called `message` that can be used to pass information to up to the UI/CLI for use by the application developer.

To use this, define a result in your task/pipeline:

```yaml
results:
- name: message
  description: Important result description, especially for error messages
```

Then write a message to that result:

```shell
printf "No git-url provided. git-url must exist" | tee $(results.message.path)
```

### Add custom rbac for the task

TODO

# Development Flow

Locally, use the `make carvel package` targets to build the pacakge locally.  Behind the scenes, this uses `kctrl` to package
the component locally and `make install-from-package` to deploy this to a TAP cluster.
 
