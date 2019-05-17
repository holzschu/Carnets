
// Initializations

function onMarkdownCellRendering(event, data) {
    // console.log("recomputing eqs")
    if (MathJaxDefined)  
        // see answer in https://groups.google.com/forum/#!topic/mathjax-users/7x-SzrezCaY       
        MathJax.Hub.Queue(
          function () {
            if (MathJax.InputJax.TeX.resetEquationNumbers) {
              MathJax.InputJax.TeX.resetEquationNumbers();
            }
          },
          ["PreProcess", MathJax.Hub], ["Reprocess", MathJax.Hub]
        );


    /*    MathJax.Hub.Queue(
        ["resetEquationNumbers", MathJax.InputJax.TeX], ["PreProcess", MathJax.Hub], ["Reprocess", MathJax.Hub]
    );*/
    $('.latex_label_anchor').toggle(labels_anchors);
    
    reset_counters();
    renumberAllEnvs();
};
//$('.latex_label_anchor').each(function(ind,elt){$(elt).css('visibility','show')})

function toggleLatexMenu() {
    if (!LaTeX_envs_menu_present) {
        $('#Latex_envs').remove();
        $('#toggleLatexMenu').css('color', 'grey')
            .attr('title', 'Insert LaTeX_envs menu');
    } else {
        create_latex_menu();
        $('#toggleLatexMenu').css('color', 'black')
            .attr('title', 'Remove LaTeX_envs menu');
    }
}

function toggleLabelsAnchors() {
    if (!labels_anchors) {
        $('#toggleLabelsAnchorsVisibility').css('color', 'grey')
            .attr('title', 'Show labels anchors');
    } else {
        $('#toggleLabelsAnchorsVisibility').css('color', 'black')
            .attr('title', 'Hide labels anchors');
    }
}

function loadLatexUserDefs() {
    $.get('latexdefs.tex').done(function(data) {
        data = data.replace(/^/gm, '\$\$\$').replace(/$/gm, '\$\$\$');
        if ($('#latexdefs').length > 0) $('#latexdefs').remove();
        $('body').append($('<div/>').attr('id', 'latexdefs').text(data));
        console.log('latex_envs: loaded user LaTeX definitions latexdefs.tex');
        onMarkdownCellRendering();
    }).fail(function() {
        console.log('latex_envs: failed to load user LaTeX definitions latexdefs.tex')
    });
}

function loadUserEnvsCfg(callback) {
        var baseUrl = require('base/js/utils').get_body_data("baseUrl")
        var jqxhr = $.getJSON( baseUrl + "nbextensions/latex_envs/user_envs.json", function(data) {
        //var jqxhr = $.getJSON( "example.json", function(data) { //in current directory
          environmentMap = $.extend(true,{}, environmentInitialMap,data) 
          //console.log( "success" );
        })
          .done(function() {
           // console.log( "second success" );
          })
          .fail(function(data) {
            environmentMap = $.extend(true, {}, environmentInitialMap) //deep copy
            console.log( "latex_envs: error loading /nbextensions/latex_envs/user_envs.json");
          })
          .always(function() {
            callback && callback();
            //console.log( "complete" );
          });
      }


function loadEnvsLaTeX(callback) {
    var baseUrl = require('base/js/utils').get_body_data("baseUrl")
    var jqxhr = $.getJSON(baseUrl + "nbextensions/latex_envs/envsLatex.json")
        .done(function(data) {
            envsLatex = $.extend(true, {}, data) //deep copy
            create_latex_menu(); // then create LaTeX menu
        })
        .fail(function(jqxhr, textStatus, error) {
            var err = textStatus + ", " + error;
            console.log("latex_envs: error loading /nbextensions/latex_envs/envsLatex.json");
            console.log("Request Failed: " + err);
        })
        .always(function() {
            callback && callback();
            //console.log( "complete" );
        });
}



var init_nb = function() {
    cit_table = {};
    readBibliography(function() {
        loadEnvsLaTeX();
        if (!LaTeX_envs_menu_present) toggleLatexMenu();
        if (latex_user_defs) loadLatexUserDefs();
        add_help_menu_item();
        init_cells(createReferenceSection);
    });
}


var init_cells = function(callback) {
    var ncells = Jupyter.notebook.ncells();
    var cells = Jupyter.notebook.get_cells();
    var MarkdownCell = require('notebook/js/textcell').MarkdownCell;

    eqNum = eqNumInitial;
    current_cit = current_citInitial;
    var noevent = true;
    var lastmd_cell;
    for (var i = 0; i < ncells; i++) {
        var cell = cells[i]; 
        // render visible markdown cells
        if (cell instanceof MarkdownCell && $(cell.element).is(":visible") ) {
            cell.render(noevent);
            lastmd_cell = cell;
        };
    }
    if(typeof lastmd_cell !== "undefined") lastmd_cell.render(); // re-render last md cell and issue rendered.MarkdownCell event
    onMarkdownCellRendering();
    //$('.latex_label_anchor').toggle(labels_anchors); 
    callback && callback();
}


// ** load configuration (1) default config, (2) system config (3) document config
// and save at document level
function init_config(Jupyter,utils,configmod, callback) {
    var cfg = { // default config
            //EQUATIONS
            'eqNumInitial': 1, // begins equation numbering at eqNum
            'eqLabelWithNumbers': true, //if true, label equations with equation numbers; otherwise using the tag specified by \label
            //BIBLIOGRAPHY
            'current_citInitial': 1, // begins citation numbering at current_cit
            'cite_by': 'apalike', //cite by 'number', 'key' or 'apalike' 
            'bibliofile': 'biblio.bib', //or IPython.notebook.notebook_name.split(".")[0]+."bib"
            // LaTeX_envs_menu 
            'LaTeX_envs_menu_present': true,
            // Show anchors for labels
            'labels_anchors': false,
            // Load LaTeX user definitions
            'latex_user_defs' : false,
            // Load user_envs configuration
            'user_envs_cfg' : false,
            // Use section numbers for numbering environments
            // ie Book/Report numbering style
            'report_style_numbering' : false,
            // Autoclose '$$', '()', '[]', '{}'
            'autoclose' : false,
            // Autocomplete LaTeX commands
            'autocomplete' : true,
            // Hotkeys -- more hotkeys can be added directly in envsLatex.json
            'hotkeys' : {
            'equation' : 'Ctrl-E',
            'itemize' : 'Ctrl-I'
            }
        }
    // create config object to load parameters
    var base_url = utils.get_body_data("baseUrl");
    var config = new configmod.ConfigSection('notebook', { base_url: base_url });
    config.loaded.then(function config_loaded_callback() {
        // config may be specified at system level or at document level.
        // first, update defaults with config loaded from server
        cfg = $.extend(true, cfg, config.data.latex_envs);
        // then update cfg with any found in current notebook metadata
        // and save in nb metadata (then can be modified per document)
        cfg = IPython.notebook.metadata.latex_envs = $.extend(true, cfg,
            IPython.notebook.metadata.latex_envs);
        // hotkeys taken from system
        if (config.data.latex_envs) {
            if (typeof config.data.latex_envs.hotkeys !== "undefined") {
               cfg.hotkeys = IPython.notebook.metadata.latex_envs.hotkeys = $.extend(true, {}, config.data.latex_envs.hotkeys);
            }
        }
        // update global variables
        cite_by = cfg.cite_by; //global
        bibliofile = cfg.bibliofile;
        eqNumInitial = cfg.eqNumInitial;
        eqLabelWithNumbers = cfg.eqLabelWithNumbers;
        eqNum = cfg.eqNumInitial;
        LaTeX_envs_menu_present = cfg.LaTeX_envs_menu_present;
        labels_anchors = cfg.labels_anchors; 
        latex_user_defs = cfg.latex_user_defs;
        user_envs_cfg = cfg.user_envs_cfg 
        report_style_numbering = cfg.report_style_numbering;
        reprocessEqs = true;
        // and initialize maps, bibliography and cells
        initmap();
        if (user_envs_cfg) {
            callback && callback();
            // reset eq numbers on each markdown cell modification
            $([Jupyter.events]).on("rendered.MarkdownCell", onMarkdownCellRendering);
            loadUserEnvsCfg(init_nb)
        } 
        else {
            environmentMap = $.extend(true, {}, environmentInitialMap) //deep copy
            callback && callback();
            // reset eq numbers on each markdown cell modification
            $([Jupyter.events]).on("rendered.MarkdownCell", onMarkdownCellRendering);
            init_nb()
        }
    })
    config.load();
}
//)

/** help menu **************************************************************/
    function add_help_menu_item() {

        if ($('#latex_envs_help').length > 0) {
            return;
        }
        var menu_item = $('<li/>')
            .insertAfter('#keyboard_shortcuts');
        var menu_link = $('<a/>')
            .text('LaTeX_envs help')
            .attr('title', 'LaTeX_envs documentation')
            .attr('id', "latex_envs_help")
            .attr('href', '/nbextensions/latex_envs/doc/latex_env_doc.html')
            .attr('target', "_blank")
            .appendTo(menu_item);
        $('<i/>')
            .addClass('fa fa-external-link menu-icon pull-right')
            .prependTo(menu_link);
    }


/** LaTeX_envs menu *********************************************************
* Series of sortcuts to environments in latex_envs
****************************************************************************/

function create_latex_menu(callback) {

    if ($('#Latex_envs').length > 0) {
        return;
    }

    cfg = Jupyter.notebook.metadata.latex_envs
    $('#help_menu').parent().before('<li id="Latex_envs"/>')
    $('#Latex_envs').addClass('dropdown')
            .append($('<a/>').attr('href', '#')
            .attr('id', 'latex_envs')
            .addClass('dropdown-toogle')
            .attr('data-toggle', "dropdown")
            .attr('aria-expanded', "false")
            .text("LaTeX_envs"))
            .append($('<ul/>')
            .attr('id', 'latex_envs_menu')
            .addClass('dropdown-menu'))

    //for (var i = 0; i < Object.keys(envsLatex).length; i++) {
    for (var p in envsLatex) {
        var current_env_name = envsLatex[p]['name']
        var current_hint = envsLatex[p]['hint']
        var current_env = envsLatex[p]['env']
        var current_shortcut = cfg['hotkeys'][current_env_name] != undefined ? cfg['hotkeys'][current_env_name] : envsLatex[p]['shortcut']
        var current_id = "env_" + p
        current_env_name = current_shortcut == "" ? current_env_name : current_env_name + '  (' + current_shortcut + ')'

        var menu_item = $('<li/>').appendTo('#latex_envs_menu')
            .attr('id', 'zozo').attr('title', "titre")

        var menu_link = $('<a/>')
            .text(current_env_name)
            .attr('href', '#')
            .attr('title', current_hint)
            .attr('id', current_id)
            .attr('data-text', current_env)
            .attr('onclick', 'insert_text(this);')
            .appendTo(menu_item);

        if (typeof envsLatex[p]['position'] !== "undefined") {
            menu_link.attr('data-position', envsLatex[p]['position'])
        }

        if (current_shortcut !== "") {
            add_edit_shortcuts[current_shortcut] = {
                help: current_hint,
                help_index: 'ht',
                handler: Function('insert_text($(' + '"#' + current_id + '"))')
            }
        }
    }
    callback && callback();
    Jupyter.keyboard_manager.edit_shortcuts.add_shortcuts(add_edit_shortcuts);
}

/********************************************************************************************
* Definition of a toolbar that enable to select several options:
*		- equations numbered or labelled
* 		- value of initial counter for equations
*		- style of citations call: by number, eg [1,2], by key, eg [perez2001,buss2012], or apalike
* 			eg (Perez et al., 1988)
*		- name of biblio file (if applicable)
*
*********************************************************************************************/
function config_toolbar(callback) {

    if (config_toolbar_present) {
        config_toolbar_present = false;
        $("#LaTeX_envs_toolbar").remove();
        $(site).height($(window).height() - $('#header').height() - $('#footer').height());
        return
    } else {
        config_toolbar_present = true;
    }
    cfg = Jupyter.notebook.metadata.latex_envs

    //local to this function
    var cite_by_icon = { 'number': 'fa-sort-numeric-asc', 'key': 'fa-key', 'apalike': 'fa-pencil-square-o' }
    var cite_by_tmp = cite_by
    var eqLabel_tmp = eqLabelWithNumbers
    var eq_by_icon = { true: 'fa-sort-numeric-asc', false: 'fa-tag' }

    var eqNumtmp = eqNumInitial;

    // Defining the toolbar --------------------------------------------------------------
    var LaTeX_envs_toolbar = $('<div id="LaTeX_envs_toolbar" class="container edit_mode" >')

    var vertical_separator = '&nbsp;&nbsp;<span style="display: inline-block; \
vertical-align:bottom; width: 0; height: 1.8em;border-left:2px solid #cccccc"></span>&nbsp;&nbsp;'

    var biblioLabel = $('<b/>').html('Bibliography&nbsp;')
    var equationLabel = $('<b/>').html('Equations&nbsp;')

    var LaTeX_envs_help_link = $('<a/>').html('LaTeX_envs&nbsp;')
        .css({
            textDecoration: 'none',
            'font-weight': "bold",
            color: 'black'
        })
        .attr('href', '/nbextensions/latex_envs/doc/latex_env_doc.html')
        .attr('target', "_blank")
        .attr('title', 'LaTeX_envs documentation')

    // input bibliography BibTeX filename
    var input_bibFilename = $('<input/>')
        .attr('type', "text")
        .attr('value', bibliofile)
        .attr('id', "biblio")
        .attr('size', '15')
        .attr('title','Enter BibTeX biblio filename (must be present in current directory)')
        .addClass("edit_mode input-xs")
        .css("vertical-align", "middle")

    // input equations numbering offset
    var input_eqNumInitial = $('<input/>')
        .attr('type', "text")
        .attr('value', eqNumtmp)
        .attr('id', "eqnum")
        .attr('title','Equations numbering begins at...')
        .attr('size', '3')
        .addClass("edit_mode")
        .css("vertical-align", "middle")
        .css("text-align", "right")

    // dropdown menu for selecting the citation style
    var bibStyleMenu = $('<div/>').attr('id', 'citeby').addClass('btn-group')
        .attr('title', 'Select references style: numbered, by key, or apa-like')
        .append($('<a/>')
            .addClass("btn btn-default")
            .append($('<i/>')
                .attr('id', "menu-refs").addClass("fa " + cite_by_icon[cite_by_tmp] + " fa-fw"))
            .append('References')
        )
        .append($('<a/>')
            .addClass("btn btn-default dropdown-toggle")
            .attr('data-toggle', "dropdown")
            .attr('href', "#")
            .append($('<span/>').addClass("fa fa-caret-down")))
        .append($('<ul/>').attr('id', 'choice').addClass("dropdown-menu")
            .append($('<li/>')
                .append($('<a/>')
                    .append($('<i/>').addClass("fa fa-sort-numeric-asc fa-fw"))
                    .append('Numbered')
                ))
            .append($('<li/>')
                .append($('<a/>')
                    .append($('<i/>').addClass("fa fa-key fa-fw"))
                    .append('Key')
                )
            )
            .append($('<li/>')
                .append($('<a/>')
                    .append($('<i/>').addClass("fa fa-pencil-square-o fa-fw"))
                    .append('Apa-like')
                )
            )
        )

    // dropdown menu for selecting the numbering style
    var eqLabelStyle = $('<div/>').attr('id', 'eqby').addClass('btn-group')
        .attr('title','Select equations referencing: by number or by label')
        .append($('<a/>')
            .addClass("btn btn-default")
            .append($('<i/>')
                .attr('id', "menu-eqs").addClass("fa " + eq_by_icon[eqLabelWithNumbers] + " fa-fw"))
            .append('Equations')
        )
        .append($('<a/>')
            .addClass("btn btn-default dropdown-toggle")
            .attr('data-toggle', "dropdown")
            .attr('href', "#")
            .append($('<span/>').addClass("fa fa-caret-down")))
        .append($('<ul/>').attr('id', 'choice').addClass("dropdown-menu")
            .append($('<li/>')
                .append($('<a/>')
                    .append($('<i/>').addClass("fa fa-sort-numeric-asc fa-fw"))
                    .append('Numbered')
                ))
            .append($('<li/>')
                .append($('<a/>')
                    .append($('<i/>').addClass("fa fa-tag  fa-fw"))
                    .append('Label')
                )
            )
        )

    // dropdown menu for parameter selection and toggle


    var configMenu = $('<div/>').attr('id', 'cfgby').addClass('btn-group')
        .attr('title', 'Select/Toogle parameters')
        .append($('<a/>')
            .addClass("btn btn-default")
            .append($('<i/>')
                .attr('id', "menu-config").addClass("fa fa-wrench fa-fw"))
            .append('Toggles')
        )
        .append($('<a/>')
            .addClass("btn btn-default dropdown-toggle")
            .attr('data-toggle', "dropdown")
            .attr('href', "#")
            .append($('<span/>').addClass("fa fa-caret-down")))
        .append($('<ul/>').attr('id', 'choice').addClass("dropdown-menu")        
        .attr('min-width', '300px')
            .append($('<li/>') 
                .append($('<a/>')
                    .attr('id','latex_envs_Menu')
                    .text('Show LaTeX menu')
                    .css('width', '200px')
                    .attr('href', '#')
                    .attr('title', 'Toogle visibility of LaTeX_envs menu')
                    .on('click',function (){
                        cfg.LaTeX_envs_menu_present = LaTeX_envs_menu_present = !LaTeX_envs_menu_present
                        $('#latex_envs_Menu > .fa').toggleClass('fa-check', LaTeX_envs_menu_present);
                        toggleLatexMenu();
                    })
                    .prepend($('<i/>').addClass('fa menu-icon pull-right'))
                )
            )
            .append($('<li/>')
                .append($('<a/>')
                    .attr('id','labels_anchors_menu')
                    .text('Show Labels anchors')
                    .attr('href', '#')
                    .attr('title', 'Toogle visibility of labels anchors')
                    .on('click',function (){
                        cfg.labels_anchors = labels_anchors = !labels_anchors
                        $('#labels_anchors_menu > .fa').toggleClass('fa-check', labels_anchors);
                        $('.latex_label_anchor').toggle(labels_anchors);
                        toggleLabelsAnchors();
                    })
                    .prepend($('<i/>').addClass('fa menu-icon pull-right'))
                )
            )
            .append($('<li/>')
                .append($('<a/>')
                    .attr('id','latex_user_defs')
                    .text('LaTeX user definitions')
                    .attr('href', '#')
                    .attr('title', 'Load LaTeX user definitions (file latexdefs.tex)')
                    .on('click',function (){
                        cfg.latex_user_defs = latex_user_defs = !latex_user_defs
                        $('#latex_user_defs > .fa').toggleClass('fa-check', latex_user_defs);
                        if (latex_user_defs) {
                            loadLatexUserDefs();
                            setTimeout(function(){ //there is a race condition somewhere
                                init_cells(); 
                                onMarkdownCellRendering();},1000);                            
                        }
                    })
                    .prepend($('<i/>').addClass('fa menu-icon pull-right'))
                )
            )
            .append($('<li/>')
                .append($('<a/>')
                    .attr('id','user_envs_cfg')
                    .text('User envs config')
                    .attr('href', '#')
                    .attr('title', 'Load user envs configuration (file user_envs.json)')
                    .on('click',function (){
                        cfg.user_envs_cfg = user_envs_cfg = !user_envs_cfg
                        $('#user_envs_cfg > .fa').toggleClass('fa-check', user_envs_cfg);
                        if (user_envs_cfg) {
                            loadUserEnvsCfg(init_cells);
                        }
                        else{
                            environmentMap = $.extend(true, {}, environmentInitialMap) //deep copy
                            init_cells();
                        }
                    })
                    .prepend($('<i/>').addClass('fa menu-icon pull-right'))
                )
            )
            .append($('<li/>')
                .append($('<a/>')
                    .attr('id','report_style_numbering')
                    .text('Report style numbering')
                    .attr('href', '#')
                    .attr('title', 'Book/Report style numbering (use section numbers for numbering environments)')
                    .on('click',function (){
                        cfg.report_style_numbering = report_style_numbering = !report_style_numbering
                        $('#report_style_numbering > .fa').toggleClass('fa-check', report_style_numbering);
                        onMarkdownCellRendering();                           
                    })
                    .prepend($('<i/>').addClass('fa menu-icon pull-right'))
                )
            )   
            .append($('<li/>')
                .append($('<a/>')
                    .attr('id','autoclose')
                    .text('Autoclose $,(,{,[')
                    .attr('href', '#')
                    .attr('title', 'Autoclose $,(,{,[ while typing')
                    .on('click',function (){
                        cfg.autoclose = !cfg.autoclose
                        $('#autoclose > .fa').toggleClass('fa-check', cfg.autoclose);
                    })
                    .prepend($('<i/>').addClass('fa menu-icon pull-right'))
                )
            )         
            .append($('<li/>')
                .append($('<a/>')
                    .attr('id','autocomplete')
                    .text('Autocomplete')
                    .attr('href', '#')
                    .attr('title', 'Autocomplete LaTeX commands while typing')
                    .on('click',function (){
                        cfg.autocomplete = !cfg.autocomplete
                        $('#autocomplete > .fa').toggleClass('fa-check', cfg.autocomplete);
                    })
                    .prepend($('<i/>').addClass('fa menu-icon pull-right'))
                )
            )
        )





    // toggle the latex_envs dropdown menu
    var latex_envs_menu_button = $("<a/>")
        .addClass("btn btn-default")
        .attr('href', "#")
        .attr('title', 'Toogle LaTeX_envs menu')
        .css('color', 'black')
        .attr('id', 'toggleLatexMenu')
        .append($("<i/>").addClass('fa fa-caret-square-o-down'))


    // toggle the latex_envs dropdown menu
    var labels_anchors_toggle_button = $("<a/>")
        .addClass("btn btn-default")
        .attr('href', "#")
        .attr('title', 'Toogle Labels anchors')
        .css('color', 'black')
        .attr('id', 'toggleLabelsAnchorsVisibility')
        .append($("<i/>").addClass('fa fa-bullseye'))
    
    // close button
    var suicide_button = $("<a/>")
        .addClass("btn btn-default")
        .attr('href', "#")
        .attr('title', 'Close LaTeX_envs toolbar')
        .css('float', 'right')
        .attr('id', 'suicide')
        .attr('title', 'Close the LaTeX-envs configuration toolbar')
        .append($("<i/>").addClass('fa fa-power-off'))
        .on('click', function() {
            config_toolbar_present = false;
            $("#LaTeX_envs_toolbar").remove();
            $(site).height($(window).height() - $('#header').height() - $('#footer').height())
            return
        })


    // Finally the toolbar itself
    LaTeX_envs_toolbar.append(LaTeX_envs_help_link)
        .append(vertical_separator)
        .append(biblioLabel)
        .append(input_bibFilename)
        .append(bibStyleMenu)
        .append(vertical_separator)
        .append(equationLabel)
        .append(input_eqNumInitial)
        .append(eqLabelStyle)
        .append(vertical_separator)
        .append(latex_envs_menu_button)
        .append(labels_anchors_toggle_button)
        .append(configMenu)
        .append(suicide_button)

    // Appending the new toolbar to the main one
    $('head').append('<style> input:focus {border-color: #66afe9;\
outline: 0; box-shadow: inset 0 1px 1px rgba(0,0,0,.075), 0 0 8px \
rgba(102, 175, 233, 0.6);}</style>')

    $("#maintoolbar-container").append(LaTeX_envs_toolbar);
    $("#LaTeX_envs_toolbar").css({ 'padding': '5px' });

    // Initializing toogles checks
    $('#labels_anchors_menu > .fa').toggleClass('fa-check', labels_anchors)
    toggleLabelsAnchors();
    $('#latex_envs_Menu > .fa').toggleClass('fa-check', LaTeX_envs_menu_present);
    $('#user_envs_cfg> .fa').toggleClass('fa-check', user_envs_cfg);
    $('#latex_user_defs > .fa').toggleClass('fa-check', latex_user_defs);
    $('#report_style_numbering > .fa').toggleClass('fa-check', report_style_numbering);
    $('#autoclose > .fa').toggleClass('fa-check', cfg.autoclose);
    $('#autocomplete > .fa').toggleClass('fa-check', cfg.autocomplete);
    
    // Now the callback functions --------------------------------------------  

    $('#toggleLabelsAnchorsVisibility').on('click', function() {
        cfg.labels_anchors = labels_anchors = !labels_anchors
        $('#labels_anchors_menu > .fa').toggleClass('fa-check', labels_anchors);
        $('.latex_label_anchor').toggle(labels_anchors)
        toggleLabelsAnchors();
    })

    $('#toggleLatexMenu').on('click', function() {
        cfg.LaTeX_envs_menu_present = LaTeX_envs_menu_present = !LaTeX_envs_menu_present
        $('#latex_envs_Menu > .fa').toggleClass('fa-check', LaTeX_envs_menu_present);
        toggleLatexMenu();
    })

    $('#citeby').on('click', '.dropdown-menu li a', function() {
        var tmp_text = $(this).text().trim().toLowerCase()
        switch (tmp_text) {
            case 'numbered':
                cite_by_tmp = 'number';
                break;
            case 'key':
                cite_by_tmp = 'key';
                break;
            case 'apa-like':
                cite_by_tmp = 'apalike';
                break;
            default:
                cite_by_tmp = 'apalike';
        }
        $('#menu-refs').removeClass().addClass("fa " + cite_by_icon[cite_by_tmp] + " fa-fw");
        cfg.cite_by = cite_by_tmp //Jupyter.notebook.metadata.latex_envs.cite_by 
        cite_by = cite_by_tmp //Jupyter.notebook.metadata.latex_envs.cite_by 
        init_nb();
    })


    var kmMode = "command";
    $('#biblio').on('focus', function() {
            kmMode = Jupyter.keyboard_manager.mode;
            Jupyter.keyboard_manager.mode = "edit";
        })
        .on('blur', function() { Jupyter.keyboard_manager.mode = kmMode })
        .on('keypress', function(e) {
            if (e.keyCode == 13) {
                $('#biblio').blur();
                cfg.bibliofile = $("#biblio")[0].value;
                bibliofile = $("#biblio")[0].value;
                init_nb();
            }
        })        

    $('#eqby').on('click', '.dropdown-menu li a', function() {
            //console.log($(this).text());
            var tmp_text = $(this).text().trim().toLowerCase()
            switch (tmp_text) {
                case 'numbered':
                    {
                        eqLabel_tmp = true;
                        if (MathJaxDefined) MathJax.Hub.Config({
                            TeX: {
                                equationNumbers: {
                                    autoNumber: "AMS",
                                    useLabelIds: true
                                }
                            }
                        });
                    }
                    break;
                case 'label':
                    {
                        eqLabel_tmp = false;
                        if (MathJaxDefined) MathJax.Hub.Config({
                            TeX: {
                                equationNumbers: {
                                    autoNumber: "none",
                                    useLabelIds: true
                                }
                            }
                        });
                    }
                    break;
                default:
                    {
                        eqLabel_tmp = true;
                        if (MathJaxDefined) MathJax.Hub.Config({
                            TeX: {
                                equationNumbers: {
                                    autoNumber: "AMS",
                                    useLabelIds: true
                                }
                            }
                        });
                    }
            }
            $('#menu-eqs').removeClass().addClass("fa " + eq_by_icon[eqLabel_tmp] + " fa-fw");
            cfg.eqLabelWithNumbers = eqLabel_tmp; //Jupyter.notebook.metadata.latex_envs.eqLabelWithNumbers
            eqLabelWithNumbers = eqLabel_tmp;
            init_cells();
        })


    $('#eqnum').on('focus', function() {
            kmMode = Jupyter.keyboard_manager.mode;
            Jupyter.keyboard_manager.mode = "edit";
        })
        .on('blur', function() { Jupyter.keyboard_manager.mode = kmMode })
        .on('keypress', function(e) {
            if (e.keyCode == 13) {
                $('#eqnum').blur();
                cfg.eqNumInitial = Number($('#eqnum')[0].value); //Jupyter.notebook.metadata.latex_envs.eqNumInitial 
                eqNumInitial = Number($('#eqnum')[0].value);
                init_cells();
            }
        })

    $('#apply').on('click', function() {
            //
            //set the values of global variables
            cite_by = cite_by_tmp //Jupyter.notebook.metadata.latex_envs.cite_by 
            bibliofile = $("#biblio")[0].value //Jupyter.notebook.metadata.latex_envs.bibliofile 
            eqNumInitial = Number($('#eqnum')[0].value)  //Jupyter.notebook.metadata.latex_envs.eqNumInitial
            eqLabelWithNumbers = eqLabel_tmp //Jupyter.notebook.metadata.latex_envs.eqLabelWithNumbers
                //save into notebook's metadata 
            cfg = Jupyter.notebook.metadata.latex_envs
            cfg.cite_by = cite_by_tmp //Jupyter.notebook.metadata.latex_envs.cite_by 
            cfg.bibliofile = $("#biblio")[0].value //Jupyter.notebook.metadata.latex_envs.bibliofile 
            cfg.eqNumInitial = Number($('#eqnum')[0].value) //Jupyter.notebook.metadata.latex_envs.eqNumInitial
            cfg.eqLabelWithNumbers = eqLabel_tmp //Jupyter.notebook.metadata.latex_envs.eqLabelWithNumbers
                //apply all this
            readBibliography(function() {
                init_cells();
                createReferenceSection();
            });

        })
        .tooltip({ title: 'Apply the selected values', trigger: "hover", delay: { show: 500, hide: 50 } });

}
