package MusicFinder::DbSaveWorker;
use Moose;
use MusicFinder::IndexHash;
use namespace::autoclean;

with 'MusicFinder::Worker';

has 'seq' => (
    is  => 'rw',
    isa => 'Int',
);

has 'song' => (
    is  => 'rw',
    isa => 'Str',
);

sub initialize {
    my $self = shift;
    $self->redis->flushdb;
    $self->mongo->audio_db->song->remove( {} );
}

sub add_song {
    my ( $self, $song_name ) = @_;
    $self->mongo->audio_db->song->insert(
        { no => $self->seq, name => $song_name } );
}

sub work {
    my ( $self, $offset, $data ) = @_;
    my $s = $self->seq;
    $self->redis->rpush( MusicFinder::IndexHash::hash($data),
        "$offset|$s", sub { } )
        ; # third arg, sub {} means 'Do async', but it seems not to boost much.
}

__PACKAGE__->meta->make_immutable;
1;
