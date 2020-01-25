```bash
# Convert all files in dir to unix format
find . -type f -print0 | xargs -0 dos2unix
```