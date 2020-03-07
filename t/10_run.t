use strict;
use warnings;
use Test::More;
use Test::MockServer::Postgresql;
use File::Spec;

my $server = Test::MockServer::Postgresql->new(tag => '12-alpine');
isa_ok($server, "Test::MockServer::Postgresql");
can_ok($server, qw/pull run fixture dbh dsn container_name image_name/);

my $fixture_file = File::Spec->catfile(qw/t data fixture.sql/);

my $dbh = $server
    ->run()
    ->fixture($fixture_file)
    ->dbh();
isa_ok $dbh, "DBI::db";

my $sth = $dbh->prepare('SELECT * FROM Users');
$sth->execute();

my $res = $sth->fetchall_hashref('account_id');
is_deeply($res, {'1' => {
    'account_id' => 1,
    'account_name' => 'ytnobody',
    'email' => 'ytnobody@gmail.com',
    'password' => 'hogehoge'
}});

done_testing;