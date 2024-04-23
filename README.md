[FluentBit](https://github.com/boilingdata/data-taps-fluentbit-example) | [Web Analytics](https://github.com/boilingdata/data-taps-webanalytics-example) | [PostgreSQL CDC](https://github.com/boilingdata/data-taps-postgres-cdc) | [REST API](https://github.com/boilingdata/data-taps-nycopendata-example) | [OpenSearch/ES](https://github.com/boilingdata/data-taps-opensearch-to-s3)

# FluentBit --> Data Tap --> S3 Parquet

<p align="center">
  <img src="img/fluentbit-collectd.png" title="simple architecture">
</p>

Our building blocks:

- [collectd](https://www.collectd.org/): _"Systems statistics collection daemon"_
- [fluentbit](https://fluentbit.io/): _"A super fast, lightweight, and highly scalable logging and metrics processor and forwarder. It is the preferred choice for cloud and containerized environments"_
- [Data Taps](https://www.taps.boilingdata.com/): Managed hyper scale HTTP URL for posting newline JSON at any scale, SQL transformation, and landing to S3 with optimal format.

Data Taps makes a perfect end point for colllecting logs, metrics, events etc. efficiently and in scale to S3 -- a single smallest AWS Lambda, so you don't have to worry about clusters or costs. Purely from data storage cost perspective Data Taps is at least 50-80x more cost efficient than Elasticsearch with EBS volumes (assuming EBS is 100% utilised which never is the case of a healthy system, rather closer to 50%). Data Taps brings your data to S3 in de-factor compressed Parquet format, where you want them to land in the end anyway.

## Building Blocks

### 1. collectd

`collectd` daemon with [collectd.conf](collectd.conf) as input source for Fluent Bit client below.

```shell
brew install collectd
```

### 2. FluentBit

Install FluentBit. The [`fluent-bit.yaml`](fluent-bit.yaml) configuration file includes `collectd` input and Data Tap HTTP(s) output with `x-bd-authorization` token.

```shell
brew install fluent-bit
```

### 3. Data Tap

A Data Tap is a single AWS Lambda function with [Function URL](https://docs.aws.amazon.com/lambda/latest/dg/lambda-urls.html) and customized C++ runtime embedding [DuckDB](https://www.duckdb.org/). It uses streaming SQL clause to upload the buffered HTTP POSTed newline JSON data in the Lambda to S3, hive partitioned, and as ZSTD compressed Parquet. You can tune the SQL clause your self for filtering, search, and aggregations. You can also set the thresholds when the upload to S3 happens. A Data Tap runs already very efficiently with the smallest arm64 AWS Lambda, making it the simplest, fastest, and most cost efficient solution for streaming data onto S3 in scale. You can run it on [your own AWS Account](https://github.com/boilingdata/data-taps-template) or hosted by Boiling Cloud.

You need to have [BoilingData account](https://github.com/boilingdata/boilingdata-bdcli) and use it to create a [Data Tap](https://github.com/boilingdata/data-taps-template). The account is used to [fetch authorization tokens](https://github.com/boilingdata/data-taps-template?tab=readme-ov-file#3-get-token-and-ingestion-url-and-send-data) which allow you to send data to a Data Tap (security access control). You can also share write access (see the `AUTHORIZED_USERS` AWS Lambda environment variable) to other BoilingData users if you like, efficiently creating Data Mesh architectures.

## Prerequisites

1. You need a Data Tap on your AWS Account. You can follow these instructions.
   https://github.com/boilingdata/data-taps-template/tree/main/aws_sam_template

2. Export fresh Tap token as `TAP_TOKEN` environment variable and `TAP_URL` env var as the Tap ingestion URL endpoint by using [bdcli](https://github.com/boilingdata/boilingdata-bdcli) (see previous step).

```shell
# 1. You will get the TAP URL from the Tap deployment you did in the first step
export TAP_URL='https://...'
# 2a. If you send to your own Data Tap (sharing user is the as your BoilingData username)
export TAP_TOKEN=`bdcli account tap-client-token --disable-spinner | jq -r .bdTapToken`
# 2b. If you send to somebody else's Data Tap, replace "boilingSharingUsername"
export TAP_TOKEN=`bdcli account tap-client-token --sharing-user boilingSharingUsername --disable-spinner | jq -r .bdTapToken`
```

## Start Collecting Statistics

Start collectd. It requires root privileges to collect CPU statistics.

```shell
# 1. start collectd
cp collectd.conf /opt/homebrew/etc/collectd.conf
sudo /opt/homebrew/opt/collectd/sbin/collectd -f -C /opt/homebrew/etc/collectd.conf
# 2. start fluent-bit that gets the collectd statistics and sends to Data Tap
./setup-config.sh # setups fluent-bit.conf
/opt/homebrew/bin/fluent-bit -c fluent-bit.conf
```

## Checking Data

You can check the uploaded Parquet files in your S3 bucket and download them to your local laptop and get a glimpse into them with e.g. [DuckDB](https://duckdb.org/).

```shell
aws s3 sync s3://YOURBUCKET/datataps/ d/
duckdb -s "SELECT COUNT(*) FROM parquet_scan('./d/**/*.parquet');"
```

Alternatively you can run the analytics on the cloud side with BoilingData. For example, a one-off SQL query with bdcli.

```shell
bdcli api query  -s "SELECT COUNT(*) FROM parquet_scan('s3://YOURBUCKET/datataps/');"
```
