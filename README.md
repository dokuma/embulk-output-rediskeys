# Rediskeys output plugin for Embulk


## Overview

* **Plugin type**: output
* **Load all or nothing**: no
* **Resume supported**: no
* **Cleanup supported**: yes

## Configuration

- host: Redis hostname (string, default:localhost).
- port: Redis port number (int, default: 6379).
- db: Number of Redis DB to dump columns (int, default: 0).
- key_prefix: Prefix of column name to set. (string, required).
- encode: Type of eoncoding of data to set (string, default:json).

## Example

```yaml
out:
  type: rediskeys
  host: localhost
  port: 6379
  db: 4
  key_prefix: test_key
  encode: json
```


## Build

```
$ rake
```
