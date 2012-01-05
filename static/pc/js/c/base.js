(function() {
  var __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  window.GTDme = {};

  /*
   *
   *  GTDme.ItemsFilteredBy
   *
  */

  GTDme.ItemsFilteredBy = {
    belongs: null,
    project_id: null,
    tag: null
  };

  /*
   *
   *  GTDme.InboxAlways - Inbox anywhere
   *
  */

  GTDme.InboxAlways = (function() {

    function InboxAlways(params) {
      var _this = this;
      if (params == null) params = {};
      this._screen;
      this._form_shoed = false;
      this._event_handler = {
        submit_succeed: null,
        submit_error: null
      };
      this.$ = $('#inbox-always');
      this.$form = this.$.find('form');
      this.$textbox_content = this.$form.find('input[name="content"]');
      this.$button_cancel = this.$form.find('a.button-cancel');
      this.$button_submit = this.$form.find('a.button-submit');
      this.$.click(function() {
        return false;
      });
      this.$.mouseover(function() {
        return _this.$textbox_content.focus();
      });
      this.$form.submit(function() {
        return false;
      });
      this.$textbox_content.keydown(function(ev) {
        switch (ev.keyCode) {
          case 13:
            return _this.submit();
          case 27:
            return _this.cancel();
        }
      });
      this.$button_cancel.click(function() {
        _this.cancel();
        return false;
      });
      this.$button_submit.click(function() {
        _this.submit();
        return false;
      });
    }

    InboxAlways.prototype.set_screen = function(screen) {
      return this._screen = screen;
    };

    InboxAlways.prototype.show = function() {
      var _ref;
      if ((_ref = this._screen) != null) _ref.show();
      this.$.show();
      this.$.css({
        left: parseInt(($(window).width() - this.$form.width()) / 2, 10) - parseInt(this.$.css('padding-left'), 10) - 2
      });
      this._form_showed = true;
      return this.$textbox_content.focus();
    };

    InboxAlways.prototype.hide = function() {
      var _ref;
      this.$.hide();
      if ((_ref = this._screen) != null) _ref.hide();
      return this._form_showed = false;
    };

    InboxAlways.prototype.cancel = function() {
      this.reset();
      return this.hide();
    };

    InboxAlways.prototype.submit = function() {
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
          _this.hide();
          if (typeof _this._event_handler.submit_succeed === 'function') {
            return _this._event_handler.submit_succeed(item, xhr);
          }
        },
        error: function(xhr, status) {
          if (typeof this._event_handler.submit_error === 'function') {
            return this._event_handler.submit_error(xhr);
          }
        }
      };
      return $.ajax(ajax_params);
    };

    InboxAlways.prototype.reset = function() {
      return this.$textbox_content.val('');
    };

    InboxAlways.prototype.set_event_listener = function(event_type, callback) {
      return this._event_handler[event_type] = callback;
    };

    InboxAlways.prototype.clear_event_listener = function(event_type) {
      return delete this._event_handler[event_type];
    };

    return InboxAlways;

  })();

  GTDme.ItemManager = (function() {

    function ItemManager() {
      this.$ = $('#items');
      this.$list = this.$.find('> ul');
      this.items = {};
      this.project_selector = new GTDme.Selector.Projects;
      this.api_url = {
        update: "" + URL_BASE + "api/item/update",
        update_step: "" + URL_BASE + "api/item/update_step",
        update_order: "" + URL_BASE + "api/item/update_order",
        mark_done: "" + URL_BASE + "api/item/mark_done"
      };
      this.router = new Router({
        connect: {
          '/step/([\+\-][0-9]+)/([0-9]+)': this._route_step,
          '/done/([0-9]+)': this._route_done,
          '/do_now/([0-9]+)': this._route_do_now,
          '/deliver/([^/]+)/([0-9]+)': this._route_deliver,
          '/edit/([0-9]+)': this._route_edit
        }
      });
    }

    ItemManager.prototype.setup = function() {
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

    ItemManager.prototype.add_item = function(item) {
      var $li, html;
      html = $('#jarty\\:items-item').jarty({
        i: item
      });
      $li = $(html);
      this._set_listener($li);
      $li.appendTo($('#items > ul'));
      return $li;
    };

    ItemManager.prototype.get_item = function(params) {
      var $item;
      if (params == null) params = {};
      $item;
      if ((params != null ? params.id : void 0) != null) {
        $item = $("#items-item\\:" + params.id);
      } else {
        return null;
      }
      if ($item.size() > 0) {
        return $item;
      } else {
        return null;
      }
    };

    ItemManager.prototype._update_item_order = function($item) {
      var ajax_data, ajax_params, item_id, item_id_next, item_id_prev, _ref, _ref2, _ref3, _ref4, _ref5;
      item_id = (_ref = $item.attr('id')) != null ? _ref.split(':')[1] : void 0;
      item_id_prev = (_ref2 = $item.prev()) != null ? (_ref3 = _ref2.attr('id')) != null ? _ref3.split(':')[1] : void 0 : void 0;
      item_id_next = (_ref4 = $item.next()) != null ? (_ref5 = _ref4.attr('id')) != null ? _ref5.split(':')[1] : void 0 : void 0;
      ajax_data = {
        id: item_id,
        id_prev: item_id_prev,
        id_next: item_id_next
      };
      if (GTDme.ItemsFilteredBy.belongs != null) {
        ajax_data.belongs = GTDme.ItemsFilteredBy.belongs;
      }
      if (GTDme.ItemsFilteredBy.project_id != null) {
        ajax_data.project_id = GTDme.ItemsFilteredBy.project_id;
      }
      if (GTDme.ItemsFilteredBy.tag != null) {
        ajax_data.tag = GTDme.ItemsFilteredBy.tag;
      }
      ajax_params = {
        url: this.api_url.update_order,
        type: 'post',
        dataType: 'json',
        data: ajax_data,
        success: function(res, status, xhr) {},
        error: function(xhr, status) {}
      };
      $.ajax(ajax_params);
      return true;
    };

    ItemManager.prototype._set_listener = function($item) {
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

    ItemManager.prototype._route_step = function(m) {
      var ajax_params, item_id, n,
        _this = this;
      n = m[0], item_id = m[1];
      ajax_params = {
        url: this.api_url.update_step,
        type: 'post',
        dataType: 'json',
        data: {
          id: item_id,
          n: n
        },
        success: function(res, status, xhr) {
          var item, _base;
          item = res.item;
          if ((_base = _this.items)[item_id] == null) {
            _base[item_id] = new GTDme.Item({
              id: item_id,
              manager: _this
            });
          }
          return _this.items[item.item_id]._update_view(item);
        },
        error: function(xhr, status) {}
      };
      $.ajax(ajax_params);
      return false;
    };

    ItemManager.prototype._route_done = function(m) {
      var ajax_params, item_id,
        _this = this;
      item_id = m[0];
      ajax_params = {
        url: this.api_url.mark_done,
        type: 'post',
        dataType: 'json',
        data: {
          id: item_id
        },
        success: function(res, status, xhr) {
          var $li;
          $li = _this.get_item({
            id: item_id
          });
          return $li.addClass("done").fadeOut(function() {
            return $(this).remove();
          });
        },
        error: function(xhr, status) {}
      };
      $.ajax(ajax_params);
      return false;
    };

    ItemManager.prototype._route_do_now = function(m) {
      var item_id, res;
      item_id = m[0];
      res = confirm('Have you done?');
      if (!res) return false;
      return this._route_done(m);
    };

    ItemManager.prototype._route_deliver = function(m) {
      var $src, item, item_id, method_name, target, _base, _ref,
        _this = this;
      target = m[0], item_id = m[1];
      if (target === 'project') {
        item = (_ref = (_base = this.items)[item_id]) != null ? _ref : _base[item_id] = new GTDme.Item({
          id: item_id,
          manager: this
        });
        $src = item.$.find(".menu ul li a[href^=\"#/deliver/project/\"]");
        this.project_selector.show({
          item: item,
          $src: $src,
          select: function(project) {},
          create: function(project) {
            return _this.deliver_simple(item_id, 'project');
          },
          assign: function(project) {
            var ajax_params;
            ajax_params = {
              url: _this.api_url.update,
              type: 'post',
              dataType: 'json',
              data: {
                id: item_id,
                project_id: project.id,
                belongs: 'project'
              },
              success: function(res, status, xhr) {
                var $li;
                $li = _this.get_item({
                  id: item_id
                });
                return $li.addClass("to_project").fadeOut(function() {
                  return $(this).remove();
                });
              },
              error: function(xhr, status) {}
            };
            return $.ajax(ajax_params);
          }
        });
        return false;
      }
      method_name = "deliver_" + target;
      if (this[method_name] != null) {
        this[method_name](item_id);
      } else {
        throw new Error("method GTDme.ItemManager#" + method_name + " is not defined.");
      }
      return false;
    };

    ItemManager.prototype._route_edit = function(m) {
      var item_id, _base;
      item_id = m[0];
      if ((_base = this.items)[item_id] == null) {
        _base[item_id] = new GTDme.Item({
          id: item_id,
          manager: this
        });
      }
      this.items[item_id].show_editor();
      return false;
    };

    ItemManager.prototype.deliver_simple = function(id, to) {
      var ajax_params,
        _this = this;
      ajax_params = {
        url: this.api_url.update,
        type: 'post',
        dataType: 'json',
        data: {
          id: id,
          belongs: to
        },
        success: function(res, status, xhr) {
          var $li;
          $li = _this.get_item({
            id: id
          });
          return $li.addClass("to_" + to).fadeOut(function() {
            return $(this).remove();
          });
        },
        error: function(xhr, status) {}
      };
      return $.ajax(ajax_params);
    };

    ItemManager.prototype.deliver_action = function(id) {
      return this.deliver_simple(id, 'action');
    };

    ItemManager.prototype.deliver_calendar = function(id) {
      return this.deliver_simple(id, 'calendar');
    };

    ItemManager.prototype.deliver_material = function(id) {
      return this.deliver_simple(id, 'material');
    };

    ItemManager.prototype.deliver_someday = function(id) {
      return this.deliver_simple(id, 'someday');
    };

    ItemManager.prototype.deliver_background = function(id) {
      return this.deliver_simple(id, 'background');
    };

    ItemManager.prototype.deliver_project = function(id) {
      return this.deliver_simple(id, 'project');
    };

    ItemManager.prototype.deliver_trash = function(id) {
      return this.deliver_simple(id, 'trash');
    };

    return ItemManager;

  })();

  GTDme.Item = (function() {

    function Item(params) {
      if (params == null) params = {};
      this.id = params.id;
      this.manager = params.manager;
      this.$ = $("#items-item\\:" + this.id);
      this.$content = this.$.find('.content');
      this.$editor = this.$.find('.editor');
      this.$options = this.$.find('.options');
      this.$steps = this.$.find('.steps');
      this.$editor_textbox_content = this.$editor.find('input[name="content"]');
      this.$editor_hidden_raw_text = this.$editor.find('input[name="raw_text"]');
      this.$editor_button_submit = this.$editor.find('a.button-submit');
      this.$editor_button_cancel = this.$editor.find('a.button-cancel');
    }

    Item.prototype.show_editor = function() {
      var _this = this;
      this.$content.hide();
      this.$editor.show();
      this.$editor_textbox_content.bind('keydown.edit', function(ev) {
        switch (ev.keyCode) {
          case 13:
            return _this.submit_edit();
          case 27:
            return _this.cancel_edit();
        }
      }).val($.trim(this.$editor_hidden_raw_text.val())).focus();
      this.$editor_button_submit.bind('click.edit', function() {
        _this.submit_edit();
        return false;
      });
      this.$editor_button_cancel.bind('click.edit', function() {
        _this.cancel_edit();
        return false;
      });
      return this.$.bind('mouseover.edit', function() {
        return _this.$editor_textbox_content.focus();
      });
    };

    Item.prototype.hide_editor = function() {
      this.$editor.hide();
      return this.$content.show();
    };

    Item.prototype.cancel_edit = function() {
      this.$editor_textbox_content.val('').unbind('keydown.edit');
      this.$editor_button_submit.unbind('click.edit');
      this.$editor_button_cancel.unbind('click.edit');
      this.$.unbind('mouseover.edit');
      return this.hide_editor();
    };

    Item.prototype.submit_edit = function() {
      var ajax_params, content_up,
        _this = this;
      content_up = $.trim(this.$editor_textbox_content.val());
      if (/^[ ]*$/.test(content_up)) return false;
      if (content_up === $.trim(this.$editor_hidden_raw_text.val())) {
        this.cancel_edit();
      }
      ajax_params = {
        url: this.manager.api_url.update,
        type: 'post',
        dataType: 'json',
        data: {
          id: this.id,
          content: content_up
        },
        success: function(res, status, xhr) {
          var item;
          item = res.item;
          _this._update_view(item);
          return _this.cancel_edit();
        },
        error: function(xhr, status) {
          return alert('error');
        }
      };
      return $.ajax(ajax_params);
    };

    Item.prototype._update_view = function(item) {
      var $html;
      this.$content.text(item.content);
      this.$editor_hidden_raw_text.val(item.raw_text);
      $html = $($('#jarty\\:items-item').jarty({
        i: item
      }));
      this.$options.html($html.find('.options').html());
      return this.$steps.html($html.find('.steps').html());
    };

    return Item;

  })();

  /*
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
  */

  this.Router = (function() {

    function Router(params) {
      var k, v, _ref, _ref2;
      if (params == null) params = {};
      this._rules = [];
      _ref2 = (_ref = params.connect) != null ? _ref : {};
      for (k in _ref2) {
        v = _ref2[k];
        this.connect(k, v);
      }
    }

    Router.prototype.connect = function(hash, action) {
      this._rules.push({
        hash: hash,
        action: action != null ? action : function() {}
      });
      return this;
    };

    Router.prototype.match = function(url_hash) {
      var a, h, i, m, r, re_h, ret, v, _len,
        _this = this;
      url_hash = url_hash.replace(new RegExp('^.*#!?'), '');
      r = this._rules;
      for (i = 0, _len = r.length; i < _len; i++) {
        v = r[i];
        h = v.hash;
        a = v.action;
        re_h = new RegExp(('^' + h + '$').replace(/^\^+/, '^').replace(/\$+$/, '$'));
        m = url_hash.match(re_h);
        if (m !== null) {
          ret = {
            hash: h,
            action: a,
            matched: m,
            run: function(o) {
              m.shift();
              return a.apply(o, [m]);
            }
          };
          break;
        }
      }
      if (!(ret != null)) {
        ret = {
          run: function(o) {
            return _this._cannot_route.apply(o, [url_hash]);
          }
        };
      }
      return ret;
    };

    Router.prototype._cannot_route = function(h) {
      throw new Error('cannot route: ' + h);
    };

    return Router;

  })();

  /*
   *
   *  GTDme.Selector -
   *
  */

  GTDme.Selector = (function() {

    function Selector(params) {
      if (params == null) params = {};
      this.router;
      this._cache;
      this._item;
      this._callback_select;
      this._callback_create;
      this._callback_assign;
      this.$;
      this.$head;
      this.$body;
      this.$foot;
      this.$loading;
      this.$list;
      this.$_src;
    }

    Selector.prototype.show = function(params) {
      var self;
      self = this;
      this.hide();
      this._item = params.item;
      this.$_src = params.$src;
      this._callback_select = params.select;
      this._callback_create = params.create;
      this._callback_assign = params.assign;
      this.$.show();
      this.$.css({
        top: this.$_src.offset().top - 80,
        left: this.$_src.offset().left - 400
      });
      this._item.$.addClass('hover');
      this.$loading.show();
      this.$button_cancel.bind('click.cancel', function() {
        return self.router.match($(this).attr('href')).run(self);
      });
      return this.load();
    };

    Selector.prototype.hide = function() {
      var _ref, _ref2;
      this.$.hide();
      this.$list.empty();
      this.$button_cancel.unbind('click.cancel');
      if ((_ref = this._item) != null) {
        if ((_ref2 = _ref.$) != null) _ref2.removeClass('hover');
      }
      delete this._item;
      return delete this.$_src;
    };

    Selector.prototype.load = function() {};

    Selector.prototype.update_view = function() {};

    return Selector;

  })();

  /*
   *
   *  GTDme.Selector.Projects -
   *
  */

  GTDme.Selector.Projects = (function(_super) {

    __extends(Projects, _super);

    function Projects(params) {
      if (params == null) params = {};
      Projects.__super__.constructor.call(this, params);
      this.$ = $('#selector-project');
      this.$head = this.$.find('> .head');
      this.$body = this.$.find('> .body');
      this.$foot = this.$.find('> .foot');
      this.$loading = this.$body.find('> .loading');
      this.$list = this.$body.find('> ul');
      this.$button_cancel = this.$foot.find('a.button-cancel');
      this.router = new Router({
        connect: {
          '/project/create': this._route_create,
          '/project/assign/([0-9]+)': this._route_assign,
          '/project/cancel': this._route_cancel
        }
      });
    }

    Projects.prototype.hide = function() {
      Projects.__super__.hide.call(this);
      delete this._callback_select;
      delete this._callback_create;
      return delete this._callback_assign;
    };

    Projects.prototype.load = function() {
      var ajax_params,
        _this = this;
      ajax_params = {
        url: "" + URL_BASE + "api/project/list?t=" + ((new Date()).getTime()),
        type: 'get',
        dataType: 'json',
        data: {},
        success: function(res, status, xhr) {
          _this.update_view(res.projects);
          return _this._cache = res.projects;
        },
        error: function(xhr, status) {}
      };
      if (this._cache != null) {
        return this.update_view(this._cache);
      } else {
        return $.ajax(ajax_params);
      }
    };

    Projects.prototype.update_view = function(projects) {
      var $jarty_template, html, self;
      self = this;
      html = $jarty_template = $('#jarty\\:selector-project-item').jarty({
        projects: projects
      });
      this.$loading.hide();
      this.$list.html(html);
      return this.$list.find('> li a').hover(function() {
        return $(this).bind('click.mouseover', function(ev) {
          var $a;
          $a = $(ev.target);
          return self.router.match($a.attr('href')).run(self);
        });
      }, function() {
        return $(this).unbind('click.mouseover');
      });
    };

    Projects.prototype._route_create = function(m) {
      var o;
      o = {
        id: null,
        type: 'create'
      };
      if (typeof this._callback_select === "function") this._callback_select(o);
      if (typeof this._callback_create === "function") this._callback_create(o);
      delete this._cache;
      this.hide();
      return false;
    };

    Projects.prototype._route_assign = function(m) {
      var o, project_id;
      project_id = m[0];
      o = {
        id: project_id,
        type: 'assign'
      };
      if (typeof this._callback_select === "function") this._callback_select(o);
      if (typeof this._callback_assign === "function") this._callback_assign(o);
      this.hide();
      return false;
    };

    Projects.prototype._route_cancel = function(m) {
      this.hide();
      return false;
    };

    return Projects;

  })(GTDme.Selector);

  /*
   *
   *  GTDme.Screen - Screen
   *
  */

  GTDme.Screen = (function() {

    function Screen(params) {
      var _ref,
        _this = this;
      if (params == null) params = {};
      this.parent = params.parent;
      this.$ = $('<div></div>').attr({
        id: (_ref = params.id) != null ? _ref : 'gtdme-global-screen'
      }).css({
        'position': 'absolute',
        'z-index': 99999,
        'top': -60,
        'left': 0,
        'width': 0,
        'height': 0,
        'background': '#000',
        'opacity': '.66'
      }).appendTo('body');
      if (typeof params.css === 'object') this.$.css(params.css);
      if (typeof params.click === 'function') {
        this.$.click(function(ev) {
          return params.click(_this, ev);
        });
      }
    }

    Screen.prototype.show = function() {
      return this.$.css({
        width: $(window).width(),
        height: $(window).height() + 60
      }).show();
    };

    Screen.prototype.hide = function() {
      return this.$.hide();
    };

    return Screen;

  })();

  window.add_jarty_filter = function(name, func) {
    var _ref, _ref2;
    name = name.replace(new RegExp('_(.)', 'g'), function(p, c) {
      return c.toUpperCase();
    });
    return typeof Jarty !== "undefined" && Jarty !== null ? (_ref = Jarty.Pipe) != null ? (_ref2 = _ref.prototype) != null ? _ref2[name] = func : void 0 : void 0 : void 0;
  };

  $(function() {
    window.inbox_always = new GTDme.InboxAlways;
    inbox_always.set_screen(new GTDme.Screen({
      parent: inbox_always,
      id: 'inbox-always-screen',
      click: function() {
        return inbox_always.hide();
      }
    }));
    $('#inbox-always-toggle a').click(function() {
      inbox_always.show();
      return false;
    });
    window.item_manager = new GTDme.ItemManager();
    item_manager.setup();
    return add_jarty_filter('split', function() {
      return this.value.split('::');
    });
  });

}).call(this);
