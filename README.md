# NAME

Test::MockServer::Postgresql - A Postgresql mock server for testing perl programs

# SYNOPSIS

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

# DESCRIPTION

Test::MockServer::Postgresql run the postgres container on the Docker, for testing your perl programs.

**\*\*NOTE\*\*** Maybe this module doesn't work on the Windows, because this module uses some backticks for use the Docker.

# OPTIONS FOR CONSTRACTOR

- distro (int)

    A distribution name of container OS. You may specify "debian" or "alpine". Default is "debian".

- version (str)

    A version number of the PostgreSQL. Default is 12. 

# REQUIREMENT

- Docker

    This module uses the Docker as ephemeral environment.

# LICENSE

Copyright (C) Satoshi Azuma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Satoshi Azuma <ytnobody@gmail.com>

# SEE ALSO

[https://hub.docker.com/\_/postgres](https://hub.docker.com/_/postgres)
