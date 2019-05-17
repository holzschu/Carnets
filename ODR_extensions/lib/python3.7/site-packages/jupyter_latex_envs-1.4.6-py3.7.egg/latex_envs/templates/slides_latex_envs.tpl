{%- extends 'slides_reveal.tpl' -%}


{% block header %}
<!DOCTYPE html>
<html>
<head>

<meta charset="utf-8" />
<meta http-equiv="X-UA-Compatible" content="chrome=1" />

<meta name="apple-mobile-web-app-capable" content="yes" />
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />

  <meta charset="utf-8"/>

<!-- javascript from CDN for conversion -->
  <script src="https://cdnjs.cloudflare.com/ajax/libs/marked/0.3.5/marked.js"></script>

    

{% if nb['metadata']['latex_envs']['eqLabelWithNumbers'] == True %}
<script type="text/x-mathjax-config">
// make sure that equations numbers are enabled
MathJax.Hub.Config({ TeX: { equationNumbers: {
    autoNumber: "AMS", // All AMS equations are numbered
    useLabelIds: true, // labels as ids
    // format the equation number - uses an offset eqNumInitial (default 0)
    formatNumber: function (n) {return String(Number(n)+Number({{nb['metadata']['latex_envs']['eqNumInitial']}})-1)} 
    } } 
});
</script>
{% else %}
<script type="text/x-mathjax-config">
// make sure that equations numbers are enabled
MathJax.Hub.Config({ TeX: { equationNumbers: {
    autoNumber: "none", // All AMS equations are numbered
    useLabelIds: true, // labels as ids
    } } 
});
</script>
{% endif %}


<title>{{resources['metadata']['name']}} slides</title>

<script src="{{resources.reveal.require_js_url}}"></script>
<script src="{{resources.reveal.jquery_url}}"></script>

<!-- General and theme style sheets -->
<link rel="stylesheet" href="{{resources.reveal.url_prefix}}/css/reveal.css">
<link rel="stylesheet" href="{{resources.reveal.url_prefix}}/css/theme/{{resources.reveal.theme}}.css" id="theme">

<!-- If the query includes 'print-pdf', include the PDF print sheet -->
<script>
if( window.location.search.match( /print-pdf/gi ) ) {
        var link = document.createElement( 'link' );
        link.rel = 'stylesheet';
        link.type = 'text/css';
        link.href = '{{resources.reveal.url_prefix}}/css/print/pdf.css';
        document.getElementsByTagName( 'head' )[0].appendChild( link );
}

</script>

<!--[if lt IE 9]>
<script src="{{resources.reveal.url_prefix}}/lib/js/html5shiv.js"></script>
<![endif]-->

<!-- Loading the mathjax macro -->
{{ mathjax() }}

<!-- Get Font-awesome from cdn -->
<link rel="stylesheet" href="{{resources.reveal.font_awesome_url}}">

{% for css in resources.inlining.css -%}
    <style type="text/css">
    {{ css }}
    </style>
{% endfor %}

<style type="text/css">
/* Overrides of notebook CSS for static HTML export */
.reveal {
  font-size: 160%;
}
.reveal pre {
  width: inherit;
  padding: 0.4em;
  margin: 0px;
  font-family: monospace, sans-serif;
  font-size: 80%;
  box-shadow: 0px 0px 0px rgba(0, 0, 0, 0);
}
.reveal pre code {
  padding: 0px;
}
.reveal section img {
  border: 0px solid black;
  box-shadow: 0 0 10px rgba(0, 0, 0, 0);
}
.reveal i {
  font-style: normal;
  font-family: FontAwesome;
  font-size: 2em;
}
.reveal .slides {
  text-align: left;
}
.reveal.fade {
  opacity: 1;
}
.reveal .progress {
  position: static;
}
.reveal .controls .navigate-left,
.reveal .controls .navigate-left.enabled {
  border-right-color: #727272;
}
.reveal .controls .navigate-left.enabled:hover,
.reveal .controls .navigate-left.enabled.enabled:hover {
  border-right-color: #dfdfdf;
}
.reveal .controls .navigate-right,
.reveal .controls .navigate-right.enabled {
  border-left-color: #727272;
}
.reveal .controls .navigate-right.enabled:hover,
.reveal .controls .navigate-right.enabled.enabled:hover {
  border-left-color: #dfdfdf;
}
.reveal .controls .navigate-up,
.reveal .controls .navigate-up.enabled {
  border-bottom-color: #727272;
}
.reveal .controls .navigate-up.enabled:hover,
.reveal .controls .navigate-up.enabled.enabled:hover {
  border-bottom-color: #dfdfdf;
}
.reveal .controls .navigate-down,
.reveal .controls .navigate-down.enabled {
  border-top-color: #727272;
}
.reveal .controls .navigate-down.enabled:hover,
.reveal .controls .navigate-down.enabled.enabled:hover {
  border-top-color: #dfdfdf;
}
.reveal .progress span {
  background: #727272;
}
div.input_area {
  padding: 0.06em;
}
div.code_cell {
  background-color: transparent;
}
div.prompt {
  width: 11ex;
  padding: 0.4em;
  margin: 0px;
  font-family: monospace, sans-serif;
  font-size: 80%;
  text-align: right;
}
div.output_area pre {
  font-family: monospace, sans-serif;
  font-size: 80%;
}
div.output_prompt {
  /* 5px right shift to account for margin in parent container */
  margin: 5px 5px 0 0;
}
div.text_cell.rendered .rendered_html {
  /* The H1 height seems miscalculated, we are just hidding the scrollbar */
  overflow-y: hidden;
}
a.anchor-link {
  /* There is still an anchor, we are only hidding it */
  display: none;
}
.rendered_html p {
  text-align: inherit;
}
::-webkit-scrollbar
{
  width: 6px;
  height: 6px;
}
::-webkit-scrollbar *
{
  background:transparent;
}
::-webkit-scrollbar-thumb
{
  background: #727272 !important;
}
</style>



<!-- stylesheet from CDN -->
<link rel="stylesheet" type="text/css" href="https://rawgit.com/jfbercher/jupyter_latex_envs/master/src/latex_envs/static/latex_envs.css">

<!-- Custom stylesheet, it must be in the same directory as the html file -->
<link rel="stylesheet" href="custom.css"> 

<!-- Load mathjax -->
<script type="text/javascript"  src="https://rawgit.com/jfbercher/jupyter_latex_envs/master/src/latex_envs/static/thmsInNb4.js"> </script>

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.12.1/jquery-ui.css">

<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.9.1/jquery-ui.min.js"></script>


<script>
$( document ).ready(function(){

        //Value of configuration variables, some taken from the notebook's metada. 
        eqNum = 0; // begins equation numbering at eqNum+1
        eqLabelWithNumbers = "{{nb['metadata']['latex_envs']['eqLabelWithNumbers']}}"=="True" ? true : false; //if true, label equations with equation numbers; 
                                       //otherwise using the tag specified by \label
        conversion_to_html = false;
        current_cit=1;
        cite_by='key';  //only number and key are supported
        //var document={}
        document.bibliography={};

        // Read environment map config
        initmap();
        // Read user envs config, if specified
        {% if nb['metadata']['latex_envs']['user_envs_cfg'] == True %}
                var data = {{ include_userenvs_cfg() }}
                environmentMap = $.extend(true,{}, environmentInitialMap,data)
        {% else %}
                environmentMap = $.extend(true,{}, environmentInitialMap)        
        {% endif %}

        // fire the main function with these parameters
        var html_to_analyse = $('body').html()
        var html_converted = thmsInNbConv(marked,html_to_analyse);
        html_converted = html_converted.replace(/%[\S\t ]*<\/p>/gm,"</p>")
        $('body').html(html_converted)
        // Show/hide anchors
        var labels_anchors = "{{nb['metadata']['latex_envs']['labels_anchors']}}"=="True" ? true : false;
        $('.latex_label_anchor').toggle(labels_anchors)
        // Number all environments
        report_style_numbering = "{{nb['metadata']['latex_envs']['report_style_numbering']}}"=="True" ? true : false;
        reset_counters();
        renumberAllEnvs();

    });
</script>


</head>
{% endblock header%}

{% block body %}

{% if nb['metadata']['latex_envs']['latex_user_defs'] == True %}
<div id='latex_user_defs'>
        {{ include_latexdefs('latexdefs.tex') }}
</div>
{% endif %}

{{ super() }}



{%- endblock body %}

{% block footer %}
</html>
{% endblock footer %}
