Here you will find useful scripts and configuration files to make working on `phoenix` a little easier.

# File Access Permissions

You will find ways to modify file permissions so that other users of `phoenix` can securly access your files. This is really useful
to avoid creating multiple copies of data and thus limit storage requirements.

# Copying Data to Phoenix

When you copy data to `phoenix`, the simplest method is to have that data available on your local desktop computer (`localhost`)
and then copy it to `phoenix` using a tool such as `scp` or `rsync`. However, when the source data is on a remote computer, you may 
be tempted to take a 2-step approach to getting the data to `phoenix`: 1) download it to your `localhost` 2) upload it to
`phoenix`. Depending on the size of the data being transfered, this might require considerable local storage and time to complete.
While the [copy_data_between_remote_hosts.sh](copying_data/copy_data_between_remote_hosts.sh) script provides a 1-step approach,
the data is still being piped via your `localhost`.

# Screen

If you use `screen`, in particular the [~/.screenrc](rc/.screenrc) file, you will find that the "tab" titles change
whenever you perform a `cd` or `ls` command. This is because the `COMMAND_PROMPT` environmental variable is set. This is
really annoying when using `screen` or `tmux`. Simply add the following line to your `~/.bashrc` file:

```bash
unset COMMAND_PROMPT
```
