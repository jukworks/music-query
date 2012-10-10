#!/usr/bin/perl
use strict;
use warnings;

use MusicFinder::WaveHandler;
use MusicFinder::DbLoadWorker;

my $worker = MusicFinder::DbLoadWorker->new;
my $wh     = MusicFinder::WaveHandler->new( { worker => $worker } );
my $fn     = $ARGV[0] || './query.wav';

print $wh->handle($fn), "\n";

my %vote = %{ $worker->points };
binmode STDOUT, ":utf8";     # show Korean titles
for my $song ( sort { $vote{$b} <=> $vote{$a} } keys %vote )
{                            # show songs that get much points first
    printf "%4d points: %s\n", $vote{$song}, $worker->get_song($song);
}
