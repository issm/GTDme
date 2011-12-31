(function() {

  GTDme.Inbox = {};

  GTDme.Inbox.Form = (function() {

    function Form() {
      var _this = this;
      this.$ = $('#inbox-form');
      this.$form = this.$.find('form');
      this.$textbox_content = this.$form.find('input[name="content"]');
      this.manager;
      this.$.mouseover(function() {
        return _this.$textbox_content.focus();
      });
      this.$form.submit(function() {
        _this.submit();
        return false;
      });
    }

    Form.prototype.submit = function() {
      var ajax_params, content,
        _this = this;
      content = $.trim(this.$textbox_content.val());
      if (/^ *$/.test(content)) {
        this.$textbox_content.focus();
        return false;
      }
      ajax_params = {
        url: "" + URL_BASE + "api/item/update",
        type: 'post',
        dataType: 'json',
        data: {
          content: content
        },
        success: function(res, status, xhr) {
          var item;
          item = res.item;
          _this.reset();
          if (_this.manager != null) {
            _this.manager.add_item(item);
            return _this.$textbox_content.blur().focus();
          }
        },
        error: function(xhr, status) {}
      };
      return $.ajax(ajax_params);
    };

    Form.prototype.reset = function() {
      return this.$textbox_content.val('');
    };

    return Form;

  })();

  $(function() {
    window.inbox_form = new GTDme.Inbox.Form();
    inbox_form.manager = item_manager;
    return inbox_always.set_event_listener('submit_succeed', function(item, xhr) {
      item_manager.add_item(item);
      return inbox_form.$textbox_content.focus();
    });
  });

}).call(this);
