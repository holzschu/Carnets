(some) LaTeX environments for Jupyter notebook
==============================================

[![Join the chat at https://gitter.im/jfbercher/jupyter_latex_envs](https://badges.gitter.im/jfbercher/jupyter_latex_envs.svg)](https://gitter.im/jfbercher/jupyter_latex_envs?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

This extension for Jupyter notebook enables the use of some LaTeX commands and
environments markdown cells.

1.  **LaTeX commands and environments**
    - support for some LaTeX commands within markdown cells, *e.g.*
      `\textit`, `\textbf`, `\underline`.
    - support for **theorems-like environments**, support for labels
      and cross references
    - support for **lists**: *enumerate, itemize*,
    - limited support for a **figure environment**,
    - support for an environment *listing*,
    - additional *textboxa* environment
2.  **Citations and bibliography**
    - support for `\cite` with creation of a References section
3.  **Document-wide numbering of equations and environments, support for `\label` and `\ref`**
4.  **Configuration toolbar**
5.  **LaTeX_envs dropdown menu for a quick insertion of environments**
6.  **User's LaTeX definitions** file can be loaded and used
7.  **Export to HTML and LaTeX with a customized exporter**
8.  Environments title/numbering can be customized by users in
    `user_envs.json` config file.
9.  Styles can be customized in the `latex_env.css` stylesheet
10. Limited **autocompletion** for \$, (, {, [ 

More environments can be simply added in `user_envs.json` or in the source file
(`thmsInNb4.js`).

It is possible to export the notebooks to plain $\LaTeX$ and html while keeping
all the features of the `latex_envs` notebook extension in the converted
version. We provide specialized exporters, pre and post processors, templates.
We also added entry-points to simplify the conversion process.
It is now as simple as

```bash
jupyter nbconvert --to html_with_lenvs FILE.ipynb
```

or

```bash
jupyter nbconvert --to latex_with_lenvs FILE.ipynb
```

to convert `FILE.ipynb` into html/latex while keeping all the features of the
`latex_envs` notebook extension in the converted version. The LaTeX converter
also expose several conversion options (read the
[docs](https://rawgit.com/jfbercher/jupyter_latex_envs/master/src/latex_envs/static/doc/latex_env_doc.html)).


Demo/documentation
------------------

The `doc` subdirectory that constains an example notebook and its html and pdf
versions. This serves as the documentation. A demo notebook
`latex_env_doc.ipynb` is provided. Its html version is
[latex_env_doc.html](https://rawgit.com/jfbercher/jupyter_latex_envs/master/src/latex_envs/static/doc/latex_env_doc.html)
and a pdf resulting from conversion to LaTeX is available as
[documentation](https://rawgit.com/jfbercher/jupyter_latex_envs/master/src/latex_envs/static/doc/documentation.pdf).


Installation
------------

The extension consists of a pypi package that includes a javascript notebook
extension, along with python code for nbconvert support. Since Jupyter 4.2,
pypi is the recommended way to distribute nbextensions. The extension can be
installed

- from the master version on the github repo (this will be always the
  most recent version)
- via pip for the version hosted on Pypi
- via conda, from the [conda-forge](https://conda-forge.org) [channel](https://anaconda.org/conda-forge)
- as part of the great
  [jupyter_contrib_nbextensions](https://github.com/ipython-contrib/jupyter_contrib_nbextensions)
  collection. Follow the instructions there for installing. Once this
  is done, you can open a tab at `http://localhost:8888/nbextensions`
  to enable and configure the various extensions.

From the github repo or from Pypi,

1.  install the package
     - `pip3 install https://github.com/jfbercher/jupyter_latex_envs/archive/master.zip [--user][--upgrade]`
     - or `pip3 install jupyter_latex_envs [--user][--upgrade]`
     - or clone the repo and install
           git clone https://github.com/jfbercher/jupyter_latex_envs.git
           python3 setup.py install

2.  install the notebook extension

        jupyter nbextension install --py latex_envs [--user|--sys-prefix|--system]

3.  and enable it

        jupyter nbextension enable --py latex_envs [--user|--sys-prefix|--system]

For Jupyter versions before 4.2, the situation after step 1 is more tricky,
since the `--py` option isn't available, so you will have to find the location
of the source files manually as follows (instructions adapted from
[@jcb91](https://github.com/jcb91)'s
[jupyter_highlight_selected_word](https://github.com/jcb91/jupyter_highlight_selected_word)).
Execute

    python -c "import os.path as p; from latex_envs import __file__ as f, _jupyter_nbextension_paths as n; print(p.normpath(p.join(p.dirname(f), n()[0]['src'])))"

Then, issue

    jupyter nbextension install <output source directory>
    jupyter nbextension enable latex_envs/latex_envs

where `<output source directory>` is the output of the first python command.


Disclaimer, sources and acknowledgments
---------------------------------------


Originally, I used a piece of code from the nice online markdown editor
[stackedit](https://github.com/benweet/stackedit/issues/187), where the authors
also considered the problem of incorporating LaTeX markup in their markdown.

I also studied and used examples and code from
[ipython-contrib/jupyter_contrib_nbextensions](https://github.com/ipython-contrib/jupyter_contrib_nbextensions).

This is done in the hope it can be useful. However there are many impovements
possible, in the code and in the documentation.
**Contributions will be welcome and deeply appreciated.**

- This is done in the hope it can be useful. However there are many
  impovements possible, in the code and in the documentation.
**Contributions will be welcome and deeply appreciated.**
- If you have issues, please post an issue at
  `https://github.com/jfbercher/jupyter_latex_envs/issues`
  [here](https://github.com/jfbercher/jupyter_latex_envs/issues).

**Self-Promotion** -- Like `latex_envs`? Please star and follow the
[repository](https://github.com/jfbercher/jupyter_latex_envs) on GitHub.
