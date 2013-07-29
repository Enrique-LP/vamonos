class Graph

    constructor: ({
        container
        @varName
        defaultGraph
        @inputVars
        @vertexLabels
        @edgeLabel
        @colorEdges
        vertexCssAttributes
        containerMargin
        minX
        minY
    }) ->

        @inputVars    ?= {}
        @theGraph      = defaultGraph ? new Vamonos.DataStructure.Graph()
        @inputVars[k]  = @theGraph.vertex(v) for k,v of @inputVars
        @container     = Vamonos.jqueryify(container)

        @displayWidget = new Vamonos.Widget.GraphDisplay
            editableEdgeLabelMaker: @createEditableEdgeLabel
            container: @container
            vertexLabels: @vertexLabels
            vertexCssAttributes: vertexCssAttributes
            edgeLabel: @edgeLabel
            colorEdges: @colorEdges
            containerMargin: containerMargin
            minX: minX
            minY: minY
   
    event: (event, options...) -> switch event
        when "setup"
            [@viz] = options
            @registerVariables()
            @updateVariables()

        when "render"
            [frame, type] = options
            @displayWidget.fitGraph(frame[@varName])
            @displayWidget.draw(frame[@varName], frame)

        when "editStart"    
            @startEditing()

        when "editStop"     
            @stopEditing()

    # ----------------- EDITING MODE ------------------------ #

    startEditing: () ->
        @displayWidget.clearDisplay()
        @displayWidget.mode = "edit"
        @displayWidget.fitGraph(@theGraph)
        @displayWidget.draw(@theGraph, @inputVars)
        @setContainerEditBindings()
        @setConnectionEditBindings()

    stopEditing: ->
        @deselect()
        @displayWidget.mode = undefined
        @unsetConnectionEditBindings()
        @unsetContainerEditBindings()
        @updateVariables()
        @displayWidget.clearDisplay()

    registerVariables: ->
        @viz.registerVariable(key, true) for key of @inputVars
        for e in @colorEdges when typeof e[0] is 'string'
            @viz.registerVariable(v) for v in e[0].split(/<?->?/)
        for label, values of @vertexLabels
            for v in values when typeof v is 'string'
                @viz.registerVariable(v)

    updateVariables: ->
        graph = Vamonos.clone(@theGraph)
        @viz.setVariable(@varName, graph)
        for k, v of @inputVars
            # TODO do alerting in a friendlier way - maybe using mikes boxes
            unless v?
                alert "GRAPH WIDGET: please set #{k}!"
                throw "GRAPH WIDGET: need a value for #{k}!"
            @viz.setVariable(k, graph.vertex(v.id), true)

    # adds a vertex to the graph being edited and redraws the graph.
    addVertex: (vertex = {}, autoSelect = true) ->
        newv = @theGraph.addVertex(vertex)
        @displayWidget.draw(@theGraph, @inputVars)
        node = @displayWidget.nodes[newv.id]
        @selectNode(node) if autoSelect
        node

    removeVertex: (vid) ->
        @deselect()
        @theGraph.removeVertex(vid)
        for k, v of @inputVars when v? and v.id is vid
            @inputVars[k] = undefined
        @displayWidget.draw(@theGraph, @inputVars)

    addEdge: (sourceId, targetId) ->
        attrs = {}
        if @edgeLabel?.length
            attrs[@edgeLabel[0]] = @edgeLabel[1]
        @theGraph.addEdge(sourceId, targetId, attrs)
        @displayWidget.draw(@theGraph, @inputVars)
        @connectionBindings(@displayWidget.connections[sourceId][targetId])

    removeEdge: (sourceId, targetId) ->
        @deselect() if 'edge' is @selected()
        @theGraph.removeEdge(sourceId, targetId)
        @displayWidget.draw(@theGraph, @inputVars)

    setContainerEditBindings: ->
        @displayWidget.$outer.on "click.vamonos-graph", (e) =>
            $target = $(e.target)
            if not @selected()
                if $target.is("div.vertex-contents")
                    @selectNode($target.parent())
                if $target.is(@displayWidget.$inner)
                    @addVertex({x: e.offsetX - 12, y: e.offsetY - 12})
            else
                if $target.is("div.vertex-contents") and 'vertex' is @selected()
                    sourceId = @$selectedNode.attr("id")
                    targetId = $target.parent().attr("id")
                    if sourceId is targetId
                        @deselect()
                    else if @theGraph.edge(sourceId, targetId)
                        @selectNode(@displayWidget.nodes[targetId])
                    else
                        @addEdge(sourceId, targetId)
                        @removePotentialEdge()
                else if $target.is("div.vertex-contents") and 'edge' is @selected()
                    @selectNode($target.parent())
                else if $target.is(@displayWidget.$inner)
                    @deselect()
            true

    unsetContainerEditBindings: ->
        @displayWidget.$outer.off("click.vamonos-graph")

    setConnectionEditBindings: ->
        @displayWidget.eachConnection (sourceId, targetId, con) =>
            @connectionBindings(con)

    connectionBindings: (con) ->
        con.bind "click", (c) =>
            @selectConnection(c)
        con.bind "mouseenter", (c) =>
            return if c.id is @$selectedConnection?.id
            c.setPaintStyle(@displayWidget.hoverPaintStyle)
        con.bind "mouseexit", (c) =>
            return if c.id is @$selectedConnection?.id
            @displayWidget.resetConnectionStyle(c)
        if @edgeLabel?
            con.hideOverlay("edgeLabel")
            con.addOverlay([
                "Custom"
                create: => 
                    @createEditableEdgeLabel(
                        @theGraph.edge(con.sourceId, con.targetId)
                    )
                id: "editableEdgeLabel"
            ])


    unsetConnectionEditBindings: ->
        @displayWidget.eachConnection (sourceId, targetId, con) =>
            con.unbind("click")
            con.unbind("mouseenter")
            con.unbind("mouseexit")
            con.removeOverlay("editableEdgeLabel")
            con.showOverlay("edgeLabel")

    selected: () ->
        return 'vertex' if @$selectedNode?
        return 'edge'   if @$selectedConnection?
        return false

    selectNode: (node) ->
        @stopEditingLabel()
        @deselectNode()       if 'vertex' is @selected()
        @deselectConnection() if 'edge' is @selected()

        @$selectedNode = node
        @$selectedNode.addClass("selected")
        @$selectedNode.removeClass('hovering')

        # Show dotted and red lines for potential edge additions/deletions
        @others = @$selectedNode
            .siblings("div.vertex")
            .children("div.vertex-contents")
        @others.on "mouseenter.vamonos-graph", (e) =>
            @potentialEdgeTo($(e.target).parent())
        @others.on "mouseleave.vamonos-graph", @removePotentialEdge

        @openDrawer()

    selectConnection: (con) ->
        @deselectNode()       if 'vertex' is @selected()
        @deselectConnection() if 'edge' is @selected()

        @$selectedConnection = con
        @$selectedConnection.setPaintStyle(@displayWidget.selectedPaintStyle)

        @openDrawer()

    deselect: () ->
        @deselectNode()
        @deselectConnection()
        @closeDrawer()

    deselectNode: () ->
        return unless @$selectedNode?
        @displayWidget.jsPlumbInstance.detach(@possibleEdge) if @possibleEdge?
        @others.off("mouseenter.vamonos-graph mouseleave.vamonos-graph")
        @$selectedNode.removeClass("selected")
        @$selectedNode = undefined

    deselectConnection: () ->
        return unless @$selectedConnection?
        @displayWidget.resetConnectionStyle(@$selectedConnection)
        @$selectedConnection = undefined
        @removePotentialEdge()

    potentialEdgeTo: (node) =>
        sourceId   = @$selectedNode.attr("id")
        targetId   = node.attr("id")
        return if @displayWidget.connections[sourceId]?[targetId]?

        @potentialEdge = @displayWidget.jsPlumbInstance.connect
            source: sourceId
            target: targetId
            paintStyle: @displayWidget.potentialEdgePaintStyle

    removePotentialEdge: () =>
        return unless @potentialEdge?
        @displayWidget.jsPlumbInstance.detach(@potentialEdge)
        @potentialEdge = undefined

    openDrawer: ->
        if @$drawer?
            @$drawer.html("")
        else
            @$drawer = $("<div>", { class: "graph-drawer" }).hide()
            @displayWidget.$outer.parent().append(@$drawer)

        type = @selected()

        switch type
            when 'vertex'
                elem = @theGraph.vertex(@$selectedNode.attr("id"))
                $("<span class='label'>vertex&nbsp;&nbsp;#{elem.name}&nbsp;&nbsp;</span>")
                    .appendTo(@$drawer)

                for v of @inputVars
                    $("<button>", {text: "#{v}"})
                        .on "click.vamonos-graph", (e) =>
                            @inputVars[v] = elem
                            @displayWidget.draw(@theGraph, @inputVars)
                        .appendTo(@$drawer)

            when 'edge'
                sourceId = @$selectedConnection.sourceId
                targetId = @$selectedConnection.targetId
                elem = @theGraph.edge(sourceId, targetId)
                nametag =
                    elem.source.name + "&nbsp;" +
                    (if @theGraph.directed then "->" else "-") +
                    "&nbsp;" + elem.target.name
                @$drawer.append(
                    "<span class='label'>edge&nbsp;&nbsp;#{nametag}&nbsp;&nbsp;</span>"
                )

        $deleteButton = $("<button>", {text: "del"})
            .on "click.vamonos-graph", (e) =>
                switch type
                    when 'vertex'
                        @removeVertex(elem.id)
                    when 'edge'
                        @removeEdge(elem.source.id, elem.target.id)
            .appendTo(@$drawer)

        @$drawer.fadeIn("fast") unless @$drawer.is(":visible")

    closeDrawer: () ->
        return unless @$drawer?
        @$drawer.fadeOut("fast")
        @$drawer = undefined

    createEditableEdgeLabel: (edge, $wrapper = $("<div>")) =>
        val = Vamonos.rawToTxt(edge[@edgeLabel[0]] ? "")
        $label = $("<div class='graph-label'>#{val}</div>")
        $wrapper.append($label)
        $label.on "click", =>
            @selectConnection(
                @displayWidget.connections[edge.source.id][edge.target.id]
            )
            @editAttribute($label, edge)
        return $wrapper

    editAttribute: ($label, edge) =>
        $editor = $("<input class='inline-input'>")
            .hide()
            .val(edge[@edgeLabel[0]] ? "")
            .width($label.width()) 
            .on "keydown.vamonos-graph", (event) =>
                return unless event.keyCode in [13, 32, 9, 27]
                @doneEditingLabel($label, $editor, edge)
                false
            .on "blur.vamonos-graph something-was-selected", (event) =>
                @doneEditingLabel($editor, edge)
                true
        $label.html($editor)
        $editor.fadeIn("fast")
            .focus()
            .select()

    doneEditingLabel: ($editor, edge) =>
        val = Vamonos.txtToRaw($editor.val())
        if val?
            edge[@edgeLabel[0]] = val
        $editor.html(@createEditableEdgeLabel(edge, $editor))

    stopEditingLabel: =>
        @displayWidget.$inner
            .find("input.inline-input")
            .trigger("something-was-selected")

Vamonos.export { Widget: { Graph } }
