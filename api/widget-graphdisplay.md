---
layout: main
title: "Vamonos API Reference"
header: Vamonos API Reference
---


Vamonos.Widget.GraphDisplay
===========================

[Back](index.html)

GraphDisplay provides display functionality to widgets that need not use graph data structures.


### Constructor Arguments

 * **container** :: *String* | *jQuery Selector* -- **required**

    The id or a jQuery selector of the div in which this widget should draw itself.



 * **colorEdges** :: *Array* -- default Value: `[]`

    provides a way to set edge coloring based on vertex variables or edge properties. takes an array of doubles of the form  `[ edge-predicate, color ]`, where color is a hex color and edge-predicate is either a string of the form `'vertex1->vertex2'` or a function that takes an edge and returns a boolean

    Example:

>     colorEdges: [
>         ['u->v', '#FF7D7D'],
>         [ function(edge){
>             return (edge.target.pred ? edge.target.pred.id === edge.source.id : false)
>                 || (edge.source.pred ? edge.source.pred.id === edge.target.id : false) }
>         , '#92E894' ],
>     ]



 * **containerMargin** :: *Number* -- default Value: `30`

    how close nodes can get to the container edge



 * **draggable** :: *Boolean* -- default Value: `true`

    whether nodes can be moved



 * **edgeLabel** :: *Object* | *Array* | *Function* -- optional

    an array, containing the name of the edge attribute to displayand the default value for new edges or a function taking an edge and returning a string. one can also specify whether to show certain things in edit or display mode by using an object.

    Example:

>     edgeLabel: { display: [ 'w', 1 ], edit: function(e){ return e.w } }



 * **highlightChanges** :: *Boolean* -- default Value: `true`

    whether nodes will get the css class 'changed' when they are modified



 * **minX** :: *Number* -- default Value: `100`

    minimum width of the graph widget



 * **minY** :: *Number* -- default Value: `100`

    minimum height of the graph widget



 * **resizable** :: *Boolean* -- default Value: `true`

    whether the graph widget is resizable



 * **vertexCssAttributes** :: *Object* -- default Value: `{}`

    provides a way to change CSS classes of vertices based on vertex attributes. takes an object of the form `{ attribute: value | [list of values] }`. in the case of a single value,  the vertex will simply get a class with the same name as the attribute. in the case of a list of values, the css class will be of the form 'attribute-value' when its value matches.

    Example:

>     vertexCssAttributes: { done: true }
>     vertexCssAttributes: { color: ['white', 'gray', 'black'] }



 * **vertexLabels** :: *Object* -- default Value: `{}`

    an object containing a mapping of label positions (inner, nw, sw, ne, se) to labels. Labels can display simple variable names (corresponding to inputVars). This must be provided in the form: `{ label: ['var1', 'var2'] }`. It can be more complicated, as a function that takes a vertex and returns some html. if we give a label an object, we can control what is shown in edit/display mode in the form: `{ label : { edit: function{}, display: function{} } }`

    Example:

>     vertexLabels: {
>         inner : {
>             edit: function(vtx){return vtx.name}, 
>             display: function(vtx){return vtx.d} 
>         },
>         sw    : function(vtx){return vtx.name}, 
>         ne    : ['u', 'v'],
>         nw    : ['s'],
>     }


