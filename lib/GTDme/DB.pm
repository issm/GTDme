package GTDme::DB;
use parent 'Teng';
__PACKAGE__->load_plugin('Utils');
__PACKAGE__->load_plugin('Resultset');
1;

package GTDme::DB::Schema;
use Teng::Schema::Declare;
table {
    name 'gtd_item';
    pk 'item_id';
    columns (
        {name => 't_done', type => 4},
        {name => 'ord', type => 4},
        {name => 't_up', type => 4},
        {name => 'content', type => 12},
        {name => 'step_attain', type => 12},
        {name => 'item_id', type => 4},
        {name => 'step', type => 4},
        {name => 'flg_del', type => 4},
        {name => 't_add', type => 4},
        {name => 'belongs', type => 12},
        {name => 'user_id', type => 4},
        {name => 'project_id', type => 4},
        {name => 'raw_text', type => 12},
    );
};

table {
    name 'gtd_item_2_tag';
    pk 'tag_id','item_id';
    columns (
        {name => 'item_id', type => 4},
        {name => 'tag_id', type => 4},
    );
};

table {
    name 'gtd_item_options';
    pk 'item_id';
    columns (
        {name => 'wday', type => 4},
        {name => 'item_id', type => 4},
        {name => 't_end', type => 4},
        {name => 't_start', type => 4},
        {name => 'mwday', type => 4},
        {name => 'mday', type => 4},
    );
};

table {
    name 'gtd_project';
    pk 'project_id';
    columns (
        {name => 't_done', type => 4},
        {name => 'ord', type => 4},
        {name => 't_up', type => 4},
        {name => 'name', type => 12},
        {name => 'description', type => 12},
        {name => 'flg_del', type => 4},
        {name => 't_add', type => 4},
        {name => 'user_id', type => 4},
        {name => 'code', type => 12},
        {name => 'project_id', type => 4},
    );
};

table {
    name 'gtd_tag';
    pk 'tag_id';
    columns (
        {name => 't_up', type => 4},
        {name => 'name', type => 12},
        {name => 't_add', type => 4},
        {name => 'user_id', type => 4},
        {name => 'tag_id', type => 4},
    );
};

table {
    name 'gtd_user';
    pk 'user_id';
    columns (
        {name => 'service_type', type => 1},
        {name => 'nickname', type => 1},
        {name => 'service_user_id', type => 1},
        {name => 't_up', type => 4},
        {name => 'flg_del', type => 4},
        {name => 't_add', type => 4},
        {name => 'user_id', type => 4},
        {name => 'apikey', type => 1},
    );
};

table {
    name 'sessions';
    pk 'id';
    columns (
        {name => 'session_data', type => 12},
        {name => 'id', type => 1},
    );
};

1;

