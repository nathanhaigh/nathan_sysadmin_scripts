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

# Determine Currently Available Resources on a Slurm Partition

On a busy slurm cluster it is often useful to know what resources are currently available on a partition. Slurm normally tries to fill
these "gaps" periodically by checking the resources requested by each job in the queue and if one fits the available "gap" it will
start to run the job. This process is known as "back-filling" is is one way Slurm increases system resources utilisation and can
schedule jobs to run sooner.

You could think of it as a game of tetris where the pieces are jobs, their sizes/shapes are the resources requested. Gaps that appear
during the game can be filled by the system if a small enough piece is available to fill it. In doing so, a more solid/complete wall of
blocks is achieved.

Knowing the location and sizes of the resource gaps can help you to choose a resource alloocation which will fit into the gap and thus
improve the chances that your job gets run sooner.

```bash
# check available resources on the default partition, "batch"
./slurmbf/slurmbf

# check available resources on a specified partition
./slurmbf/slurmbf -p test
./slurmbf/slurmbf -p gpu
```
