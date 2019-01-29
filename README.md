# Carnets
Carnets is a stand-alone Jupyter notebook server and client. Edit your notebooks on the go, even where there is no network.

# To build: 
- clone the git repository
- type `./get_frameworks.sh`
- open Xcode, change the developer key, compile and install.

# Known bugs:

- "Terminals" don't work. I will probably remove the option from the menus.
- Starting the 6th or so kernel fails with `zmq.error.ZMQError: Too many open files`

# Recently fixed bugs:

- "new file", "new notebook", "copy notebook" now open a new window (instead of opening a blank window).

# To install new packages:

If it's a pure python package, you can install it yourself:

```python
import subprocess
p = subprocess.Popen("pip install packageName", stdout = subprocess.PIPE)
out = p.stdout.read()
print(out)
```
