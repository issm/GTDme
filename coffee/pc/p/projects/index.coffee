GTDme.Projects = {}

#
# GTDme.Projects.Manager - project manager
#
class GTDme.Projects.Manager
    constructor: () ->
        @$ = $('#projects')
        @$list = @$.find('> ul')

        @projects = {}  # key: project_id

        @api_url =
            update:       "#{URL_BASE}api/project/update"
            update_order: "#{URL_BASE}api/project/update_order"
            mark_done:    "#{URL_BASE}api/project/mark_done"

        @router = new Router
            connect:
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
                    @_update_item_order($item_moved)
                    return true
                start: (ev, ui) =>
                    $item = ui.item
                    @$list.find('> li.sortable_placeholder').css
                        height:  $item.height()
            )

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


    _update_item_order: ($item) ->
        project_id      = $item.attr('id')?.split(':')[1]
        project_id_prev = $item.prev()?.attr('id')?.split(':')[1]
        project_id_next = $item.next()?.attr('id')?.split(':')[1]

        ajax_params =
            url:      @api_url.update_order
            type:     'post'
            dataType: 'json'
            data:
                id:      project_id
                id_prev: project_id_prev
                id_next: project_id_next
            success: (res, status, xhr) ->

            error: (xhr, status) ->

        $.ajax(ajax_params)
        return true


    _route_edit: (m) ->
        [ project_id ] = m
        @projects[project_id] ?= new GTDme.Project({ id: project_id, manager: @ })
        @projects[project_id].show_editor()
        return false


#
# GTDme.Project - a project
#
class GTDme.Project
    constructor: (params = {}) ->
        @id      = params.id
        @manager = params.manager

        @$ = $("#projects-item\\:#{@id}")
        @$name        = @$.find('.name')
        @$code        = @$.find('.code')
        @$description = @$.find('.description')
        @$editor      = @$.find('.editor')
        @$editor_textbox_name        = @$editor.find('form input[name="name"]')
        @$editor_textbox_code        = @$editor.find('form input[name="code"]')
        @$editor_textbox_description = @$editor.find('form input[name="description"]')
        @$editor_button_submit       = @$editor.find('form a.button-submit')
        @$editor_button_cancel       = @$editor.find('form a.button-cancel')

        @$_editor_current_input = @$editor_textbox_name

    _handle_keydown_edit: (ev) =>
        switch ev.keyCode
            when 13
                @submit_edit()
            when 27
                @cancel_edit()

    show_editor: ->
        @$name.hide()
        @$description.hide()
        @$editor.show()
        @$editor_textbox_name
            .bind('keydown.edit', @_handle_keydown_edit)
            .val( $.trim( @$name.text() ) )
            .bind('focus.edit', =>
                @$_editor_current_input = @$editor_textbox_name
            )
            .focus()
        @$editor_textbox_code
            .bind('keydown.edit', @_handle_keydown_edit)
            .bind('focus.edit', =>
                @$_editor_current_input = @$editor_textbox_code
            )
        @$editor_textbox_description
            .bind('keydown.edit', @_handle_keydown_edit)
            .bind('focus.edit', =>
                @$_editor_current_input = @$editor_textbox_description
            )
        @$editor_button_submit.bind('click.edit', =>
            @submit_edit()
            return false
        )
        @$editor_button_cancel.bind('click.edit', =>
            @cancel_edit()
            return false
        )

        @$.bind('mouseover.edit', =>
            @$_editor_current_input.focus()
        )

        @$editor_textbox_name.focus()

    hide_editor: ->
        @$editor.hide()
        @$name.show()
        @$description.show()

    validate_edit: ->
        _name        = $.trim( @$editor_textbox_name.val() )
        _code        = $.trim( @$editor_textbox_code.val() )
        _description = $.trim( @$editor_textbox_description.val() )

        valid = true
        valid = false  if /^[ 　]*$/.test(_name)
        #valid = false  if /^[ 　]*$/.test(_code)
        #valid = false  if /^[ 　]*$/.test(_description)

        return valid

    editor_next_input: ->
        switch @$_editor_current_input
            when @$editor_textbox_name
                @$editor_textbox_code.focus()
            when @$editor_textbox_code
                @$editor_textbox_description.focus()
            when @$editor_textbox_description
                @$editor_textbox_name.focus()


    cancel_edit: ->
        @$editor_textbox_name
            .val('')
            .unbind('keydown.edit')
            .unbind('focus.edit')
        @$editor_textbox_code
            .unbind('keydown.edit')
            .unbind('focus.edit')
        @$editor_textbox_description
            .unbind('keydown.edit')
            .unbind('focus.edit')
        @$editor_button_submit.unbind('click.edit')
        @$editor_button_cancel.unbind('click.edit')
        @$.unbind('mouseover.edit')
        @hide_editor()

    submit_edit: ->
        if ! @validate_edit()
            @editor_next_input()
            return false

        name_up        = $.trim( @$editor_textbox_name.val() )
        code_up        = $.trim( @$editor_textbox_code.val() )
        description_up = $.trim( @$editor_textbox_description.val() )

        if /^[ ]*$/.test(name_up)
            return false

        ajax_params =
            url:      @manager.api_url.update
            type:     'post'
            dataType: 'json'
            data:
                id:          @id
                name:        name_up
                code:        code_up
                description: description_up
            success: (res, status, xhr) =>
                project = res.project
                @_update_view(project)
                @cancel_edit()

            error: (xhr, status) ->
                alert('error')

        $.ajax(ajax_params)

    _update_view: (project) ->
        $html = $(
            $('#jarty\\:projects-item').jarty
                i: project
        )

        @$name.html( $html.find('.name').html() )
        @$code.text( project.code )
        @$description.text( project.description )

        # @$options.html( $html.find('.options').html() )
        # @$steps.html( $html.find('.steps').html() )





#
# GTDme.Projects.Form - local form
#
class GTDme.Projects.Form
    constructor: ->
        @$ = $('#project-form')
        @$form = @$.find('form')
        @$textbox_name        = @$form.find('input[name="name"]')
        @$textbox_code        = @$form.find('input[name="code"]')
        @$textbox_description = @$form.find('input[name="description"]')
        @$button_submit = @$form.find('input[name="submit"]')
        @$button_cancel = @$form.find('input[name="cancel"]')

        @$_current_input = @$textbox_name

        @$textbox_name.focus =>
            @$_current_input = @$textbox_name
        @$textbox_code.focus =>
            @$_current_input = @$textbox_code
        @$textbox_description.focus =>
            @$_current_input = @$textbox_description

        @manager

        @$.mouseover =>
            @$_current_input.focus()

        @$form.submit =>
            if @$_current_input is @$textbox_description
                @submit()
            else
                @next_input()
            return false

        @$button_cancel.click =>
            @reset()

    validate: ->
        valid = true

        _name        = $.trim( @$textbox_name.val() )
        _code        = $.trim( @$textbox_code.val() )
        _description = $.trim( @$textbox_description.val() )

        valid = true
        valid = false  if /^[ 　]*$/.test(_name)
        valid = false  if /^[ 　]*$/.test(_code)
        #valid = false  if /^[ 　]*$/.test(_description)

        return valid

    next_input: ->
        switch @$_current_input
            when @$textbox_name
                @$textbox_code.focus()
            when @$textbox_code
                @$textbox_description.focus()
            when @$textbox_description
                @$textbox_name.focus()

    submit: ->
        if ! @validate()
            @next_input()
            return false

        _name        = $.trim( @$textbox_name.val() )
        _code        = $.trim( @$textbox_code.val() )
        _description = $.trim( @$textbox_description.val() )

        ajax_params =
            url:      "#{URL_BASE}api/project/update"
            type:     'post'
            dataType: 'json'
            data:
                name:         _name
                code:         _code
                description: _description
            success: (res, status, xhr) =>
                project = res.project
                console.log project

                @reset()

            error: (xhr, status) ->

        $.ajax(ajax_params)
        return false

    reset: ->
        @$textbox_description.val('')
        @$textbox_code.val('')
        @$textbox_name.val('').focus()

$ ->
    window.project_manager = new GTDme.Projects.Manager()
    project_manager.setup()

    window.project_form = new GTDme.Projects.Form()
    project_form.manager = project_manager

    # inbox_always.set_event_listener(
    #     'submit_succeed'
    #     (item, xhr) ->
    #         item_manager.add_item(item)
    #         inbox_form.$textbox_content.focus()
    # )
