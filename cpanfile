requires 'perl', '5.008001';
requires 'DBI';
requires 'DBD::Pg';
requires 'Sub::Retry';
requires 'Net::EmptyPort';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

