/*

*/

// Global variables ********************************************************************

var conversion_to_html = false;
var config_toolbar_present = false;
var reprocessEqs; 
//These variables are initialized in init_config()
var cite_by, bibliofile, eqNumInitial, eqNum, eqLabelWithNumbers, LaTeX_envs_menu_present, labels_anchors, latex_user_defs, user_envs_cfg;
var environmentMap = {};
var envsLatex = {};

if (typeof add_edit_shortcuts === "undefined")
    var add_edit_shortcuts = {}

var MathJaxDefined = !(typeof MathJax == "undefined")

// MathJax ******************************************************************************
// make sure that equations numbers are enabled
if (MathJaxDefined) {
    MathJax.Hub.Config({
        processSectionDelay: 0,
        TeX: {
            equationNumbers: {
                autoNumber: "AMS", // All AMS equations are numbered
                useLabelIds: true, // labels as ids
                // format the equation number - uses an offset eqNumInitial-1 (default 0) ie number from 1
                formatNumber: function(n) {
                    return String(Number(n) + Number(eqNumInitial) - 1) }
            }
        }
    });
   // MathJax.Hub.processSectionDelay = 0; //commented For Jupyter 5.0 ??
}

/* *************************************************************************************
 *    BIBLIOGRAPHY 
 ***************************************************************************************/
//var cite_by = 'apalike'  //cite by 'number', 'key' or 'apalike'
var current_citInitial = 1;
var current_cit = current_citInitial; // begins citation numbering at current_cit
//var bibliofile = 'biblio.bib' //or IPython.notebook.notebook_name.split(".")[0]+."bib"

//citations templates ...................

var etal = 3; //list of authors is completed by et al. if there is more than etal authors
var cit_tpl = {
        // feel free to add more types and customize the templates
        'INPROCEEDINGS': '%AUTHOR:InitialsGiven%, ``_%TITLE%_\'\', %BOOKTITLE%, %MONTH% %YEAR%.',
        'TECHREPORT': '%AUTHOR%, ``%TITLE%\'\', %INSTITUTION%, number: %NUMBER%,  %MONTH% %YEAR%.',
        'ARTICLE': '%AUTHOR:GivenFirst%, ``_%TITLE%_\'\', %JOURNAL%, vol. %VOLUME%, number %NUMBER%, pp. %PAGES%, %MONTH% %YEAR%.',
        'INBOOK': '%AUTHOR:Given%, ``_%TITLE%_\'\', in %BOOKTITLE%, %EDITION%, %PUBLISHER%, pp. %PAGES%, %MONTH% %YEAR%.',
        'UNKNOWN': '%AUTHOR:FirstGiven%, ``_%TITLE%_\'\', %MONTH% %YEAR%.'
    }
    /* The keys are the main types of documents, eg inproceedings, article, inbook, etc. To each key is associated a string where the %KEYWORDS% are the fields of the bibtex entry. The keywords are replaced by the correponding bibtex entry value. The template string can formatted with additional words and effects (markdown or LaTeX are commands are supported)

    Authors can be formatted according to the following keywords:
    - %AUTHOR:FirstGiven%, i.e. John Smith
    - %AUTHOR:GivenFirst%, i.e. Smith John
    - %AUTHOR:InitialsGiven%, i.e. J. Smith
    - %AUTHOR:GivenInitials%, i.e. Smith J.
    - %AUTHOR:Given%, i.e. Smith
    */

// *****************************************************************************

function insert_text(identifier) { //must be available in the main scope
    var deltaPos = [1, 0]
    var selected_cell = Jupyter.notebook.get_selected_cell();
    Jupyter.notebook.edit_mode();
    var cursorPos = selected_cell.code_mirror.getCursor()
    var selectedText = selected_cell.code_mirror.getSelection();
    selected_cell.code_mirror.replaceSelection(
        String($(identifier).data('text')), 'start');
    if (typeof $(identifier).data('position') !== "undefined") {
        var deltaPos = $(identifier).data('position').split(',').map(Number)
    }
    selected_cell.code_mirror.setCursor(cursorPos['line'] + deltaPos[0], deltaPos[1])
    var cursorPos = selected_cell.code_mirror.getCursor()    
    selected_cell.code_mirror.replaceRange(selectedText, cursorPos);    
}

// use AMD-style simplified define wrapper to avoid https://requirejs.org/docs/errors.html#notloaded
// `define(['notebook'], function(notebookApp) { var module =  notebookApp['base/js/utils']});`

define(function(require, exports, module) {
    var Jupyter = require('base/js/namespace');
    var MarkdownCell = require('notebook/js/textcell').MarkdownCell;
    var TextCell = require('notebook/js/textcell').TextCell;
    var mathjaxutils = require('notebook/js/mathjaxutils');
    var security = require("base/js/security");
    var configmod = require("services/config");
    var utils = require('base/js/utils');
    var marked = require('components/marked/lib/marked');
    // var completer = require('notebook/js/completer')
    var codemirror = require('codemirror/lib/codemirror');
    var showhint  = require("codemirror/addon/hint/show-hint")
    var anyword  = require("codemirror/addon/hint/anyword-hint")

    var thmsInNb = require('nbextensions/latex_envs/thmsInNb4');
    var bibsInNb = require('nbextensions/latex_envs/bibInNb4');
    //require('nbextensions/latex_envs/envsLatex');
    var initNb = require('nbextensions/latex_envs/initNb');

    cfg = Jupyter.notebook.metadata.latex_envs;

    var load_css = function(name) {
        var link = document.createElement("link");
        link.type = "text/css";
        link.rel = "stylesheet";
        link.href = require.toUrl(name);
        //link.href = name;
        document.getElementsByTagName("head")[0].appendChild(link);

    };


    function override_mdrenderer() {
        var _on_reload = true; /* make sure cells render on reload */

        /* Override original markdown render function to include latex_envs 
        processing */

        MarkdownCell.prototype.render = function(noevent) {
            if (typeof noevent === "undefined") noevent = false;
            var cont = TextCell.prototype.render.apply(this);
            if (cont || Jupyter.notebook.dirty || _on_reload) {
                var that = this;
                var text = this.get_text();
                // interpret \[..\] and \(\) as LaTeX
                text = text.replace(/\\\[([\s\S]*?)\\\]/gm, function(w, m1) {
                    return "$$" + m1 + "$$"
                })
                text = text.replace(/\\\(([\s\S]*?)\\\)/gm, function(w, m1) {
                    return "$" + m1 + "$"
                })
                var math = null;
                if (text === "") { text = this.placeholder; }
                var text_and_math = mathjaxutils.remove_math(text);
                text = text_and_math[0];
                math = text_and_math[1];
                marked(text, function(err, html) {
                    html = mathjaxutils.replace_math(html, math);
                    html = thmsInNbConv(marked, html); //<----- thmsInNb patch here
                    html = security.sanitize_html(html);
                    html = $($.parseHTML(html));
                    // add anchors to headings
                    html.find(":header").addBack(":header").each(function(i, h) {
                        h = $(h);
                        var hash = h.text().replace(/ /g, '-');
                        h.attr('id', hash);
                        h.append(
                            $('<a/>')
                            .addClass('anchor-link')
                            .attr('href', '#' + hash)
                            .text('¶')
                        );
                    });
                    // links in markdown cells should open in new tabs
                    html.find("a[href]").not('[href^="#"]').attr("target", "_blank");
                    that.set_rendered(html);
                    that.typeset();
                    if (!noevent)
                        that.events.trigger("rendered.MarkdownCell", { cell: that });
                });
            }
            return cont;
        };
        if (IPython.version[0] > '4') {
            // seems that the original prototype is copied to IPython.MarkdownCell
            // have to override it. 
            // TODO - define new prototype, including modifs in 5.x
            IPython.MarkdownCell.prototype.render = MarkdownCell.prototype.render;
        }


        MarkdownCell.prototype.handle_codemirror_keyevent = function(editor, event) {

            require('notebook/js/cell').Cell.prototype.handle_codemirror_keyevent.apply(this, [editor, event]);
            var cur = editor.getCursor();
            var inWord_re = /[%0-9a-z._/\\:~-]/i;


            if (editor.somethingSelected() || editor.getSelections().length > 1) return;
            var line = editor.getLine(cur.line);
            var pre_cursor = editor.getRange({
                line: cur.line,
                ch: cur.ch - 1
            }, cur);

            var tst = inWord_re.test(pre_cursor)

            var array_completion = ['$$', '()', '[]', '{}']
            var matches = array_completion.filter(function(elt) {
                return elt.startsWith(event.key)
            })
            if (cfg.autoclose) {
                if (matches.length == 1) {
                    event.codemirrorIgnore = true;
                    event.preventDefault();
                    editor.replaceRange(matches[0], cur);
                    editor.setCursor(cur.line, cur.ch + 1);
                    return true
                }
            }

            // if not a word character, then return immediately (type it in) 
            if (!/\w/.test(event.key) || event.key.length > 1) return false
            if (cfg.autocomplete) {
                var inchar = event.key.length == 1 ? event.key : ""
                var posx = cur.ch
                var ch = line[cur.ch]
                    // get the current word
                if (!editor.somethingSelected()) {
                    var re = /[\w]/
                    var cur = editor.getCursor(),
                        line = editor.getLine(cur.line),
                        start = cur.ch,
                        end = start;
                    while (start && re.test(line.charAt(start - 1))) {
                        --start;
                    }
                    while (end < line.length && re.test(line.charAt(end))) {
                        ++end;
                    }
                    if (start < end) {
                        var word_before = line.slice(start, posx) + inchar
                        var word_after = line.slice(posx, end)
                        var str = word_before + word_after
                    }
                    // if word starts with \, then autocomplete
                    if (line[start - 1] == "\\") {
                        // console.log("Completion in order");
                        var array_completion = ['text ', 'textit{}', 'textbf{}', 'texttt{}', 'emph{}',
                            'cite{}', 'ref{}', 'underline{}', 'title{}', 'begin{}', 'end{}', 'label{}'
                        ]
                        var matches = array_completion.filter(function(elt) {
                            return elt.startsWith(word_before)
                        })
                        if (matches.length > 0) {
                            event.codemirrorIgnore = true;
                            event.preventDefault();
                            editor.replaceRange(matches[0], { line: cur.line, ch: start }, { line: cur.line, ch: cur.ch });
                            editor.setCursor(cur.line, start + matches[0].length - 1);
                            return true
                        }
                    }
                }

            }
            return false;
        };
    }


function load_ipython_extension() {
    //var load_ipython_extension = require(['base/js/namespace'], function(Jupyter) {

    "use strict";
    if (Jupyter.version[0] < 3) {
        console.log("This extension requires Jupyter or IPython >= 3.x")
        return
    }

    var environmentMap = {};
    
    if (Jupyter.notebook._fully_loaded) {  
        // this tests if the notebook is fully loaded              
        var initcfg = init_config(Jupyter, utils, configmod, override_mdrenderer);
        cfg = Jupyter.notebook.metadata.latex_envs;
        console.log("Notebook fully loaded -- latex_envs initialized ")
    } else {
        $([Jupyter.events]).on("notebook_loaded.Notebook", function() {
            init_config(Jupyter, utils, configmod, override_mdrenderer);
            cfg = Jupyter.notebook.metadata.latex_envs;
            console.log("latex_envs initialized (via notebook_loaded)")
        })
    }


    // toolbar buttons
        var toolbarButtons = Jupyter.toolbar.add_buttons_group([

			Jupyter.keyboard_manager.actions.register ({
		        help: 'LaTeX_envs: Refresh rendering of labels, equations and citations',
		        icon: 'fa-refresh',
		        handler: init_cells
        }, 'init_cells', 'latex_envs'),

		Jupyter.keyboard_manager.actions.register ({
             help: 'Read bibliography and generate references section',
             icon: 'fa-book',
             handler: generateReferences
        }, 'generateReferences', 'latex_envs'),

		 Jupyter.keyboard_manager.actions.register ({
             	help: 'LaTeX_envs: Some configuration options (toogle toolbar)',
             	icon: 'fa-wrench',
            	handler: config_toolbar}, 'confToolbar', 'latex_envs')
		]);

	toolbarButtons.find('.btn').eq(0).attr('id', 'doReload');

    }  //end of load_ipython_extension function

    console.log("Loading latex_envs.css");
    load_css('./latex_envs.css')

    return {
        load_ipython_extension: load_ipython_extension,
    };
}); //End of main function 

console.log("Loading ./latex_envs.js");
