// Copyright 2016-2021, Pulumi Corporation.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

export interface StaticPageArgs {
    /**
     * The HTML content for index.html.
     */
    indexContent: pulumi.Input<string>;
}

export class StaticPage extends pulumi.ComponentResource {
    public readonly bucket: aws.s3.Bucket;
    public readonly websiteUrl: pulumi.Output<string>;

    constructor(name: string, args: StaticPageArgs, opts?: pulumi.ComponentResourceOptions) {
        super("xyz:index:StaticPage", name, args, opts);

        // Create a bucket and expose a website index document.
        const bucket = new aws.s3.Bucket(name, {
            website: {
                indexDocument: "index.html",
            },
        }, {
            parent: this,
        });

        // Create a bucket object for the index document.
        new aws.s3.BucketObject(name, {
            bucket: bucket,
            key: "index.html",
            content: args.indexContent,
            contentType: "text/html",
        }, {
            parent: bucket
        });

        // Set the access policy for the bucket so all objects are readable.
        new aws.s3.BucketPolicy("bucketPolicy", {
            bucket: bucket.bucket,
            policy: bucket.bucket.apply(name => JSON.stringify({
                Version: "2012-10-17",
                Statement: [
                    {
                        Effect: "Allow",
                        Principal: "*",
                        Action: ["s3:GetObject"],
                        Resource: [
                            `arn:aws:s3:::${name}/*`, // policy refers to bucket name explicitly
                        ],
                    },
                ],
            })),
        }, {
            parent: bucket,
        });

        this.bucket = bucket;
        this.websiteUrl = bucket.websiteEndpoint;

        this.registerOutputs({
            bucket,
            websiteUrl: bucket.websiteEndpoint,
        });
    }
}
