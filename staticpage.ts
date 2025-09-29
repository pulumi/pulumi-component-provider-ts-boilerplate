import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

export interface StaticPageArgs {
  // The HTML content for index.html
  indexContent: pulumi.Input<string>;
}

export class StaticPage extends pulumi.ComponentResource {
  // The URL of the static website.
  public readonly endpoint: pulumi.Output<string>;

  constructor(name: string, args: StaticPageArgs, opts?: pulumi.ComponentResourceOptions) {
    super("static-page-component:index:StaticPage", name, args, opts);

    // Create a bucket
    const bucket = new aws.s3.Bucket(`${name}-bucket`, {}, { parent: this });

    // Configure the bucket website
    const bucketWebsite = new aws.s3.BucketWebsiteConfiguration(`${name}-website`, {
      bucket: bucket.bucket,
      indexDocument: { suffix: "index.html" },
    }, { parent: bucket });

    // Create a bucket object for the index document.
    const bucketObject = new aws.s3.BucketObject(`${name}-index-object`, {
      bucket: bucket.bucket,
      key: 'index.html',
      content: args.indexContent,
      contentType: 'text/html',
    }, { parent: bucket });

    // Create a public access block for the bucket
    const publicAccessBlock = new aws.s3.BucketPublicAccessBlock(`${name}-public-access-block`, {
      bucket: bucket.id,
      blockPublicAcls: false,
    }, { parent: bucket });

    // Set the access policy for the bucket so all objects are readable
    const bucketPolicy = new aws.s3.BucketPolicy(`${name}-bucket-policy`, {
      bucket: bucket.id, // refer to the bucket created earlier
      policy: bucket.bucket.apply(this.allowGetObjectPolicy),
    }, { parent: bucket, dependsOn: publicAccessBlock });

    this.endpoint = bucketWebsite.websiteEndpoint;

    // By registering the outputs on which the component depends, we ensure
    // that the Pulumi CLI will wait for all the outputs to be created before
    // considering the component itself to have been created.
    this.registerOutputs({
      endpoint: bucketWebsite.websiteEndpoint,
    });
  }

  allowGetObjectPolicy(bucketName: string) {
    return JSON.stringify({
      Version: "2012-10-17",
      Statement: [{
        Effect: "Allow",
        Principal: "*",
        Action: [
          "s3:GetObject"
        ],
        Resource: [
          `arn:aws:s3:::${bucketName}/*`
        ]
      }]
    });
  }
}
