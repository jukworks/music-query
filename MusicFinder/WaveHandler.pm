package MusicFinder::WaveHandler;
use PDL::Core;
use PDL::Ufunc;
use PDL::FFTW;
use Time::HiRes qw/time/;    # for measuring query time
use Moose;
use MusicFinder::Worker;
use namespace::autoclean;

use constant CHUNK_SIZE => 4096;
use constant WINDOW     => 8;

has 'worker' => (
    is       => 'ro',
    isa      => 'MusicFinder::Worker',
    required => 1,
);

sub handle {
    my ( $self, $fn ) = @_;
    open my $fh, "< $fn" or die "No file like that.";
    binmode $fh;

    my $buf;
    read $fh, $buf, 12;
    my ( $chunk_id, $chunk_size, $chunk_format ) = unpack "A4 I A4", $buf;
    return "Not a WAVE file."
      unless $chunk_id eq 'RIFF'
        or $chunk_format eq 'WAVE';
    
    read $fh, $buf, 8;
    my ( $sub_chunk1_id, $sub_chunk1_size ) = unpack "A4 I", $buf;
    return "Bad Wave Format." unless $sub_chunk1_id eq 'fmt';

    read $fh, $buf, $sub_chunk1_size;
    my ($audio_format, $num_channels, $sample_rate,
        $byte_rate,    $block_align,  $bits_per_sample
    ) = unpack "S S I I S S", $buf;
    return "This is not a PCM file."          unless $audio_format == 1;
    return "Only mono wave can be accepted." unless $num_channels == 1;
    return "Sample rate must be 32000."      unless $sample_rate == 32000;
    return "Bits per sample must be 16."     unless $bits_per_sample == 16;

    read $fh, $buf, 8;
    my ( $sub_chunk2_id, $sub_chunk2_size ) = unpack "A4 I", $buf;
    return $sub_chunk2_id unless $sub_chunk2_id eq 'data';

    my @samples = ();
    my $count   = 0;

    my $nelem = undef;
    my ( $first, $second, $third );
    my ( $slice_str1, $slice_str2, $slice_str3, $slice_str4 );

    load_wisdom('.fftwisdom');
    my $window_seek = -( CHUNK_SIZE * ( WINDOW - 1 ) / WINDOW );
    my $offset = 0;
    my $start_time = time;
    while ( ( read $fh, $buf, 2 ) == 2 ) { # sample size: 2 (16 bit = 2 bytes)
        my $data = unpack "s", $buf;
        push @samples, $data;
        $count += 2;

        if ( $count == CHUNK_SIZE ) {      # a CHUNK is filled.
            my $pdl = pdl @samples;
            my $fft = rfftw $pdl;
            my $r   = $fft->slice('1')->transpose->abs->long;

            unless ( defined $nelem ) {
                $nelem      = $r->nelem unless defined $nelem;
                $first      = int( $nelem / 4 ) - 1;
                $second     = int( $nelem / 2 ) - 1;
                $third      = int( $nelem / 4 * 3 ) - 1;
                $slice_str1 = "0:$first";
                $slice_str2 = ( $first + 1 ) . ":" . $second;
                $slice_str3 = ( $second + 1 ) . ":" . $third;
                $slice_str4 = ( $third + 1 ) . ":" . ( $nelem - 1 );
            }

            my $bucket = [
                ( maximum_ind( $r->slice($slice_str1) ) + 0 )->at(0),
                ( maximum_ind( $r->slice($slice_str2) ) + $first + 1 )->at(0),
                ( maximum_ind( $r->slice($slice_str3) ) + $second + 1 )
                    ->at(0),
                ( maximum_ind( $r->slice($slice_str4) ) + $third + 1 )->at(0),
            ];
            my $w = $self->worker;
            $w->work( $offset, $bucket );

            # re-gather samples
            @samples = ();
            $count   = 0;
            seek $fh, $window_seek,
                1;    # third arg 1 means SEEK_CUR (current position)
	    $offset++;
        }
    }
    return "Done: " . (time - $start_time) . " seconds.";
}

__PACKAGE__->meta->make_immutable;
1;
