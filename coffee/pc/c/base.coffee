window.GTDme = {}


###
 *
 *  GTDme.InboxAlways - Inbox anywhere
 *
###
class GTDme.InboxAlways
    constructor: (params = {}) ->
        @_screen
        @_form_shoed = false
        @_event_handler =
            submit_succeed: null
            submit_error:   null

        @$     = $('#inbox-always')
        @$form = @$.find('form')
        @$textbox_content = @$form.find('input[name="content"]')
        @$button_cancel   = @$form.find('a.button-cancel')
        @$button_submit   = @$form.find('a.button-submit')

        @$.click ->
            return false;

        @$.mouseover =>
            @$textbox_content.focus()

        @$form.submit =>
            return false

        @$textbox_content.keydown (ev) =>
            switch ev.keyCode
                when 13
                    @submit()
                when 27
                    @cancel()

        @$button_cancel.click =>
            @cancel()
            return false

        @$button_submit.click =>
            @submit()
            return false

    set_screen: (screen) ->
        @_screen = screen

    show: ->
        @_screen?.show()
        @$.show()
        @$.css
            left: parseInt( ($(window).width() - @$form.width()) / 2, 10 ) - parseInt( @$.css('padding-left'), 10 ) - 2  # 2: border-width
        @_form_showed = true

        @$textbox_content.focus()

    hide: ->
        @$.hide()
        @_screen?.hide()
        @_form_showed = false

    cancel: ->
        @reset()
        @hide()

    submit: ->
        content = $.trim( @$textbox_content.val() )
        if /^ *$/.test( content )
            @$textbox_content.focus()
            return false

        ajax_params =
            url:      "#{URL_BASE}api/item/update"
            type:     'post'
            dataType: 'json'
            data:
                content: content
            success: (res, status, xhr) =>
                item = res.item
                @reset()
                @hide()
                if typeof @_event_handler.submit_succeed is 'function'
                    @_event_handler.submit_succeed(item, xhr)

            error: (xhr, status) ->
                if typeof @_event_handler.submit_error is 'function'
                    @_event_handler.submit_error(xhr)

        $.ajax(ajax_params)

    reset: ->
        @$textbox_content.val('')

    set_event_listener: (event_type, callback) ->
        @_event_handler[event_type] = callback

    clear_event_listener: (event_type) ->
        delete @_event_handler[event_type]



#
# GTDme.ItemManager - item manager
#
class GTDme.ItemManager
    constructor: () ->
        @$ = $('#items')
        @$list = @$.find('> ul')

        @items = {}  # key: item_id
        @project_selector = new GTDme.Selector.Projects

        @api_url =
            update:       "#{URL_BASE}api/item/update"
            update_step:  "#{URL_BASE}api/item/update_step"
            update_order: "#{URL_BASE}api/item/update_order"
            mark_done:    "#{URL_BASE}api/item/mark_done"

        @router = new Router
            connect:
                '/step/([\+\-][0-9]+)/([0-9]+)': @_route_step
                '/done/([0-9]+)':                @_route_done
                '/do_now/([0-9]+)':              @_route_do_now
                '/deliver/([^/]+)/([0-9]+)':     @_route_deliver
                '/edit/([0-9]+)':                @_route_edit

    setup: ->
        self = @
        @$list.find('> li').each ->
            self._set_listener( $(@) )

        @$list
            .sortable(
                handle: '.sort a'
                axis: 'y'
                placeholder: 'sortable_placeholder'
                update: (ev, ui) =>
                    $item_moved = ui.item
                    $item_moved.removeClass('being_dragged')
                    @_update_item_order($item_moved)
                    return true
                start: (ev, ui) =>
                    $item = ui.item
                    $item.addClass('being_dragged')
                    @$list.find('> li.sortable_placeholder').css
                        height:  $item.height()
                stop: (ev, ui) =>
                    $item = ui.item
                    $item.removeClass('being_dragged')
            )

    add_item: (item) ->
        html = $('#jarty\\:items-item').jarty
            i: item
        $li = $(html)
        @_set_listener($li)
        $li.appendTo( $('#items > ul') )
        return $li

    get_item: (params = {}) ->
        $item
        if params?.id?
            $item = $("#items-item\\:#{params.id}")
        else
            return null
        return if $item.size() > 0 then $item else null

    _update_item_order: ($item) ->
        item_id      = $item.attr('id')?.split(':')[1]
        item_id_prev = $item.prev()?.attr('id')?.split(':')[1]
        item_id_next = $item.next()?.attr('id')?.split(':')[1]

        ajax_params =
            url:      @api_url.update_order
            type:     'post'
            dataType: 'json'
            data:
                id:      item_id
                id_prev: item_id_prev
                id_next: item_id_next
            success: (res, status, xhr) ->

            error: (xhr, status) ->

        $.ajax(ajax_params)
        return true


    _set_listener: ($item) ->
        self = @
        $item.find('.menu').hover(
            ->
                $(@).bind 'click.mouseover', (ev) ->
                    $a = $( ev.target )
                    self.router.match( $a.attr('href') ).run( self )
            ->
                $(@).unbind 'click.mouseover'
        )


    _route_step: (m) ->
        [ n, item_id ] = m

        ajax_params =
            url:      @api_url.update_step
            type:     'post'
            dataType: 'json'
            data:
                id: item_id
                n:  n
            success: (res, status, xhr) =>
                item = res.item
                @items[item_id] ?= new GTDme.Item({ id: item_id, manager: @ })
                @items[item.item_id]._update_view(item)
            error: (xhr, status) =>

        $.ajax(ajax_params)
        return false;

    _route_done: (m) ->
        [ item_id ] = m

        ajax_params =
            url:      @api_url.mark_done
            type:     'post'
            dataType: 'json'
            data:
                id: item_id
            success: (res, status, xhr) =>
                $li = @get_item({id: item_id})
                $li.addClass("done").fadeOut ->
                    $(@).remove()
            error: (xhr, status) ->

        $.ajax(ajax_params)
        return false

    _route_do_now: (m) ->
        [ item_id ] = m

        # TODO: HTMLなダイアログ表示
        res = confirm('Have you done?')
        return false  if ! res

        return @_route_done(m)

    _route_deliver: (m) ->
        [ target, item_id ] = m

        if target is 'project'
            item = @items[item_id] ?= new GTDme.Item({ id: item_id, manager: @ })
            $src =  item.$.find(".menu ul li a[href^=\"#/deliver/project/\"]")

            @project_selector.show
                item: item
                $src: $src
                select: (project) =>
                create: (project) =>
                    @deliver_simple(item_id, 'project')
                assign: (project) =>
                    ajax_params =
                        url:      @api_url.update
                        type:     'post'
                        dataType: 'json'
                        data:
                            id:         item_id
                            project_id: project.id
                            belongs:    'project'
                        success: (res, status, xhr) =>
                            $li = @get_item({id: item_id})
                            $li.addClass("to_project").fadeOut ->
                                $(@).remove()
                        error: (xhr, status) =>

                    $.ajax(ajax_params)

            return false

        method_name = "deliver_#{target}"
        if @[method_name]?
            @[method_name](item_id)
        else
            throw new Error("method GTDme.ItemManager##{method_name} is not defined.")

        return false

    _route_edit: (m) ->
        [ item_id ] = m
        @items[item_id] ?= new GTDme.Item({ id: item_id, manager: @ })
        @items[item_id].show_editor()
        return false



    deliver_simple: (id, to) ->
        ajax_params =
            url:      @api_url.update
            type:     'post'
            dataType: 'json'
            data:
                id:      id
                belongs: to
            success: (res, status, xhr) =>
                $li = @get_item({id: id})
                $li.addClass("to_#{to}").fadeOut ->
                    $(@).remove()
            error: (xhr, status) ->

        $.ajax(ajax_params)

    deliver_action: (id) ->
        @deliver_simple(id, 'action')

    deliver_calendar: (id) ->
        @deliver_simple(id, 'calendar')

    deliver_material: (id) ->
        @deliver_simple(id, 'material')

    deliver_someday: (id) ->
        @deliver_simple(id, 'someday')

    deliver_background: (id) ->
        @deliver_simple(id, 'background')

    deliver_project: (id) ->
        @deliver_simple(id, 'project')

    deliver_trash: (id) ->
        @deliver_simple(id, 'trash')


#
# GTDme.Item - an item
#
class GTDme.Item
    constructor: (params = {}) ->
        @id      = params.id
        @manager = params.manager

        @$ = $("#items-item\\:#{@id}")
        @$content = @$.find('.content')
        @$editor  = @$.find('.editor')
        @$options = @$.find('.options')
        @$steps   = @$.find('.steps')
        @$editor_textbox_content = @$editor.find('input[name="content"]')
        @$editor_hidden_raw_text = @$editor.find('input[name="raw_text"]')
        @$editor_button_submit   = @$editor.find('a.button-submit')
        @$editor_button_cancel   = @$editor.find('a.button-cancel')

    show_editor: ->
        @$content.hide()
        @$editor.show()
        @$editor_textbox_content
            .bind( 'keydown.edit', (ev) =>
                switch ev.keyCode
                    when 13
                        @submit_edit()
                    when 27
                        @cancel_edit()
            )
            .val( $.trim( @$editor_hidden_raw_text.val() ) )
            .focus()
        @$editor_button_submit.bind( 'click.edit', =>
            @submit_edit()
            return false
        )
        @$editor_button_cancel.bind( 'click.edit', =>
            @cancel_edit()
            return false
        )

        @$.bind( 'mouseover.edit', =>
            @$editor_textbox_content.focus()
        )

    hide_editor: ->
        @$editor.hide()
        @$content.show()

    cancel_edit: ->
        @$editor_textbox_content
            .val('')
            .unbind('keydown.edit')
        @$editor_button_submit.unbind('click.edit')
        @$editor_button_cancel.unbind('click.edit')
        @$.unbind('mouseover.edit')
        @hide_editor()

    submit_edit: ->
        content_up = $.trim( @$editor_textbox_content.val() )
        if /^[ ]*$/.test(content_up)
            return false
        if content_up is $.trim( @$editor_hidden_raw_text.val() )
            @cancel_edit()

        ajax_params =
            url:      @manager.api_url.update
            type:     'post'
            dataType: 'json'
            data:
                id:      @id
                content: content_up
            success: (res, status, xhr) =>
                item = res.item
                @_update_view(item)
                @cancel_edit()

            error: (xhr, status) ->
                alert('error')

        $.ajax(ajax_params)

    _update_view: (item) ->
        @$content.text( item.content )
        @$editor_hidden_raw_text.val( item.raw_text )

        $html = $(
            $('#jarty\\:items-item').jarty
                i: item
        )

        @$options.html( $html.find('.options').html() )
        @$steps.html( $html.find('.steps').html() )



###
 *
 * Router - URLハッシュを基に各処理へルーティングする
 *
 *   var r = new Router();
 *   r.connect(
 *       '/user/([0-9]+)',
 *       function (m) { var user_id = m[0]; return true; }
 *   );
 *   var m = r.match( 'http://example.com/#!/user/1234' );
 *   m.run();
 *
###
class @Router
    constructor: (params = {}) ->
        # properties
        @_rules = []

        # params.connect
        for k, v of params.connect ? {}
            @connect k, v

    connect: (hash, action) ->
        @_rules.push
            hash: hash
            action: ( action ? -> )
        return @

    match: (url_hash) ->
        url_hash = url_hash.replace( new RegExp('^.*#!?'), '' )  # # or #! を含む以前を削除

        r = @_rules
        for v, i in r
            h = v.hash
            a = v.action
            re_h = new RegExp( ('^' + h + '$').replace(/^\^+/, '^').replace(/\$+$/, '$') )
            m = url_hash.match(re_h)

            if m != null
                # 通常のキャプチャ
                ret =
                    hash:    h
                    action:  a
                    matched: m
                    run:     (o) ->
                        m.shift()
                        return a.apply(o, [m])
                break

        if !ret?
            ret =
                run: (o) => return @_cannot_route.apply(o, [url_hash])

        return ret

    _cannot_route: (h) ->
        throw new Error('cannot route: ' + h)

###
 *
 *  GTDme.Selector -
 *
###
class GTDme.Selector
    constructor: (params = {}) ->
        @router
        @_cache
        @_item
        @_callback_select
        @_callback_create
        @_callback_assign

        @$
        @$head
        @$body
        @$foot
        @$loading
        @$list
        @$_src


    show: (params) ->
        self = @

        @hide()

        @_item = params.item
        @$_src = params.$src

        @_callback_select = params.select
        @_callback_create = params.create
        @_callback_assign = params.assign

        @$.show()
        @$.css
            top:  @$_src.offset().top  - 80
            left: @$_src.offset().left - 400
        @_item.$.addClass('hover')
        @$loading.show()

        @$button_cancel.bind 'click.cancel', ->
            return self.router.match( $(@).attr('href') ).run(self)

        @load()

    hide: ->
        @$.hide()
        @$list.empty()

        @$button_cancel.unbind 'click.cancel'

        @_item?.$?.removeClass('hover')
        delete @_item
        delete @$_src

    load: ->
    update_view: ->

###
 *
 *  GTDme.Selector.Projects -
 *
###
class GTDme.Selector.Projects extends GTDme.Selector
    constructor: (params = {}) ->
        super(params)
        @$ = $('#selector-project')
        @$head = @$.find('> .head')
        @$body = @$.find('> .body')
        @$foot = @$.find('> .foot')
        @$loading       = @$body.find('> .loading')
        @$list          = @$body.find('> ul')
        @$button_cancel = @$foot.find('a.button-cancel')

        @router = new Router
            connect:
                '/project/create':          @_route_create
                '/project/assign/([0-9]+)': @_route_assign
                '/project/cancel':          @_route_cancel

    # show: (params) ->
    #     super(params)

    hide: ->
        super()
        delete @_callback_select
        delete @_callback_create
        delete @_callback_assign

    load: ->
        ajax_params =
            url:      "#{URL_BASE}api/project/list?t=#{(new Date()).getTime()}"
            type:     'get'
            dataType: 'json'
            data: {
            }
            success: (res, status, xhr) =>
                @update_view(res.projects)
                @_cache = res.projects
            error: (xhr, status) =>

        if @_cache?
            @update_view(@_cache)
        else
            $.ajax(ajax_params)

    update_view: (projects) ->
        self = @
        html = $jarty_template = $('#jarty\\:selector-project-item').jarty
            projects: projects

        @$loading.hide()
        @$list.html(html)
        @$list.find('> li a').hover(
            ->
                $(@).bind 'click.mouseover', (ev) ->
                    $a = $( ev.target )
                    return self.router.match( $a.attr('href') ).run( self )
            ->
                $(@).unbind 'click.mouseover'
        )

    _route_create: (m) ->
        o =
            id:   null
            type: 'create'

        @_callback_select?(o)
        @_callback_create?(o)

        delete @_cache
        @hide()
        return false

    _route_assign: (m) ->
        [ project_id ] = m
        o =
            id:   project_id
            type: 'assign'

        @_callback_select?(o)
        @_callback_assign?(o)

        @hide()
        return false

    _route_cancel: (m) ->
        @hide()
        return false

###
 *
 *  GTDme.Screen - Screen
 *
###
class GTDme.Screen
    constructor: (params = {}) ->
        @parent = params.parent

        @$ = $('<div></div>')
            .attr(
                id: params.id ? 'gtdme-global-screen'
            )
            .css(
                'position':   'absolute'
                'z-index':    99999     # to be under #inbox-always, over #inbox-always-toggle
                'top':        -60
                'left':       0
                'width':      0
                'height':     0
                'background': '#000'
                'opacity':    '.66'
            )
            .appendTo('body')

        if typeof params.css is 'object'
            @$.css(params.css)

        if typeof params.click is 'function'
            @$.click (ev) =>
                params.click(@, ev)

    show: ->
        @$
            .css(
                width: $(window).width()
                height: $(window).height() + 60
            )
            .show()

    hide: ->
        @$.hide()



window.add_jarty_filter = (name, func) ->
    # foo_bar -> fooBar
    name = name.replace(
        new RegExp('_(.)', 'g'),
        (p, c) ->
            return c.toUpperCase()
    )
    Jarty?.Pipe?.prototype?[name] = func



$ ->
    window.inbox_always  = new GTDme.InboxAlways
    inbox_always.set_screen( new GTDme.Screen
        parent: inbox_always
        id:     'inbox-always-screen'
        click: () ->
            inbox_always.hide()
    )

    $('#inbox-always-toggle a').click ->
        inbox_always.show()
        return false

    window.item_manager = new GTDme.ItemManager()
    item_manager.setup()

    add_jarty_filter( 'split', () ->
        return @value.split('::')
    )
