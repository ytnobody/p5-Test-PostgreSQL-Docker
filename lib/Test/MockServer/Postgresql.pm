package Test::MockServer::Postgresql;
use 5.008001;
use strict;
use warnings;
use Guard qw/guard/;
use DBI;
use DBD::Pg;
use Sub::Retry qw/retry/;
use Net::EmptyPort qw/empty_port/;

our $VERSION = "0.01";

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        pgname  => "postgres",
        tag     => 'latest',
        port    => empty_port(),
        host    => "127.0.0.1",
        dbowner => "postgres",
        password=> "postgres",
        dbname  => "test",
        %opts,
    }, $class;
    $self->oid;
    return $self;
}

sub oid {
    my ( $self ) = @_;
    return $self->{oid} if defined $self->{oid};
    $self->{oid} = ("$self" =~ /HASH\(0x([0-9a-f]+)\)/)[0];
}

sub pull {
    my ($self) = @_;
    my $image = $self->image_name();
    `docker pull --quiet $image`;
    $self;
}

sub run {
    my ($self, %opt) = @_;
    $self->pull() unless (exists $opt{skip_pull} ? $opt{skip_pull} : 1);

    my $image = $self->image_name();
    my $ctname = $self->container_name();
    $self->{cleanup} = guard {
        $self->{dbh}->disconnect() if defined $self->{dbh};
        `docker kill $ctname`;
    };

    my $host = $self->{host};
    my $user = $self->{dbowner};
    my $pass = $self->{password};
    my $port = $self->{port};
    my $dbname = $self->{dbname};
    `docker run --rm --name $ctname -p $host:$port:5432 -e POSTGRES_USER=$user -e POSTGRES_PASSWORD=$pass -e POSTGRES_DB=$dbname -d $image`;

    $self->dbh unless $opt{skip_connect};
    $self;
}

sub fixture {
    my ($self, $filepath) = @_;
    my $dbh = $self->dbh(); ## waiting for DB connection
    my $ctname = $self->container_name();
    my $dbname = $self->{dbname};
    my $user = $self->{user};
    `docker exec -i $ctname psql -h localhost -p 5432 -U $user $dbname < $filepath`;
    $self;
}

sub dsn {
    my ($self, %args) = @_;
    $args{port}     ||= $self->{port};
    $args{host}     ||= $self->{host};
    $args{user}     ||= $self->{dbowner};
    $args{dbname}   ||= $self->{dbname};
    $args{password} ||= $self->{password};
    return 'DBI:Pg:' . join(';', map { "$_=$args{$_}" } sort keys %args);
}

sub dbh {
    my ($self, $option) = @_;
    return $self->{dbh} if $self->{dbh};

    $option ||= {AutoCommit => 0, RaiseError => 1, PrintError => 0};
    $self->{dbh} = retry 5, 2, sub {
        DBI->connect($self->dsn, '', '', $option);
    };
    $self->{dbh};
}

sub port {
    shift->{port};
}

sub container_name {
    my ($self) = @_;
    sprintf "%s-%s-%s", $self->{pgname}, $self->{tag}, $self->oid;
}

sub image_name {
    my ($self) = @_;
    sprintf "%s:%s", $self->{pgname}, $self->{tag};
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::MockServer::Postgresql - A Postgresql mock server for testing perl programs

=head1 SYNOPSIS

    use Test::More;
    use Test::MockServer::Postgresql;
    
    # 1. create a instance of Test::MockServer::Postgresql with postgres:12-alpine image
    my $server = Test::MockServer::Postgresql->new(tag => '12-alpine');
    
    # 2. create/run a container
    $server->run();
    
    # 3. puke initialization data into postgresql on a container
    $server->fixture("/path/to/fixture.sql");
    
    # 4. get a Database Handler(a DBI::db object) from mock server object
    my $dbh = $server->dbh();
    
    # (or call steps of 2 to 4 as method-chain)
    my $dbh = $server->run->fixture("/path/to/fixture.sql")->dbh;
    
    # 5. query to database
    my $sth = $dbh->prepare("SELECT * FROM Users WHERE id=?");
    $sth->execute(1);
    
    # 6. put your own test code below
    my $row $sth->fetchrow_hashref();
    is $row->{name}, "ytnobody";
    
    done_testing;

=head1 DESCRIPTION

Test::MockServer::Postgresql run the postgres container on the Docker, for testing your perl programs.

B<**NOTE**> Maybe this module doesn't work on the Windows, because this module uses some backticks for use the Docker.


=head1 METHODS

=head2 new

    $server = Test::MockServer::Postgresql->new(%opt)

=over 2

=item pgname (str)

A distribution name. Default is C<postgres>.

=item tag (str)

A tag of the PostgreSQL. Default is C<latest>. 

=item dbowner (str)

Default is C<postgres>.

=item password (str)

Default is C<postgres>.

=item dbname (str)

Default is C<test>.

=back

=head2 run

    $server = $server->run(%opt)

1. Check image with C<docker pull>.

2. C<docker run>

3. C<connect database>

=over 2

=item skip_pull (bool)

Skip image check. Default is C<true>.

=item skip_connect (bool)

Skip connect database. Default is C<false>.

=back

=head2 oid

    $oid = $server->oid()

Return an unique id.


=head2 dsn

    $dsn = $server->dsn(%opt)

=head2 port

    $port = $server->port()

Return a PostgreSQL server port.


=head2 dbh

    $dbh = $server->dbh()


=head2 fixture

    $server = $server->fixture($path)


=head1 REQUIREMENT

=over 2

=item Docker

This module uses the Docker as ephemeral environment.

=back

=head1 LICENSE

Copyright (C) Satoshi Azuma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Satoshi Azuma E<lt>ytnobody@gmail.comE<gt>

=head1 SEE ALSO

L<https://hub.docker.com/_/postgres>

=cut

