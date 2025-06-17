const amplifyconfig = '''{
    "UserAgent": "aws-amplify-cli/2.0",
    "Version": "1.0",
    "storage": {
        "plugins": {
            "awsS3StoragePlugin": {
                "bucket": "taxi-routes",
                "region": "ap-northeast-1",
                "defaultAccessLevel": "guest"
            }
        }
    },
    "auth": {
        "plugins": {
            "awsCognitoAuthPlugin": {
                "UserAgent": "aws-amplify-cli/0.1.0",
                "Version": "0.1.0",
                "IdentityManager": {
                    "Default": {}
                },
                "CredentialsProvider": {
                    "CognitoIdentity": {
                        "Default": {
                            "PoolId": "",
                            "Region": "ap-northeast-1"
                        }
                    }
                }
            }
        }
    }
}'''; 