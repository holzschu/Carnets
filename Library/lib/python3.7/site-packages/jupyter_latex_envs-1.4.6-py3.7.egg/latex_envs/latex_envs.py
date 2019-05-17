"""latex_envs Exporter class"""

# -----------------------------------------------------------------------------
# Copyright (c) 2016-18, J.-F. Bercher
#
# Distributed under the terms of the Modified BSD License.
#
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Imports
# -----------------------------------------------------------------------------

# Stdlib imports
import os
import re

# IPython imports
from IPython.display import HTML, display,JSON
from nbconvert.exporters.exporter import Exporter
from nbconvert.exporters.html import HTMLExporter
from nbconvert.exporters.latex import LatexExporter
from nbconvert.exporters.slides import SlidesExporter

# from nbconvert.postprocessors.base import PostProcessorBase
from nbconvert.filters.highlight import Highlight2HTML, Highlight2Latex
from nbconvert.preprocessors import Preprocessor
from traitlets import Bool, Dict
from traitlets.config import Config


# A small utilitary function
def figcaption(text, label=" "):
    display(HTML("<div class=caption><b> Caption: </b> %s</div>"
                 % text.replace('\n', '<br>')))
    text = text.replace('<b>',r'\textbf{').replace('</b>','}') #some replacement of HTML formatting
    text = text.replace('<i>',r'\textit{').replace('</i>','}')
    text = text.replace('<tt>',r'\texttt{').replace('</tt>','}')
    display(JSON({'caption': text, 'label':label}),include=["application/json"])

# -----------------------------------------------------------------------------
# Preprocessors, Exporters, PostProcessors
# -----------------------------------------------------------------------------


class LenvsLatexPreprocessor(Preprocessor):

    environmentMap = ['thm', 'lem', 'cor', 'prop', 'defn', 'rem',
                      'prob', 'excs', 'examp', 'theorem', 'lemma',
                      'corollary', 'proposition', 'definition', 'remark',
                      'problem', 'exercise', 'example', 'proof', 'property',
                      'itemize', 'enumerate', 'theo', 'enum']
    # this map should match the map defined in thmsInNb4.js
    # do not include figure

    def __call__(self, nb, resources):
        if self.enabled:
            self.log.debug("Applying preprocessor: %s",
                           self.__class__.__name__)
            return self.preprocess(nb, resources)
        else:
            return nb, resources

    def preprocess(self, nb, resources):
        """
        Preprocessing to apply on each notebook.

        Must return modified nb, resources.

        If you wish to apply your preprocessing to each cell, you might want
        to override preprocess_cell method instead.

        Parameters
        ----------
        nb : NotebookNode
            Notebook being converted
        resources : dictionary
            Additional resources used in the conversion process.  Allows
            preprocessors to pass variables into the Jinja engine.
        """
        
        #process metadata

        
        for index, cell in enumerate(nb.cells):
            nb.cells[index], resources = self.preprocess_cell(cell,
                                                              resources, index)
        return nb, resources

    def replacement(self, match):
        theenv = match.group(1)
        tobetranslated = match.group(3)
        opt_parameter = ''
        if match.group(2) is not None: opt_parameter =  match.group(2).replace('[','!lb!').replace(']','!rb!')
        out = "!sl!begin!op!" + theenv + '!cl@' + opt_parameter + tobetranslated + "!sl!end!op!" + theenv + '!cl@'  # noqa
        # out = out.replace('\n', '!nl!') #dont remember why I did that
        if theenv in self.environmentMap:
            return out
        else:
            return match.group(0).replace('\\begin', '/begin').replace('\\end', '/end')#out

    def inline_math_strip_space(self,match):
        return "$"+match.group(1).replace(' ','')+"$"
    
    
    def preprocess_cell(self, cell, resources, index):
        """
        Preprocess cell

        Parameters
        ----------
        cell : NotebookNode cell
            Notebook cell being processed
        resources : dictionary
            Additional resources used in the conversion process.  Allows
            preprocessors to pass variables into the Jinja engine.
        cell_index : int
            Index of the cell being processed (see base.py)
        """
        if cell.cell_type == "markdown":
            data = cell.source
            data = data.replace(r"$\LaTeX$", r"\LaTeX")
            data = data.replace(r"{enumerate}", r"{enum}")
            code = re.search(r'\\begin{(\w+)}([\s\S]*?)\\end{\1}', data)
            while (code is not None):
                data = re.sub(r'\\begin{(\w+)}(\[[\S\s]*?\])?([\s\S]*?)\\end{\1}',
                #data = re.sub(r'\\begin{(\w+)}([\s\S]*?)\\end{\1}',
                              self.replacement, data)
                data = re.sub(r'\n\s*\\item', r'//item',data)
                data = data.replace(r'\item', r'/item')
                code = re.search(r'\\begin{(\w+)}([\s\S]*?)\\end{\1}', data)
            data = re.sub(r'\\\[([\s\S]*?)\\\]', r'$$\1$$', data) #$$.$$ is converted into \[.\] #noqa
            data = re.sub(r'\\\(([\s\S]*?)\\\)', self.inline_math_strip_space, data) #$.$ converted into \(.\) #noqa
            #data = data.replace('\n', '!nl!\n')
            data = data.replace('\\\\', '!sl!!sl!')
            data = re.sub(r'%([\S\s ]*?)\n', r'!cc!\1!nl!',data)
            #data = data.replace('%', '!cc!')
            data = data.replace("/begin", "\\begin")
            data = data.replace("/end", "\\end")
            cell.source = data
        elif cell.cell_type == "code" and "outputs" in cell:
            json_metadata = []
            mime_types  = ['image/svg+xml','image/png','image/jpeg','application/pdf']
            # Below just an ad hoc personnal filter 
            if "%run nbinit.ipy" in cell.source:
                cell.source = ''
                cell.cell_type = "raw"                
                return cell, resources
            for output in cell.outputs:
                if "data" in output:
                    if 'text/html' in output.data and 'img src' in output.data['text/html']:
                        data = output.data['text/html']
                        data = re.sub(r'<img src="data:image/png;base[\d]+,','',data)
                        data = re.sub(r'" width="[\d]+">','',data)
                        output.data['image/png'] = data # make png data from html data
                    elif  'application/json' in output.data and 'caption' in output.data['application/json']: #found a json field with caption
                        json_metadata.append(output.data['application/json'])
                        
                    if any(x in output.data for x in mime_types) and len(json_metadata)>0:
                        output.metadata.update(json_metadata.pop()) # write caption to data field metadata
                
        return cell, resources


class LenvsHTMLPreprocessor(Preprocessor):

    environmentMap = ['thm', 'lem', 'cor', 'prop', 'defn', 'rem',
                      'prob', 'excs', 'examp', 'theorem', 'lemma',
                      'corollary', 'proposition', 'definition', 'remark',
                      'problem', 'exercise', 'example', 'proof', 'property',
                      'itemize', 'enumerate', 'theo', 'enum']
    # this map should match the map defined in thmsInNb4.js
    # do not include figure

    def replacement(self, match):
        return "\n" + match.group(0)

    def preprocess_cell(self, cell, resources, index):
        """
        Preprocess cell

        Parameters
        ----------
        cell : NotebookNode cell
            Notebook cell being processed
        resources : dictionary
            Additional resources used in the conversion process.  Allows
            preprocessors to pass variables into the Jinja engine.
        cell_index : int
            Index of the cell being processed (see base.py)
        """
        # Add a newline before each environment: this is a workaround
        # for a bug in mistune where
        # the environment contents will be converted from markdown
        # this has unwanted consequences for equations
        # ref: https://github.com/jupyter/nbconvert/issues/160
        if cell.cell_type == "markdown":
            cell.source = re.sub(r'\\\[([\s\S]*?)\\\]', r'$$\1$$', cell.source)
            cell.source = re.sub(r'\\\(([\s\S]*?)\\\)', r'$\1$', cell.source)
            cell.source = re.sub(r'\\begin{equation\*}([\s\S]*?)\\end{equation\*}', r'$$\1$$', cell.source)
            cell.source = re.sub(r'\\begin{(\w+)}([\s\S]*?)\\end{\1}',
                                 self.replacement, cell.source)
        return cell, resources


def include_latexdefs(name):
    '''This function is used to include latex user definitions
    in the html template, using the syntax
    {{ include_latexdefs('latexdefs.tex') }}
    This function is included in jinja2 environment'''
    text = ''
    try:
        with open(name) as f:
            for line in f:
                text += '$' + line[:-1] + '$\n'
    except:
        pass
    return text

def include_userenvs_cfg():
    '''This function is used to include the user environment configuration
    in the html template, using the syntax
    {{ include_userenvs_cfg() }}
    This function is included in jinja2 environment'''
    import jupyter_core, os
    datadir = jupyter_core.paths.jupyter_data_dir()
    user_envs_file = os.path.join(datadir, 'nbextensions', 'latex_envs', 'user_envs.json')
    text = ''
    try:
        f=open(user_envs_file,'rt')
        text=f.read();
    except:
        pass
    return text



class LenvsHTMLExporter(HTMLExporter):
    """
    Exports to an html document, embedding latex_env extension (.html)
    """

    def __init__(self, config=None, **kw):
        """
        Public constructor

        Parameters
        ----------
        config : :class:`~traitlets.config.Config`
            User configuration instance.
        `**kw`
            Additional keyword arguments passed to parent __init__

        """
        with_default_config = self.default_config
        if config:
            with_default_config.merge(config)

        super(HTMLExporter, self).__init__(
            config=with_default_config, **kw)
        self.register_preprocessor(LenvsHTMLPreprocessor(), enabled=True)

        self._init_preprocessors()

    def _file_extension_default(self):
        return '.html'

    def _template_file_default(self):
        return 'latex_envs'

    output_mimetype = 'text/html'

    def _raw_mimetypes_default(self):
        return ['text/markdown', 'text/html', '']


    @property
    def default_config(self):
        # import jupyter_core.paths
        # import os
        c = Config({
            'NbConvertBase': {
                'display_data_priority': ['application/javascript',
                                          'text/html',
                                          'text/markdown',
                                          'image/svg+xml',
                                          'text/latex',
                                          'image/png',
                                          'image/jpeg',
                                          'text/plain'
                                          ]
            },
            'CSSHTMLHeaderPreprocessor': {
                'enabled': True
            },
            'HighlightMagicsPreprocessor': {
                'enabled': True
            },
            'ExtractOutputPreprocessor': {'enabled': False},
            'latex_envs.LenvsHTMLPreprocessor': {'enabled': True}}
        )
        c.merge(super(LenvsHTMLExporter, self).default_config)
        if os.path.isdir(os.path.join(os.path.dirname(__file__), 'templates')):
            c.TemplateExporter.template_path = ['.',
                                                os.path.join(os.path.dirname(__file__), 'templates')]
        else:
            from jupyter_contrib_nbextensions.nbconvert_support import (
                templates_directory)
            c.TemplateExporter.template_path = ['.', templates_directory()]

        return c

    def from_notebook_node(self, nb, resources=None, **kw):
        langinfo = nb.metadata.get('language_info', {})
        lexer = langinfo.get('pygments_lexer', langinfo.get('name', None))
        self.register_filter('highlight_code',
                             Highlight2HTML(pygments_lexer=lexer,
                                            parent=self))
        self.environment.globals['include_latexdefs'] = include_latexdefs
        self.environment.globals['include_userenvs_cfg'] = include_userenvs_cfg
        lenvshtmlpreprocessor = LenvsHTMLPreprocessor()

        self.register_preprocessor(lenvshtmlpreprocessor, enabled=True)
        self._init_preprocessors()
        nb, resources = lenvshtmlpreprocessor(nb, resources)
        output, resources = super(LenvsHTMLExporter,
                                  self).from_notebook_node(
                                      nb, resources, **kw)
        # postout = postprocess(output)
        # print(postout[0:200]) #WORKS
        return output, resources


###################
class LenvsSlidesExporter(SlidesExporter):
    """
    Exports to a reveal-js/slides document, embedding latex_env extension (.html)
    """

    @property
    def default_config(self):
        # import jupyter_core.paths
        # import os
        c = Config({
            'NbConvertBase': {
                'display_data_priority': ['application/javascript',
                                          'text/html',
                                          'text/markdown',
                                          'image/svg+xml',
                                          'text/latex',
                                          'image/png',
                                          'image/jpeg',
                                          'text/plain'
                                          ]
            },
            'CSSHTMLHeaderPreprocessor': {
                'enabled': True
            },
            'HighlightMagicsPreprocessor': {
                'enabled': True
            },
            'ExtractOutputPreprocessor': {'enabled': False},
            'latex_envs.LenvsHTMLPreprocessor': {'enabled': True}}
        )
        c.merge(super(LenvsSlidesExporter, self).default_config)
        if os.path.isdir(os.path.join(os.path.dirname(__file__), 'templates')):
            c.TemplateExporter.template_path = ['.',
                                                os.path.join(os.path.dirname(__file__), 'templates')]
        else:
            from jupyter_contrib_nbextensions.nbconvert_support import (
                templates_directory)
            c.TemplateExporter.template_path = ['.', templates_directory()]

        return c

    def _template_file_default(self):
        return 'slides_latex_envs.tpl'

    def from_notebook_node(self, nb, resources=None, **kw):
        langinfo = nb.metadata.get('language_info', {})
        lexer = langinfo.get('pygments_lexer', langinfo.get('name', None))
        self.register_filter('highlight_code',
                             Highlight2HTML(pygments_lexer=lexer,
                                            parent=self))
        self.environment.globals['include_latexdefs'] = include_latexdefs
        self.environment.globals['include_userenvs_cfg'] = include_userenvs_cfg
        lenvshtmlpreprocessor = LenvsHTMLPreprocessor()

        self.register_preprocessor(lenvshtmlpreprocessor, enabled=True)
        self._init_preprocessors()
        nb, resources = lenvshtmlpreprocessor(nb, resources)
        output, resources = super(LenvsSlidesExporter,
                                  self).from_notebook_node(
                                      nb, resources, **kw)

        return output, resources

###################


class LenvsTocHTMLExporter(LenvsHTMLExporter):
    """
    Exports to a html document, embedding latex_env and toc extensions (.html)
    """

    def _template_file_default(self):
        return 'latex_envs_toc'


################

class LenvsLatexExporter(LatexExporter):
    """
    Exports to a LaTeX document
    """

    removeHeaders = Bool(
        False, help="Remove headers and footers").tag(config=True, alias="rh")
    figcaptionProcess = Bool(
        True, help="Process figcaptions").tag(config=True, alias="fc")
    tocrefRemove = Bool(
        True, help="Remove tocs and ref sections, + some cleaning").tag(
        config=True, alias="trr")
    flags = Dict(dict(enable=({'Bar': {'enabled': True}}, "Enable Bar")))

    def __init__(self, config=None, **kw):
        """
        Public constructor

        Parameters
        ----------
        config : :class:`~traitlets.config.Config`
            User configuration instance.
        `**kw`
            Additional keyword arguments passed to parent __init__

        """
        with_default_config = self.default_config
        if config:
            with_default_config.merge(config)

        super(Exporter, self).__init__(config=with_default_config, **kw)
        self.register_preprocessor(LenvsLatexPreprocessor(), enabled=True)

        self._init_preprocessors()

    def _file_extension_default(self):
        return '.tex'

    def _template_file_default(self):
        return 'thmsInNb_article'

    output_mimetype = 'text/tex'

    def _raw_mimetypes_default(self):
        return ['text/tex', 'text/txt', '']

    @property
    def default_config(self):
        # import jupyter_core.paths
        # import os
        c = Config({
            'NbConvertBase': {
                'display_data_priority': ['application/javascript',
                                          'text/html',
                                          'text/markdown',
                                          'image/svg+xml',
                                          'text/latex',
                                          'image/png',
                                          'image/jpeg',
                                          'text/plain'
                                          ]
            },
            'CSSHTMLHeaderPreprocessor': {
                'enabled': True},
            'HighlightMagicsPreprocessor': {
                'enabled': True},
            'ExtractOutputPreprocessor': {
                'enabled': True},
            'latex_envs.LenvsLatexPreprocessor': {'enabled': True}
        }
        )
        c.merge(super(LenvsLatexExporter, self).default_config)

        if os.path.isdir(os.path.join(os.path.dirname(__file__), 'templates')):
            c.TemplateExporter.template_path = ['.',
                                                os.path.join(os.path.dirname(__file__), 'templates')]
        else:
            from jupyter_contrib_nbextensions.nbconvert_support import (
                templates_directory)
            c.TemplateExporter.template_path = ['.', templates_directory()]
        return c

    def tocrefrm(self, text):
        # Remove Table of Contents section
        newtext = re.sub(r'(?:\\[sub]?section|\\chapter){Table of Contents}([\s\S]*?)(?=(?:\\[sub]?section|\\chapter))', '', text, flags=re.M)  # noqa
        # Remove References section
        newtext = re.sub(r'\\section{References}[\S\s]*?(?=(?:\\[sub]*section|\\chapter|\\end{document}|\Z))', '', newtext, flags=re.M)   # noqa
        # Cleaning
        newtext = re.sub('\\\\begin{verbatim}[\s]*?<matplotlib\.[\S ]*?>[\s]*?\\\\end{verbatim}', '', newtext, flags=re.M)  # noqa
        newtext = re.sub('\\\\begin{verbatim}[\s]*?<IPython\.core\.display[\S ]*?>[\s]*?\\\\end{verbatim}', '', newtext, flags=re.M)  # noqa
        # bottom page with links to Index/back/next (suppress this)
        # '----[\s]*?<div align=right> [Index](toc.ipynb)[\S ]*?.ipynb\)</div>'
        newtext = re.sub('\\\\begin{center}\\\\rule{[\S\s]*?\\\\end{center}[\s]*?\S*\href{toc.ipynb}{Index}[\S\s ]*?.ipynb}{Next}', '', newtext, flags=re.M)  # noqa
        return newtext


    def postprocess(self, nb_text):
        nb_text = nb_text.replace('!nl!', '\n')
        nb_text = nb_text.replace('!op!', '{')
        nb_text = nb_text.replace('!cl@', '}')
        nb_text = nb_text.replace('!cc!', '%')
        nb_text = nb_text.replace('!sl!', '\\')
        nb_text = nb_text.replace('!lb!', '[')
        nb_text = nb_text.replace('!rb!', ']')
        nb_text = nb_text.replace(r'//item', '\n\\item')
        nb_text = nb_text.replace('\\[', '\n\\[').replace('\\]', '\\]\n')
        nb_text = nb_text.replace(r'/item', r'\item')
        nb_text = nb_text.replace(r"{enum}", r"{enumerate}")

        if self.removeHeaders:
            tex_text = re.search('begin{document}([\s\S]*?)\\\\end{document}', nb_text, flags=re.M)  # noqa
            newtext = tex_text.group(1)
            newtext = newtext.replace('\\maketitle', '')
            newtext = newtext.replace('\\tableofcontents', '')
            nb_text = newtext
        if self.tocrefRemove:
            nb_text = self.tocrefrm(nb_text)
        return nb_text

    def from_notebook_node(self, nb, resources=None, **kw):
        langinfo = nb.metadata.get('language_info', {})
        lexer = langinfo.get('pygments_lexer', langinfo.get('name', None))
        self.register_filter('highlight_code',
                             Highlight2Latex(pygments_lexer=lexer,
                                             parent=self))
        lenvslatexpreprocessor = LenvsLatexPreprocessor()

        self.register_preprocessor(lenvslatexpreprocessor, enabled=True)
        self._init_preprocessors()
        nb, resources = lenvslatexpreprocessor(nb, resources)
        output, resources = super(LenvsLatexExporter, self).from_notebook_node(nb, resources, **kw)  # noqa
        postout = self.postprocess(output)
        #print(postout[0:200]) #WORKS

        return postout, resources

# jupyter nbconvert --to latex_envs.LenvsLatexExporter
# --LenvsLatexExporter.removeHeaders=True
# --LenvsLatexExporter.figcaptionProcess=True
# --LenvsLatexExporter.tocrefRemove=True test_theo.ipynb

# once entry point are installed
# jupyter nbconvert --to latex_lenvs --figcaptionProcess=true
# --removeHeaders=false test_theo

# jupyter nbconvert --to latex_envs.LenvsHTMLExporter test_theo.ipynb
