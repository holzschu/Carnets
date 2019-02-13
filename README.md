# Carnets
Carnets is a stand-alone Jupyter notebook server and client. Edit your notebooks on the go, even where there is no network.

# To install without building: 

Carnets has been approved for TestFlight by Apple. Send an [e-mail](mailto:carnets_jupyter@icloud.com) to receive an invitation. 

# To build: 
- clone the git repository
- type `./get_frameworks.sh`
- open Xcode, change the developer key, compile and install.

# Known issues / things to do:

- Save notebooks when app becomes inactive / background.
- Save last open notebook and restore when the app reopens.
- Better user interface for startup screen / ability to open notebooks everywhere, in place.
- Silently terminate oldest kernel when we approach the maximum number of kernels.
- "Terminals" don't work. Remove the option from the menus.
- user-installed packages are in `$PYTHONPATH`, which is `$HOME/Library/python`. 
- We are leaking 8-9 file descriptors for each kernel launch, and one thread. Trying to addres either of these results in *more* file descriptors being leaked.

# Recently fixed bugs:

- Fixed: Starting the 10th or so kernel fails with `zmq.error.ZMQError: Too many open files`
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

Otherwise, open an [issue](https://github.com/holzschu/carnets/issues) and I'll add it to the default packages. 
