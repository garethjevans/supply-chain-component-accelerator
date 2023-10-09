# source-test-scan-to-url

This repository contains the source and build templates for a cartographer v2 component ready to be packaged into a carvel package.

## To Build

```
make carvel package
```

## To Install

```
make install-from-package
```

# To setup CI/CD on Runway

Follow the guide on the [CI page](./ci/)

# What to do next?

Now that your repository has been created, the next steps are to configure the build.

## Docker Images

Any images that need to be built as part of this package are stored within the `images` directory.  When a new image is added you'll
also need to add some configuration to ensure that it's built locally, and by lever.

Add an entry in `build-templates/kbld-config.yaml` that looks similar to:

```
sources:
  - image: woke:latest
    path: images/woke
    docker:
      buildx:
        rawOptions: ["--platform", "linux/amd64"]
```

and a destination to ensure that it's pushed to the correct location:

```
destinations:
  - image: woke:latest
    newImage: #@ data.values.build.registry_host + "/" + data.values.build.registry_project + "/woke"
```

to ensure that lever builds the new docker image add a new request in the file `ci/lever/manifests/request.yaml`:

```
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

```
    - imageName: #@ image("woke-image")
      kbldSource: woke:latest
      requestName: #@ namespace_name("woke-image")
```
