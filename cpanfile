requires 'perl', '5.014';
requires 'Guard';
requires 'DBI';
requires 'DBD::Pg';
requires 'Sub::Retry';
requires 'Net::EmptyPort';
requires 'IPC::Run';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

