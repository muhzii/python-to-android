# Shell script for cross-compiling Python with NDK

# Pre-requisites
- NDK r19.
- A host Linux machine.
- Python3.7 built for host with `python3.7` on PATH (Recommended: use virtualenv to manage different versions of Python).
- A git-3.7 clone of CPython for use in cross build.

# How to use
```
git clone https://github.com/muhzii/python-to-android.git
cd python-to-android
./xcompile-python.sh <target_architecture> <path_to_ndk> <path_to_python>
```
