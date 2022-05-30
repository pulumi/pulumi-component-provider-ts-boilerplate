# Pulumi Component Provider Boilerplate (TypeScript)

This repo is a boilerplate showing how to create a Pulumi component provider written in TypeScript. You can search-replace `xyz` with the name of your desired provider as a starting point for creating a component provider for your component resources.

## Background
This repository is part of the [guide for authoring and publishing a Pulumi Package](https://www.pulumi.com/docs/guides/pulumi-packages/how-to-author).

Learn about the concepts behind [Pulumi Packages](https://www.pulumi.com/docs/guides/pulumi-packages/#pulumi-packages) and, more specifically, [Pulumi Components](https://www.pulumi.com/docs/intro/concepts/resources/components/)

## Sample xyz Component Provider

An example `StaticPage` [component resource](https://www.pulumi.com/docs/intro/concepts/resources/#components) is available in `provider/cmd/pulumi-resource-xyz/staticPage.ts`. This component creates a static web page hosted in an AWS S3 Bucket. There is nothing special about `StaticPage` -- it is a typical component resource written in TypeScript.

The component provider makes component resources available to other languages. The implementation is in `provider/cmd/pulumi-resource-xyz/provider.ts`. Each component resource in the provider must have an implementation in the `construct` method to create an instance of the requested component resource and return its `URN` and state (outputs). There is an initial implementation that demonstrates an implementation of `construct` for the example `StaticPage` component.

A code generator is available which generates SDKs in TypeScript, Python, Go and .NET which are also checked in to the `sdk` folder. The SDKs are generated from a schema in `schema.json`. This file should be kept aligned with the component resources supported by the component provider implementation.

An example of using the `StaticPage` component in TypeScript is in `examples/simple`.

Note that the provider plugin (`pulumi-resource-xyz`) must be on your `PATH` to be used by Pulumi deployments. In this case, `pulumi-resource-xyz` is a platform-specific binary that includes its Node.js dependency along with the provider code, created using [pkg](https://github.com/vercel/pkg). By default, running `make install` will create the binary specific to your host environment.

After running `make install`, `pulumi-resource-xyz` will be available in the `./bin` directory. You can add this to your path in bash with `export PATH=$PATH:$PWD/bin`.

If creating a provider for distribution to other users, they will need the `pulumi-resource-xyz` directory on their `PATH`. See the Packaging section below for more on distributing the provider to users.

## Prerequisites

- Pulumi CLI
- Node.js
- Yarn
- Go 1.17 (to regenerate the SDKs)
- Python 3.6+ (to build the Python SDK)
- .NET Core SDK (to build the .NET SDK)

## Build and Test

```bash
# Build and install the provider
make install_provider

# Regenerate SDKs
make generate

# Ensure the pulumi-provider-xyz script is on PATH
$ export PATH=$PATH:$PWD/bin

# Test Node.js SDK
$ make install_nodejs_sdk
$ cd examples/simple
$ yarn install
$ yarn link @pulumi/xyz
$ pulumi stack init test
$ pulumi config set aws:region us-east-1
$ pulumi up
```

## Naming

The `xyz` provider's plugin must be named `pulumi-resource-xyz` (in the format `pulumi-resource-<provider>`).

While the provider plugin must follow this naming convention, the SDK package naming can be customized. TODO explain.

## Packaging

The provider plugin can be packaged into a tarball and hosted at a custom server URL to make it easier to distribute to users.

Currently, five tarball files are necessary for Linux, macOS, and Windows (`pulumi-resource-xyz-v0.0.1-linux-amd64.tar.gz`, `pulumi-resource-xyz-v0.0.1-linux-arm64.tar.gz` `pulumi-resource-xyz-v0.0.1-darwin-amd64.tar.gz`, `pulumi-resource-xyz-v0.0.1-darwin-arm64.tar.gz`, `pulumi-resource-xyz-v0.0.1-windows-amd64.tar.gz`) each containing the same files: the platform-specific binary `pulumi-resource-xyz`, README and LICENSE. The fill set of binaries can be automatically generated using the command `make dist`.

TODO explain custom server hosting in more detail.

## Configuring CI and releases

1. Follow the instructions laid out in the [deployment templates](./deployment-templates/README-DEPLOYMENT.md).


## Example component

Let's look at the example `StaticPage` component resource in more detail.

### Schema

The example `StaticPage` component resource is defined in `schema.json`:

```json
"resources": {
"xyz:index:StaticPage": {
"isComponent": true,
"inputProperties": {
"indexContent": {
"type": "string",
"description": "The HTML content for index.html."
}
},
"requiredInputs": [
"indexContent"
],
"properties": {
"bucket": {
"$ref": "/aws/v3.30.0/schema.json#/resources/aws:s3%2Fbucket:Bucket",
"description": "The bucket resource."
},
"websiteUrl": {
"type": "string",
"description": "The website URL."
}
},
"required": [
"bucket",
"websiteUrl"
]
}
}
```

The component resource's type token is `xyz:index:StaticPage` in the format of `<package>:<module>:<type>`. In this case, it's in the `xyz` package and `index` module. This is the same type token passed inside the implementation of `StaticPage` in `provider/cmd/pulumi-resource-xyz/staticPage.ts`, and also the same token referenced in `construct` in `provider/cmd/pulumi-resource-xyz/provider.ts`.

This component has a required `indexContent` input property typed as `string`, and two required output properties: `bucket` and `websiteUrl`. Note that `bucket` is typed as the `aws:s3/bucket:Bucket` resource from the `aws` provider (in the schema the `/` is escaped as `%2F`).

Since this component returns a type from the `aws` provider, each SDK must reference the associated Pulumi `aws` SDK for the language. For the .NET, Node.js, and Python SDKs, dependencies are specified in the `language` section of the schema:

```json
"language": {
"csharp": {
"packageReferences": {
"Pulumi": "2.*",
"Pulumi.Aws": "3.*"
}
},
"nodejs": {
"dependencies": {
"@pulumi/aws": "^3.30.0"
},
"devDependencies": {
"typescript": "^3.7.0"
}
},
"python": {
"requires": {
"pulumi": ">=2.21.2,<3.0.0",
"pulumi-aws": ">=3.30.0,<4.0.0"
}
}
}
```

For the Go SDK, dependencies are specified in the `sdk/go.mod` file.

### Implementation

The implementation of this component is in `provider/cmd/pulumi-resource-xyz/staticPage.ts` and the structure of the component's inputs and outputs aligns with what is defined in `schema.json`:

```typescript
export interface StaticPageArgs {
    indexContent: pulumi.Input<string>;
}

export class StaticPage extends pulumi.ComponentResource {
    public readonly bucket: aws.s3.Bucket;
    public readonly websiteUrl: pulumi.Output<string>;

    constructor(name: string, args: StaticPageArgs, opts?: pulumi.ComponentResourceOptions) {
        super("xyz:index:StaticPage", name, args, opts);

    ...
    }
}
```

The provider makes this component resource available in the `construct` method in `provider/cmd/pulumi-resource-xyz/provider.ts`. When `construct` is called and the `type` argument is `xyz:index:StaticPage`, we create an instance of the `StaticPage` component resource and return its `URN` and outputs as its state.


```typescript
async function constructStaticPage(name: string, inputs: pulumi.Inputs,
                                   options: pulumi.ComponentResourceOptions): Promise<provider.ConstructResult> {

    // Create the component resource.
    const staticPage = new StaticPage(name, inputs as StaticPageArgs, options);

    // Return the component resource's URN and outputs as its state.
    return {
        urn: staticPage.urn,
        state: {
            bucket: staticPage.bucket,
            websiteUrl: staticPage.websiteUrl,
        },
    };
}
```
