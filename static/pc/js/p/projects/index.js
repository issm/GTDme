(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  GTDme.Projects = {};

  GTDme.Projects.Manager = (function() {

    function Manager() {
      this.$ = $('#projects');
      this.$list = this.$.find('> ul');
      this.projects = {};
      this.api_url = {
        update: "" + URL_BASE + "api/project/update",
        update_order: "" + URL_BASE + "api/project/update_order",
        mark_done: "" + URL_BASE + "api/project/mark_done"
      };
      this.router = new Router({
        connect: {
          '/done/([0-9]+)': this._route_done,
          '/do_now/([0-9]+)': this._route_do_now,
          '/deliver/([^/]+)/([0-9]+)': this._route_deliver,
          '/edit/([0-9]+)': this._route_edit
        }
      });
    }

    Manager.prototype.setup = function() {
      var self,
        _this = this;
      self = this;
      this.$list.find('> li').each(function() {
        return self._set_listener($(this));
      });
      return this.$list.sortable({
        handle: '.sort a',
        axis: 'y',
        placeholder: 'sortable_placeholder',
        update: function(ev, ui) {
          var $item_moved;
          $item_moved = ui.item;
          $item_moved.removeClass('being_dragged');
          _this._update_item_order($item_moved);
          return true;
        },
        start: function(ev, ui) {
          var $item;
          $item = ui.item;
          $item.addClass('being_dragged');
          return _this.$list.find('> li.sortable_placeholder').css({
            height: $item.height()
          });
        },
        stop: function(ev, ui) {
          var $item;
          $item = ui.item;
          return $item.removeClass('being_dragged');
        }
      });
    };

    Manager.prototype._set_listener = function($item) {
      var self;
      self = this;
      return $item.find('.menu').hover(function() {
        return $(this).bind('click.mouseover', function(ev) {
          var $a;
          $a = $(ev.target);
          return self.router.match($a.attr('href')).run(self);
        });
      }, function() {
        return $(this).unbind('click.mouseover');
      });
    };

    Manager.prototype._update_item_order = function($item) {
      var ajax_params, project_id, project_id_next, project_id_prev, _ref, _ref2, _ref3, _ref4, _ref5;
      project_id = (_ref = $item.attr('id')) != null ? _ref.split(':')[1] : void 0;
      project_id_prev = (_ref2 = $item.prev()) != null ? (_ref3 = _ref2.attr('id')) != null ? _ref3.split(':')[1] : void 0 : void 0;
      project_id_next = (_ref4 = $item.next()) != null ? (_ref5 = _ref4.attr('id')) != null ? _ref5.split(':')[1] : void 0 : void 0;
      ajax_params = {
        url: this.api_url.update_order,
        type: 'post',
        dataType: 'json',
        data: {
          id: project_id,
          id_prev: project_id_prev,
          id_next: project_id_next
        },
        success: function(res, status, xhr) {},
        error: function(xhr, status) {}
      };
      $.ajax(ajax_params);
      return true;
    };

    Manager.prototype._route_edit = function(m) {
      var project_id, _base;
      project_id = m[0];
      if ((_base = this.projects)[project_id] == null) {
        _base[project_id] = new GTDme.Project({
          id: project_id,
          manager: this
        });
      }
      this.projects[project_id].show_editor();
      return false;
    };

    return Manager;

  })();

  GTDme.Project = (function() {

    function Project(params) {
      if (params == null) params = {};
      this._handle_keydown_edit = __bind(this._handle_keydown_edit, this);
      this.id = params.id;
      this.manager = params.manager;
      this.$ = $("#projects-item\\:" + this.id);
      this.$name = this.$.find('.name');
      this.$code = this.$.find('.code');
      this.$description = this.$.find('.description');
      this.$editor = this.$.find('.editor');
      this.$editor_textbox_name = this.$editor.find('form input[name="name"]');
      this.$editor_textbox_code = this.$editor.find('form input[name="code"]');
      this.$editor_textbox_description = this.$editor.find('form input[name="description"]');
      this.$editor_button_submit = this.$editor.find('form a.button-submit');
      this.$editor_button_cancel = this.$editor.find('form a.button-cancel');
      this.$_editor_current_input = this.$editor_textbox_name;
    }

    Project.prototype._handle_keydown_edit = function(ev) {
      switch (ev.keyCode) {
        case 13:
          return this.submit_edit();
        case 27:
          return this.cancel_edit();
      }
    };

    Project.prototype.show_editor = function() {
      var _this = this;
      this.$name.hide();
      this.$description.hide();
      this.$editor.show();
      this.$editor_textbox_name.bind('keydown.edit', this._handle_keydown_edit).val($.trim(this.$name.text())).bind('focus.edit', function() {
        return _this.$_editor_current_input = _this.$editor_textbox_name;
      }).focus();
      this.$editor_textbox_code.bind('keydown.edit', this._handle_keydown_edit).bind('focus.edit', function() {
        return _this.$_editor_current_input = _this.$editor_textbox_code;
      });
      this.$editor_textbox_description.bind('keydown.edit', this._handle_keydown_edit).bind('focus.edit', function() {
        return _this.$_editor_current_input = _this.$editor_textbox_description;
      });
      this.$editor_button_submit.bind('click.edit', function() {
        _this.submit_edit();
        return false;
      });
      this.$editor_button_cancel.bind('click.edit', function() {
        _this.cancel_edit();
        return false;
      });
      this.$.bind('mouseover.edit', function() {
        return _this.$_editor_current_input.focus();
      });
      return this.$editor_textbox_name.focus();
    };

    Project.prototype.hide_editor = function() {
      this.$editor.hide();
      this.$name.show();
      return this.$description.show();
    };

    Project.prototype.validate_edit = function() {
      var valid, _code, _description, _name;
      _name = $.trim(this.$editor_textbox_name.val());
      _code = $.trim(this.$editor_textbox_code.val());
      _description = $.trim(this.$editor_textbox_description.val());
      valid = true;
      if (/^[ 　]*$/.test(_name)) valid = false;
      return valid;
    };

    Project.prototype.editor_next_input = function() {
      switch (this.$_editor_current_input) {
        case this.$editor_textbox_name:
          return this.$editor_textbox_code.focus();
        case this.$editor_textbox_code:
          return this.$editor_textbox_description.focus();
        case this.$editor_textbox_description:
          return this.$editor_textbox_name.focus();
      }
    };

    Project.prototype.cancel_edit = function() {
      this.$editor_textbox_name.val('').unbind('keydown.edit').unbind('focus.edit');
      this.$editor_textbox_code.unbind('keydown.edit').unbind('focus.edit');
      this.$editor_textbox_description.unbind('keydown.edit').unbind('focus.edit');
      this.$editor_button_submit.unbind('click.edit');
      this.$editor_button_cancel.unbind('click.edit');
      this.$.unbind('mouseover.edit');
      return this.hide_editor();
    };

    Project.prototype.submit_edit = function() {
      var ajax_params, code_up, description_up, name_up,
        _this = this;
      if (!this.validate_edit()) {
        this.editor_next_input();
        return false;
      }
      name_up = $.trim(this.$editor_textbox_name.val());
      code_up = $.trim(this.$editor_textbox_code.val());
      description_up = $.trim(this.$editor_textbox_description.val());
      if (/^[ ]*$/.test(name_up)) return false;
      ajax_params = {
        url: this.manager.api_url.update,
        type: 'post',
        dataType: 'json',
        data: {
          id: this.id,
          name: name_up,
          code: code_up,
          description: description_up
        },
        success: function(res, status, xhr) {
          var project;
          project = res.project;
          _this._update_view(project);
          return _this.cancel_edit();
        },
        error: function(xhr, status) {
          return alert('error');
        }
      };
      return $.ajax(ajax_params);
    };

    Project.prototype._update_view = function(project) {
      var $html;
      $html = $($('#jarty\\:projects-item').jarty({
        i: project
      }));
      this.$name.html($html.find('.name').html());
      this.$code.text(project.code);
      return this.$description.text(project.description);
    };

    return Project;

  })();

  GTDme.Projects.Form = (function() {

    function Form() {
      var _this = this;
      this.$ = $('#project-form');
      this.$form = this.$.find('form');
      this.$textbox_name = this.$form.find('input[name="name"]');
      this.$textbox_code = this.$form.find('input[name="code"]');
      this.$textbox_description = this.$form.find('input[name="description"]');
      this.$button_submit = this.$form.find('input[name="submit"]');
      this.$button_cancel = this.$form.find('input[name="cancel"]');
      this.$_current_input = this.$textbox_name;
      this.$textbox_name.focus(function() {
        return _this.$_current_input = _this.$textbox_name;
      });
      this.$textbox_code.focus(function() {
        return _this.$_current_input = _this.$textbox_code;
      });
      this.$textbox_description.focus(function() {
        return _this.$_current_input = _this.$textbox_description;
      });
      this.manager;
      this.$.mouseover(function() {
        return _this.$_current_input.focus();
      });
      this.$form.submit(function() {
        if (_this.$_current_input === _this.$textbox_description) {
          _this.submit();
        } else {
          _this.next_input();
        }
        return false;
      });
      this.$button_cancel.click(function() {
        return _this.reset();
      });
    }

    Form.prototype.validate = function() {
      var valid, _code, _description, _name;
      valid = true;
      _name = $.trim(this.$textbox_name.val());
      _code = $.trim(this.$textbox_code.val());
      _description = $.trim(this.$textbox_description.val());
      valid = true;
      if (/^[ 　]*$/.test(_name)) valid = false;
      if (/^[ 　]*$/.test(_code)) valid = false;
      return valid;
    };

    Form.prototype.next_input = function() {
      switch (this.$_current_input) {
        case this.$textbox_name:
          return this.$textbox_code.focus();
        case this.$textbox_code:
          return this.$textbox_description.focus();
        case this.$textbox_description:
          return this.$textbox_name.focus();
      }
    };

    Form.prototype.submit = function() {
      var ajax_params, _code, _description, _name,
        _this = this;
      if (!this.validate()) {
        this.next_input();
        return false;
      }
      _name = $.trim(this.$textbox_name.val());
      _code = $.trim(this.$textbox_code.val());
      _description = $.trim(this.$textbox_description.val());
      ajax_params = {
        url: "" + URL_BASE + "api/project/update",
        type: 'post',
        dataType: 'json',
        data: {
          name: _name,
          code: _code,
          description: _description
        },
        success: function(res, status, xhr) {
          var project;
          project = res.project;
          console.log(project);
          return _this.reset();
        },
        error: function(xhr, status) {}
      };
      $.ajax(ajax_params);
      return false;
    };

    Form.prototype.reset = function() {
      this.$textbox_description.val('');
      this.$textbox_code.val('');
      return this.$textbox_name.val('').focus();
    };

    return Form;

  })();

  $(function() {
    window.project_manager = new GTDme.Projects.Manager();
    project_manager.setup();
    window.project_form = new GTDme.Projects.Form();
    return project_form.manager = project_manager;
  });

}).call(this);
