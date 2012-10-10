package MusicFinder::Worker;
use Moose::Role;
use Redis;
use MongoDB;

requires 'work';

has 'redis' => (
    is      => 'ro',
    isa     => 'Redis',
    builder => '_redis_builder',
);

has 'mongo' => (
    is      => 'ro',
    isa     => 'MongoDB::Connection',
    builder => '_mongo_builder',
);

sub _redis_builder {
    my $r = Redis->new(encoding => undef);
    $r->select(1);
    $r;
}

sub _mongo_builder {
    MongoDB::Connection->new;
}

1;
