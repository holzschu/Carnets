# Carnets
Carnets is a stand-alone Jupyter notebook server and client. Edit your notebooks on the go, even where there is no network.

# To build: 
- clone the git repository
- type `./get_frameworks.sh`
- open Xcode, change the developer key, compile and install.

# Known bugs:

- "Terminals" don't work. I will probably remove the option from the menus.
- Starting the 10th or so kernel fails with `zmq.error.ZMQError: Too many open files`

# To fix before testflight:

- icon
- screen capture
- screen shots

# Recently fixed bugs:

- "new file", "new notebook", "copy notebook" now open a new window (instead of opening a blank window).
- Issue #3: "Kernel / restart and run all" does not work (kernel shudown followed by kernel restart does). Fixed with 9e3faa7
- Issue #2: `pip install` does not work (the package is unavailable, but the install process appears to have worked). Fixed with ee4cdc7

# To install new packages:

If it's a pure python package, you can install it yourself:

```python
import subprocess
p = subprocess.Popen("pip install packageName", stdout = subprocess.PIPE)
out = p.stdout.read()
print(out)
```
