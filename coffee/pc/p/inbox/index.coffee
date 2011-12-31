GTDme.Inbox = {}

#
# GTDme.Inbox.Form - local form
#
class GTDme.Inbox.Form
    constructor: ->
        @$ = $('#inbox-form')
        @$form = @$.find('form')
        @$textbox_content = @$form.find('input[name="content"]')

        @manager

        @$.mouseover =>
            @$textbox_content.focus()

        @$form.submit =>
            @submit()
            return false

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
                if @manager?
                    @manager.add_item(item)
                    @$textbox_content.blur().focus()

            error: (xhr, status) ->

        $.ajax(ajax_params)

    reset: ->
        @$textbox_content.val('')

$ ->
    window.inbox_form = new GTDme.Inbox.Form()
    inbox_form.manager = item_manager

    inbox_always.set_event_listener(
        'submit_succeed'
        (item, xhr) ->
            item_manager.add_item(item)
            inbox_form.$textbox_content.focus()
    )
