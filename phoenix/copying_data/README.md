# Copy Data Between 2 Remote Hosts

If you want to copy data between two remote hosts, you may take a 2-step approach 1) copy the data from remote `host1` to your local computer `localhost`
and then 2) copy the data from `localhost` to remote `host2`.

However, if the transfer is large, you may consume a lot of local disk space or may forget to perform step 2. There is a 1-step solution involving
`rsync` and `ssh` where data is piped down a connection between `host` and `host2` via `localhost` without the need to write anything to `localhost`.

The following wrapper script provides convienient access to this:

```bash
./copy_data_between_remote_hosts.sh \
  -f user1@host1:/my/src/path \
  -t user2@host2:/my/dest/path
```
