use strict;
use warnings;
use Test::More;
use Test::MockServer::Postgresql;

my %opt = (
    version => 12,
    distro => 'alpine',
    dbname => 'testdb',
    user   => 'foobar',
);

my $server = Test::MockServer::Postgresql->new(%opt);

ok $server->run(), "server is runing";

my $dsn = $server->dsn;


is $server->{user}, 'foobar';
like $dsn, qr/dbname=testdb/;


my $dbh = DBI->connect($server->dsn(dbname => 'template1'), '', '', {});

ok $dbh, 'create dbh by DBI';

done_testing;
