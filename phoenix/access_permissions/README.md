Providing secure access to directories and files on `phoenix` can be achieved using file permissions. However, the standard linux permissions of `user`, `group` and `other`
are a bit of a blunt instrument. Instead, we can use Access Control Lists (ACLs) to provide fine-grained control over who has access to our files.

To generate the list of commands required to give a specific user access to the files under a given project directory you can run:

```bash
./allow_biohub_access.sh -d /my/project/dir -u a1640443
```
