It can be useful to see which users are a member of a particular Linux group. Here are a couple of ways this can be
achived on `phoenix`:

Get a list of usernames.

```bash
A_GROUP='phoenix-hpc-avsci'
getent group "${A_GROUP}" \
  | cut -f4- -d":" \
  | tr ',' '\n'
```

Get a list of real names.

**NOTE: Expired users without an entry in `passwd` will be silently dropped from the output.**

```bash
A_GROUP='phoenix-hpc-avsci'
getent group "${A_GROUP}" \
  | cut -f4- -d":" \
  | tr ',' '\n' \
  | xargs getent passwd \
  | cut -f5 -d":"
```
