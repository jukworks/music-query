package MusicFinder::DbLoadWorker;
use Moose;
use MusicFinder::IndexHash;
use namespace::autoclean;

with 'MusicFinder::Worker';

has 'points' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {}; },
);

sub get_song {
    my ( $self, $song_id ) = @_;
    my $cs = $self->mongo->audio_db->song->find_one( {no => int($song_id) });
    return "No such song" unless defined $cs;
    return $cs->{name};
}

sub work {
    my ( $self, $q_offset, $data ) = @_;
    my @cs = $self->redis->lrange( MusicFinder::IndexHash::hash($data), 0, -1 );
    for (@cs) {
        my ( $s_offset, $song ) = split /\|/, $_;
        printf "Song ID: %3d, Offset: %6d\n", $song, $s_offset;
        $self->points->{$song}++;
    }
}

__PACKAGE__->meta->make_immutable;
1;
