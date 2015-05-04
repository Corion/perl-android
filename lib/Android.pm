package Android;
use strict;
use vars qw($VERSION @EXPORT_OK);
use vars qw(@kill_pids);
use Carp qw(croak);

$VERSION= '0.01';

=head1 NAME

Android - Android system routines

=cut

@EXPORT_OK=qw(
    launch_activity
    input_event_fh
    decode_input_event
    send_input_event
    screenshot
);

=head1 Exportable functions

=head2 C<< launch_activity >>

  launch_activity( 'http://www.google.com' );

Launches an activity. Currently, no metadata is passed
on. This is intended to change.

=cut

sub launch_activity {
    my( $activity, %options )= @_;
    system('am','start', $activity);
}

=head2 C<< input_event_fh >>

  my ($fh)= input_event_fh();

This needs root access.

Returns the process id and a filehandle from which all input events can be
read. This will C<croak> if the child process cannot be launched.
The child process will be automatically killed at the end of the program.

Currently, no selection of the specific input device is possible.

See also C<decode_input_event>.

=cut

sub input_event_fh {
    my(%options)= @_;
    my $command= 'su root getevent -l';
    my $pid = open my $fh, '<', "$command |"
        or croak "Couldn't launch $command: $!";
    push @kill_pids, $pid;
    $fh
}

END {
    # Cleanup
    kill -9, @kill_pids;
}

=head2 C<< decode_input_event >>

    my $input_events= input_event_fh();
    my $input= < $input_events >;
    my $ev= decode_input_event($input);

This will decode one line of sensor input. It returns a hash with the four
keys C<device>, C<type>, C<subtype> and C<value>. The interpretation
of C<value> varies between the device and types.

=cut

sub decode_input_event {
    my( $line )= @_;
    return unless $line =~ /\S/;
    $line =~ m!(.*?):\s+(\w+)\s+(\w+)\s+([a-fA-F0-9]+)$!
        or warn "Unknown line format [$line]";
    return +{
        device => $1,
        type => $2,
        subtype => $3,
        value => unpack 'H8', $4
    };
};

=head2 C<< send_input_event >>

  send_input_event(
      command => 'tap',
      args => [10,10],
      device => 'touchscreen',
  );

Sends an input event.

This needs root access.

Valid commands are

=over 4

=item *

C<text> - arguments: string

=item *

C<keyevent> - arguments: key code number or name

=item *

C<tap> - arguments: x, y

=item *

C<swipe> - arguments: x1, y1, x2, y2

=item *

C<press> - arguments: none

=item *

C<roll> - arguments: dx, dy

=back

=cut

sub send_input_event {
    my( %options )= @_;
    my @command= qw(su root input );
    if( $options{ device } ) {
        push @command, $options{ device };
    };
    push @command, $options{ command };
    if( $options{ args } ) {
        push @command, @{ $options{ args } };
    };
    system( @command );
}

=head2 C<< screenshot >>

  screenshot('/sdcard/image.png');

Takes a screenshot and saves it as a file.

This needs root.

=cut

sub screenshot {
    my( $filename, %options )= @_;
    my @command= qw(su root screencap -p );
    push @command, $filename;
    system( @command );
}

=head2 C<< vibrate >>

Triggers the vibrator of the device. Higher values mean longer duration.

=cut

sub vibrate {
    my( $duration, %options ) = @_;
    $options{ device } ||= '/sys/devices/virtual/timed_output/vibrator/enable';
    open my $vibrator, '>', $options{ device }
      or die "Couldn't write to '$options{ device }': $!";
    print $vibrator "$duration\n";
};

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/perl-android>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 TALKS

I've given a talk that featured this module at Perl conferences:

L<German Perl Workshop 2015, German|http://corion.net/talks/perl-on-android/perl-on-android-de.html>

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Android>
or via mail to L<android-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2015 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
