# Phoenix Service Units per BioHub Group Member

Return a list of `phoenix-hpc-biohub` group members sorted by the number of `phoenix` Service Units (SU) used.

```bash
getent group phoenix-hpc-biohub | sed 's/^.\+://' | tr ',' '\n' | while read u; do
  rcquota -u "$u"
done \
  | fgrep -e '+-->' /tmp/biohub.su \
  | awk '{tot[$1]+=$3}END{for (u in tot){if(tot[u]>0){print u,tot[u]}}}' \
  | sort -k2nr,2
```
