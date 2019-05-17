{%- extends 'full.tpl' -%}


{%- block html_head -%}

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


{{ super() }}



<link rel="stylesheet" href="https://code.jquery.com/ui/1.11.4/themes/smoothness/jquery-ui.css">


<!-- stylesheet from CDN -->
<link rel="stylesheet" type="text/css" href="https://rawgit.com/jfbercher/jupyter_latex_envs/master/src/latex_envs/static/latex_envs.css">

<!-- Custom stylesheet, it must be in the same directory as the html file -->
<link rel="stylesheet" href="custom.css"> 

<!-- Load mathjax 
<script src="https://rawgit.com/ipython-contrib/jupyter_contrib_nbextensions/master/src/jupyter_contrib_nbextensions/nbextensions/latex_envs/thmsInNb4.js"></script>
-->
<script type="text/javascript"  src="https://rawgit.com/jfbercher/jupyter_latex_envs/master/src/latex_envs/static/thmsInNb4.js"> </script>



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

{%- endblock html_head -%}

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
