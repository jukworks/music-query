#!/usr/bin/perl

use strict;
use warnings;

use File::Find;
use MusicFinder::WaveHandler;
use MusicFinder::DbAdapter;
use MusicFinder::DbSaveWorker;

use constant TARGETS => './db';
use constant SOX_FMT => '-s -b 16 -c 1 -r 32000';

my $worker = MusicFinder::DbSaveWorker->new;
my $wh = MusicFinder::WaveHandler->new( { worker => $worker } );

$worker->initialize;
my $seq = 1;
find( \&convert, TARGETS );

sub convert {
    return if /^\./;
    return unless /\.mp3$/;
    my ($fn) = /(.*)\.mp3$/;
    my $wav = "$fn.wav";
    print "Converting... ", $_, "\n";
    my $cmd = "sox '$_' " . SOX_FMT . " '$wav'";
    system($cmd);

    $worker->seq( $seq++ );
    $worker->add_song($fn);
    print $wh->handle($wav), "\n";

    unlink $wav;
}
