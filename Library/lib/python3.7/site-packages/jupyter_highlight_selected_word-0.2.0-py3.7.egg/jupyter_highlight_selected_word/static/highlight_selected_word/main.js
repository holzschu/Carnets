/**
 * Enable highlighting of matching words in cells' CodeMirror editors.
 *
 * This extension was adapted from the CodeMirror addon
 * codemirror/addon/search/match-highlighter.js
 */

define([
	'require',
	'jquery',
	'base/js/namespace',
	'notebook/js/cell',
	'notebook/js/codecell',
	'codemirror/lib/codemirror',
	// The mark-selection addon is need to ensure that the highlighting styles
	// are *not* applied to the actual selection, as otherwise it can become
	// difficult to see which is selected vs just highlighted.
	'codemirror/addon/selection/mark-selection'
], function (
	requirejs,
	$,
	Jupyter,
	cell,
	codecell,
	CodeMirror
) {
	'use strict';

	var Cell = cell.Cell;
	var CodeCell = codecell.CodeCell;

	var mod_name = 'highlight_selected_word';
	var log_prefix = '[' + mod_name + ']';
	var menu_toggle_class = 'highlight_selected_word_toggle';

	// Parameters (potentially) stored in server config.
	// This object gets updated on config load.
	var params = {
		highlight_across_all_cells: true,
		enable_on_load : true,
		code_cells_only: false,
		delay: 100,
		words_only: false,
		highlight_only_whole_words: true,
		min_chars: 2,
		show_token: '[\\w$]',
		highlight_color: '#90EE90',
		highlight_color_blurred: '#BBFFBB',
		highlight_style: 'matchhighlight',
		trim: true,
		use_toggle_hotkey: false,
		toggle_hotkey: 'alt-h',
		outlines_only: false,
		outline_width: 2,
		only_cells_in_scroll: true,
		scroll_min_delay: 100,
		hide_selections_in_unfocussed: false,
	};

	// these are set on registering the action(s)
	var action_names = {
		toggle: '',
	};

	/**
	 *  the codemirror matchHighlighter has a separate state object for each cm
	 *  instance, but since our state is global over all cells' editors, we can
	 *  use a single object for simplicity, and don't need to store options
	 *  inside the state, since we have closure-level access to the params
	 *  object above.
	 */
	var globalState = {
		active: false,
		timeout: null, // only want one timeout
		scrollTimeout: null,
		overlay: null, // one overlay suffices, as all cells use the same one
	};

	// define a CodeMirror option for highlighting matches in all cells
	CodeMirror.defineOption("highlightSelectionMatchesInJupyterCells", false, function (cm, val, old) {
		if (old && old != CodeMirror.Init) {
			globalState.active = false;
			// remove from all relevant, this can fail gracefully if not present
			get_relevant_cells().forEach(function (cell, idx, array) {
				cell.code_mirror.removeOverlay(mod_name);
			});
			globalState.overlay = null;
			clearTimeout(globalState.timeout);
			globalState.timeout = null;
			cm.off("cursorActivity", callbackCursorActivity);
			cm.off("focus", callbackOnFocus);
		}
		if (val) {
			if (cm.hasFocus()) {
				globalState.active = true;
				highlightMatchesInAllRelevantCells(cm);
			}
			else {
				cm.on("focus", callbackOnFocus);
			}
			cm.on("cursorActivity", callbackCursorActivity);
		}
	});

	/**
	 *  The functions callbackCursorActivity, callbackOnFocus and
	 *  scheduleHighlight are taken without major modification from cm's
	 *  match-highlighter.
	 *  The main difference is using our global state rather than
	 *  match-highlighter's per-cm state, and a different highlighting function
	 *  is scheduled.
	 */
	function callbackCursorActivity (cm) {
		if (globalState.active || cm.hasFocus()) {
			scheduleHighlight(cm);
		}
	}

	function callbackOnFocus (cm) {
		// unlike cm match-highlighter, we *do* want to schedule a highight on
		// focussing the editor
		globalState.active = true;
		scheduleHighlight(cm);
	}

	function scheduleHighlight (cm) {
		clearTimeout(globalState.timeout);
		globalState.timeout = setTimeout(function () { highlightMatchesInAllRelevantCells(cm); }, params.delay);
	}

	/**
	 *  Adapted from cm match-highlighter's highlightMatches, but adapted to
	 *  use our global state and parameters, plus work either for only the
	 *  current editor, or multiple cells' editors.
	 */
	function highlightMatchesInAllRelevantCells (cm) {
		var newOverlay = null;

		var re = params.show_token === true ? /[\w$]/ : params.show_token;
		var from = cm.getCursor('from');
		if (!cm.somethingSelected() && params.show_token) {
			var line = cm.getLine(from.line), start = from.ch, end = start;
			while (start && re.test(line.charAt(start - 1))) {
				--start;
			}
			while (end < line.length && re.test(line.charAt(end))) {
				++end;
			}
			if (start < end) {
				newOverlay = makeOverlay(line.slice(start, end), re, params.highlight_style);
			}
		}
		else {
			var to = cm.getCursor("to");
			if (from.line == to.line) {
				if (!params.words_only || isWord(cm, from, to)) {
					var selection = cm.getRange(from, to);
					if (params.trim) {
						selection = selection.replace(/^\s+|\s+$/g, "");
					}
					if (selection.length >= params.min_chars) {
						var hasBoundary = params.highlight_only_whole_words ? (re instanceof RegExp ? re : /[\w$]/) : false;
						newOverlay = makeOverlay(selection, hasBoundary, params.highlight_style);
					}
				}
			}
		}

		var siterect = document.getElementById('site').getBoundingClientRect();
		var viewtop = siterect.top, viewbot = siterect.bottom;
		var cells = params.highlight_across_all_cells ? get_relevant_cells() : [
			$(cm.getWrapperElement()).closest('.cell').data('cell')
		];
		cells.forEach(function (cell, idx, array) {
			// cm.operation to delay updating DOM until all work is done
			cell.code_mirror.operation(function () {
				cell.code_mirror.removeOverlay(mod_name);
				if (newOverlay && is_in_view(cell.element[0], viewtop, viewbot)) {
					cell.code_mirror.addOverlay(newOverlay);
				}
			});
		});
	}

	/**
	 *  isWord, boundariesAround and makeOverlay come pretty much directly from
	 *  Codemirror/addon/search/matchHighlighter
	 *  since they don't use state or config values.
	 */
	function isWord (cm, from, to) {
		var str = cm.getRange(from, to);
		if (str.match(/^\w+$/) !== null) {
			var pos, chr;
			if (from.ch > 0) {
				pos = {line: from.line, ch: from.ch - 1};
				chr = cm.getRange(pos, from);
				if (chr.match(/\W/) === null) {
					return false;
				}
			}
			if (to.ch < cm.getLine(from.line).length) {
				pos = {line: to.line, ch: to.ch + 1};
				chr = cm.getRange(to, pos);
				if (chr.match(/\W/) === null) {
					return false;
				}
			}
			return true;
		}
		return false;
	}
	function boundariesAround (stream, re) {
		return (!stream.start || !re.test(stream.string.charAt(stream.start - 1))) &&
		  (stream.pos == stream.string.length || !re.test(stream.string.charAt(stream.pos)));
	}
	function makeOverlay (query, hasBoundary, style) {
		return {
			name: mod_name,
			token: function (stream) {
				if (stream.match(query) &&
						(!hasBoundary || boundariesAround(stream, hasBoundary))) {
					return style;
				}
				stream.next();
				if (!stream.skipTo(query.charAt(0))) {
					stream.skipToEnd();
				}
			}
		};
	}

	/**
	 * Returns true if part of elem is visible between viewtop & viewbot
	 */
	var is_in_view  = function (elem, viewtop, viewbot) {
		var rect = elem.getBoundingClientRect();
		// hidden elements show height 0
		return (rect.top < viewbot) && (rect.bottom > viewtop) && rect.height;
	}

	/**
	 *  Return an array of cells to which match highlighting is relevant,
	 *  dependent on the code_cells_only parameter
	 */
	function get_relevant_cells () {
		var cells = Jupyter.notebook.get_cells();
		return params.code_cells_only ? cells.filter(function (c) { return (c instanceof CodeCell); }) : cells;
	}

	function add_menu_item () {
		if ($('#view_menu').find('.' + menu_toggle_class).length < 1) {
			var menu_item = $('<li/>')
				.appendTo('#view_menu');
			var menu_link = $('<a/>')
				.text('Highlight selected word')
				.addClass(menu_toggle_class)
				.attr({
					title: 'Highlight all instances of the selected word in the current editor',
					href: '#',
				})
				.on('click', function () { toggle_highlight_selected(); })
				.appendTo(menu_item);
			$('<i/>')
				.addClass('fa menu-icon pull-right')
				.css({'margin-top': '-2px', 'margin-right': '-16px'})
				.prependTo(menu_link);
		}
	}

	var throttled_highlight = (function () {
		var last, throttle_timeout;
		return function throttled_highlight (cm) {
			var now = Number(new Date());
			var do_it = function () {
				last = Number(new Date());
				highlightMatchesInAllRelevantCells(cm);
			};
			var remaining = last + params.scroll_min_delay - now;
			if (last && remaining > 0) {
				clearTimeout(throttle_timeout);
				throttle_timeout = setTimeout(do_it, remaining);
			}
			else {
				last = undefined; // so we will do it first time next streak
				do_it();
			}
		}
	})();

	function scroll_handler (evt) {
		if (globalState.active && Jupyter.notebook.mode === 'edit' && globalState.overlay) {
			// add overlay to cells now in view which don't already have it.
			// Don't bother removing from those no longer in view, as it would just
			// cause more work for the browser, without any benefit
			var siterect = document.getElementById('site').getBoundingClientRect();
			get_relevant_cells().forEach(function (cell) {
				var cm = cell.code_mirror;
				if (is_in_view(cell.element, siterect.top, siterect.bot)) {
					var need_it = !cm.state.overlays.some(function(ovr) {
						return ovr.modeSpec.name === mod_name; });
					if (need_it) cm.addOverlay(globalState.overlay);
				}
			});
		}
	}

	function toggle_highlight_selected (set_on) {
		set_on = (set_on !== undefined) ? set_on : !params.enable_on_load;
		// update config to make changes persistent
		if (set_on !== params.enable_on_load) {
			params.enable_on_load = set_on;
			Jupyter.notebook.config.update({highlight_selected_word: {enable_on_load: set_on}});
		}

		// Change defaults for new cells:
		var cm_conf = (params.code_cells_only ? CodeCell : Cell).options_default.cm_config;
		cm_conf.highlightSelectionMatchesInJupyterCells = cm_conf.styleSelectedText = set_on;

		// And change any existing cells:
		get_relevant_cells().forEach(function (cell, idx, array) {
			cell.code_mirror.setOption('highlightSelectionMatchesInJupyterCells', set_on);
			cell.code_mirror.setOption('styleSelectedText', set_on);
		});
		// update menu class
		$('.' + menu_toggle_class + ' > .fa').toggleClass('fa-check', set_on);
		// bind/unbind scroll handler
		$('#site')[
			(params.only_cells_in_scroll && params.scroll_min_delay > 0) ? 'on' : 'off'
		]('scroll', scroll_handler);
		console.log(log_prefix, 'toggled', set_on ? 'on' : 'off');
		return set_on;
	}

	function register_new_actions () {
		action_names.toggle = Jupyter.keyboard_manager.actions.register({
			handler : function (env) { toggle_highlight_selected(); },
			help : "Toggle highlighting of selected word",
			icon : 'fa-language',
			help_index: 'c1'
		}, 'toggle', mod_name);
	}

	function bind_hotkeys () {
		if (params.use_toggle_hotkey && params.toggle_hotkey) {
			Jupyter.keyboard_manager.command_shortcuts.add_shortcut(params.toggle_hotkey, action_names.toggle);
			Jupyter.keyboard_manager.edit_shortcuts.add_shortcut(params.toggle_hotkey, action_names.toggle);
		}
	}

	function insert_css () {
		var css = [// in unselected cells, matches have blurred color
			// in selected cells, we keep CodeMirror highlight for the actual selection to avoid confusion
			'.edit_mode .unselected .CodeMirror .cm-matchhighlight {',
			'	background-color: ' + params.highlight_color_blurred + ';',
			'}',
			
			// in active cell, matches which are not the current selection have focussed color
			'.edit_mode .CodeMirror.CodeMirror-focused :not(.CodeMirror-selectedtext).cm-matchhighlight {',
			'    background-color: ' + params.highlight_color + ';',
			'}',
			
			// in all cells, outline matches have blurred color
			'.edit_mode .CodeMirror .cm-matchhighlight-outline {',
			'	outline-style: solid;',
			'	outline-width: ' + params.outline_width + 'px;',
			'	outline-color: ' + params.highlight_color_blurred + ';',
			'}',
			
			// in active cell, outline matches have focussed color
			'.edit_mode .CodeMirror.CodeMirror-focused .cm-matchhighlight-outline {',
			'    outline-color: ' + params.highlight_color + ';',
			'}'
		].join('\n');

		if (params.hide_selections_in_unfocussed) {
			css += [
				// in unselected cells, selections which are not matches should have no background
				'.unselected .CodeMirror :not(.cm-matchhighlight).CodeMirror-selected,',
				'.unselected .CodeMirror :not(.cm-matchhighlight).CodeMirror-selectedtext {',
				'	background: initial;',
				'}',
			].join('\n');
		}

		$('<style type="text/css" id="highlight_selected_word_css">').appendTo('head').html(css);
	}

	function load_extension () {
		// add menu item, as we need it to exist for later
		// toggle_highlight_selected call to set its icon status
		add_menu_item();

		// load config & toggle on/off
		Jupyter.notebook.config.loaded
		.then(function () {
			$.extend(true, params, Jupyter.notebook.config.data.highlight_selected_word);
		}, function on_error (reason) {
			console.warn(log_prefix, 'error loading config:', reason);
		})
		.then(insert_css)
		.then(function () {
			params.show_token = params.show_token ? new RegExp(params.show_token) : false;
			if (params.outlines_only) {
				params.highlight_style += '-outline'
			}
			// set highlight on/off
			toggle_highlight_selected(params.enable_on_load);

			register_new_actions();
			bind_hotkeys();
		})
		// finally log any error we encountered
		.catch(function on_error (reason) { console.warn(log_prefix, 'error loading:', reason); });
	}

	return {
		load_ipython_extension : load_extension
	};
});
