# Screen

If you use `screen`, in particular the [~/.screenrc](rc/.screenrc) file, you will find that the "tab" titles change
whenever you perform a `cd` or `ls` command. This is because the `COMMAND_PROMPT` environmental variable is set. This is
really annoying when using `screen` or `tmux`. Simply add the following line to your `~/.bashrc` file:

```bash
unset COMMAND_PROMPT
```
