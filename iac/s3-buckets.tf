
# Create S3 Bucket per environment with for_each and maps
resource "aws_s3_bucket" "s3bucketFrontendDevops" {

  for_each = {
    dev  = "devapp-devops-bucket"
    test = "testapp-devops-bucket"
    prod = "prodapp-devops-bucket"
  }

  bucket = "${each.key}-${each.value}"
  acl    = "private"

  tags = {
    eachvalue   = each.value
    Environment = each.key
    bucketname  = "${each.key}-${each.value}-Devops"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  for_each = aws_s3_bucket.s3bucketFrontendDevops

  bucket = each.value.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "website_configuration" {
  for_each = aws_s3_bucket.s3bucketFrontendDevops

  bucket = each.value.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "public" {
  for_each = aws_s3_bucket.s3bucketFrontendDevops

  bucket = each.value.id
  depends_on = [aws_s3_bucket.s3bucketFrontendDevops,
  aws_s3_bucket_acl.my-static-website]
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "${each.value.arn}/*"
        }
    ]
}
POLICY
}

# S3 bucket ACL access

resource "aws_s3_bucket_ownership_controls" "bucket" {
  for_each = aws_s3_bucket.s3bucketFrontendDevops

  bucket = each.value.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "my-static-website" {
  for_each = aws_s3_bucket.s3bucketFrontendDevops

  bucket = each.value.id
  depends_on = [
    aws_s3_bucket_ownership_controls.bucket,
    aws_s3_bucket_public_access_block.public_access_block,
  ]

  acl = "public-read"
}