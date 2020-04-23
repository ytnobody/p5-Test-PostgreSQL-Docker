use strict;
use warnings;
use utf8;
use lib qw(t/lib);
use Test::More;
use t::Util;
use File::Spec;

my $server = t::Util->new_server(pgname => 'kazaoki/postgres-bigm', tag => '10-alpine');

unless ( $server->docker_is_running ) {
    plan skip_all => "docker is not running.";
    exit;
}

isa_ok($server, 'Test::PostgreSQL::Docker');
can_ok($server, qw/pull run psql_args run_psql run_psql_scripts oid dbh dsn container_name image_name
                                docker docker_daemon_is_accessible docker_is_running/);
my $fixture_file = File::Spec->catfile(qw/t data fixture_bigm.sql/);

my $dbh = $server
    ->run()
    ->run_psql_scripts($fixture_file)
    ->dbh();
isa_ok $dbh, "DBI::db";

my $sth = $dbh->prepare(q/SELECT * FROM Items WHERE note LIKE likequery(?)/);
$sth->execute('回復');

my $res = $sth->fetchall_hashref('id');
is_deeply($res, {
    '1' => {
        'id' => 1,
        'name' => 'やくそう',
        'note' => 'HPを30回復する'
    },
    '2' => {
        'id' => 2,
        'name' => 'どくけしそう',
        'note' => 'どくを回復する'
    },
});

$server->run_psql('-c', q|INSERT INTO Items (name, note) VALUES ('まんげつそう', 'マヒを回復する')|);
my ($new_id) = $dbh->selectrow_array(q/SELECT id FROM Items WHERE name='まんげつそう'/);
diag explain($new_id);

$sth = $dbh->prepare(q/SELECT * FROM Items WHERE note LIKE likequery(?)/);
$res = $sth->execute('回復');
is_deeply($res, {
    '1' => {
        'id' => 1,
        'name' => 'やくそう',
        'note' => 'HPを30回復する'
    },
    '2' => {
        'id' => 2,
        'name' => 'どくけしそう',
        'note' => 'どくを回復する'
    },
    "$new_id" => {
        'id' => "$new_id",
        'name' => 'まんげつそう',
        'note' => 'マヒを回復する'
    }
});

done_testing;
