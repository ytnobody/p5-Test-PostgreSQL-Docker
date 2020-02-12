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
    bless {
        oid     => int(rand(100000000)),
        version => $opts{version} || "12", 
        distro  => $opts{distro} || "debian",
        port    => empty_port(),
        host    => "127.0.0.1",
        user    => "admin",
        pass    => "admin",
        dbname  => "admin",
    }, $class;
}

sub pull {
    my ($self) = @_;
    my $image = $self->image_name();
    `docker pull --quiet $image`;
    $self;
}

sub run {
    my ($self) = @_;
    $self->pull();

    my $image = $self->image_name();
    my $ctname = $self->container_name();
    $self->{cleanup} = guard {
        $self->{dbh}->disconnect() if defined $self->{dbh};
        `docker kill $ctname`;
    };

    my $host = $self->{host};
    my $user = $self->{user};
    my $pass = $self->{pass};
    my $port = $self->{port};
    my $dbname = $self->{dbname};
    `docker run --rm --name $ctname -p $host:$port:5432 -e POSTGRES_USER=$user -e POSTGRES_PASSWORD=$pass -e POSTGRES_DB=$dbname -d $image`;
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
    my ($self) = @_;
    sprintf "dbi:Pg:dbname=%s;host=%s;port=%s", $self->{dbname}, $self->{host}, $self->{port};
}

sub dbh {
    my ($self, $option) = @_;
    return $self->{dbh} if $self->{dbh};

    $option ||= {AutoCommit => 0, RaiseError => 1, PrintError => 0};
    $self->{dbh} = retry 5, 2, sub {
        DBI->connect($self->dsn, $self->{user}, $self->{pass}, $option);
    };
    $self->{dbh};
}

sub container_name {
    my ($self) = @_;
    sprintf "postgres-%s-%s-%08d", $self->{version}, $self->{distro}, $self->{oid};
}

sub image_name {
    my ($self) = @_;
    my $distro_part = $self->{distro} eq "alpine" ? "-alpine" : "";
    sprintf "postgres:%s%s", $self->{version}, $distro_part;
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::MockServer::Postgresql - A Postgresql mock server for testing perl programs

=head1 SYNOPSIS

    use Test::More;
    use Test::MockServer::Postgresql;
    
    # raunch a container from postgres:12-alpine image
    my $server = Test::MockServer::Postgresql->new(version => 12, distro => "alpine");
    $server->run();
    
    # puke initialization data into postgresql on a container
    $server->fixture("/path/to/fixture.sql");
    
    # get a Database Handler(a DBI::db object) from mock server object
    my $dbh = $server->dbh();
    my $sth = $dbh->prepare("SELECT * FROM Users WHERE id=?");
    $sth->execute(1);
    
    # put your own test code below
    my $row $sth->fetchrow_hashref();
    is $row->{name}, "ytnobody";
    
    done_testing;

=head1 DESCRIPTION

Test::MockServer::Postgresql run the postgres container on the Docker, for testing your perl programs.

B<**NOTE**> Maybe this module doesn't work on the Windows, because this module uses some backticks for use the Docker.

=head1 OPTIONS FOR CONSTRACTOR

=over 2

=item distro (int)

A distribution name of container OS. You may specify "debian" or "alpine". Default is "debian".

=item version (str)

A version number of the PostgreSQL. Default is 12. 

=back

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

