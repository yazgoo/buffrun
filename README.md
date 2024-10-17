<!--
buffrun<c>: | md2html -f -o README.html && ~/dotfiles/__local/bin/open_or_refresh "$PWD/README.html" 
-->

have you ever whiched to apply a command within vim easily ?

Buffrun goal is to provide a way to do it, by adding a tag in current file.

# Usage with a file

If you want to run a command on the file you are currently editing, just use:

```
 buffrun: your_shell_command ${file_path}
```

`${file_path}` will be replaced with current file_path.

For example, this convert current file to markdown and displays the result in firefox:

```
 buffrun: grep -Ev '^buffrun' ${file_path} | md2html -o README.html && firefox README.html
```

Just run `:Buffrun` to apply the operation.

Note that we excluded the line with `^buffrun:` using `grep -v`.

# Usage with a buffer

If instead of using the file, you want to directly apply the transform on a buffer, just start your line with a pipe.

```
 buffrun: | your_shell_command
```

If we take previous example:

```
 buffrun: | md2html -o README.html && firefox README.html
```

In pipe format, you don't have to remove the `buffrun` keyword.

# Additional options

These are not yet implemented.

You can also add options to change the behavior of buffrun, for exmaple, if you want to add a prompt before running the command, you can use:

```
buffrun<c>: your_shell_command ${file_path}
```

If you want to prompt only the first time you run the buffer:

```
buffrun<C>: your_shell_command ${file_path}
```

If you want to automatically run the command when the file is written, you can use:

```
buffrun<o>: your_shell_command ${file_path}
```

If you want to open buffrun output in its own window:

```
buffrun<w>: your_shell_command ${file_path}
```

If you want buffrun output only in case of failure (silent mode)

```
buffrun<s>: your_shell_command ${file_path}
```
