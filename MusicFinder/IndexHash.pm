package MusicFinder::IndexHash;
use strict;
use warnings;

use constant FUZ_FACTOR => 2;

sub hash {
    my $data = shift;
    my $str
        = 'H'
        . sprintf( "%03d", $data->[0] )
        . sprintf( "%03d", $data->[1] )
        . sprintf( "%03d", $data->[2] )
        . sprintf( "%04d", $data->[3] );
    return $str;
}

1;
