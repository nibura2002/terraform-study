resource "aws_s3_bucket" "frontend" {
  bucket_prefix = "demo-frontend-"
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = ["s3:GetObject"]
        Effect    = "Allow"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
        Principal = "*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.frontend]
}

resource "aws_s3_object" "frontend" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  content      = <<-EOT
    <!DOCTYPE html>
    <html>
    <head>
      <title>Demo App</title>
      <script>
        window.API_ENDPOINT = "${var.api_endpoint}";
      </script>
    </head>
    <body>
      <div id="root"></div>
      <script>
        // This would normally be a proper React app build
        document.getElementById('root').innerHTML = '<h1>Demo Frontend</h1><p>API Endpoint: ${var.api_endpoint}</p>';
      </script>
    </body>
    </html>
  EOT
  content_type = "text/html"
} 