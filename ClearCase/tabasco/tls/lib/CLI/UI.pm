package CLI::UI;

use strict;
use Carp;
use ClearCase::Common::ClearPrompt('clearprompt');
use IO::File;
use POSIX;
use Data;
use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
   $VERSION = '0.01';
   require Exporter;

   @ISA = qw(Exporter Data);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

} # sub BEGIN()

sub new()
{
   my $proto = shift;
   my $class = ref ($proto) || $proto;
   my $self  = {};
   bless $self, $class;

   # initialize

   return $self;
} # new ()

sub ask {
   my $self = shift;
   my ( $question, $proposal, $multi_line, @other ) = $self->rearrange(
      [ 'QUESTION', 'PROPOSAL', 'MULTI_LINE' ],
      @_ );
   confess @other if @other;

   my @options;
   push @options, ('-default', "$proposal" ) if $proposal;
   push @options,  '-multi_line'             if $multi_line;

   my $rc = clearprompt('text', '-prompt', $question, '-pre', @options );
   return $rc;
} # ask

sub askYesNo {
   my $self=shift;
   my ( $question, $default, @other ) = $self->rearrange(
      [ 'QUESTION', 'DEFAULT' ],
      @_ );
   confess @other if @other;

   my $rc = clearprompt('yes_no', '-prompt', $question, '-mask', 'yes,no', '-default', $default, '-pre' );
   return $rc == 0;
} # askYesNo

sub findExecutable {
    my $self = shift;
    my $pname = shift;

    return undef unless ($pname);
    (-f "$pname") && (-x "$pname") && return $pname;
    my ($pp);
    foreach $pp (split (/:/, $ENV{PATH})) {
    my ($tpath) = "$pp/$pname";

    ( -e "$tpath" ) && ( -x "$tpath" ) && return $tpath;
    }
    return undef;
}

sub edit {
   my $self = shift;
   my ( $text, @other ) = $self->rearrange(
      [ 'TEXT' ],
      @_ );
   confess @other if @other;

   ###
   ### DETERMINE EDITOR
   ###
   my ( $display, $wineditor ) = ( $ENV{'DISPLAY'}, $ENV{'WINEDITOR'} );
   my $editor;

   if ( defined $display and defined $wineditor and defined( $self->findExecutable( $wineditor ))) {
      $editor = $wineditor;

   } else {
      $editor =
         defined( $self->findExecutable( $ENV{'EDITOR'} ))
         ?  $ENV{'EDITOR'}
         :  $CLI::Config::OS{ $^O }->{'EDITOR'};
   }

   ###
   ### CREATE TEMPORARY FILE
   ###
   my $tmpnam = POSIX::tmpnam();
   my $tmpfh  = IO::File->new( $tmpnam, O_WRONLY|O_CREAT|O_EXCL );

   if ( ref $text and ref $text eq 'ARRAY' ) {
      foreach( @$text ) {
         print $tmpfh $_, "\n";
      }

   } else {
      print $tmpfh $text;
   }

   $tmpfh->close();

   ###
   ### CALL THE EDITOR AND EVALUATE IF IT WAS SUCCESSFULL
   ###
   my $rc = system( "$editor $tmpnam" );
   $rc = int($rc/256);

   ### RETURN VALUE
   my @text = ();

   if ( $rc == 0 ) {
      ### O indicates success
      ###
      ### read tempfile
      $tmpfh  = IO::File->new( $tmpnam, O_RDONLY );
      @text = <$tmpfh>;
      $tmpfh->close();
      unlink $tmpnam;
   } else {
      unlink $tmpnam;
      Error( "Editor $editor returned failed exit status: $!\n" );
      CLI::Command::getInstance()->exitInstance( -1 );
   }
   return @text;
} # editFile

sub selectFromList {
   my $self=shift;
   my ( $question, $list, $unique, @other ) = $self->rearrange(
      [ 'QUESTION', 'LIST', 'UNIQUE' ],
      @_ );
   confess @other if @other;

   if ( $unique ) {
      Die ( 'Usage error!' . "\n" ) if wantarray();
   } else {
      Die ( 'Usage error!' . "\n" ) if not wantarray();
   }

   my @options;
   push @options, '-choices' unless $unique;
   my $rc  = clearprompt(
      'list',
      '-items', join ( ',', @$list ),
      '-prompt', $question,
      '-pre',
      @options );

   if ( $unique ) {
      # CANCEL
      return undef if $rc eq '';
      chomp $rc;
      return $rc;
   } else {
      if ( $rc ne '' ) {
         my @sel = split( /\n/, $rc );
         grep (chomp, @sel);
         @sel = grep(!m/^\s*$/, @sel);
         return @sel;
      } else {
         return ();
      }
   }


} # selectFromList

1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2001  Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com

=head1 SEE ALSO

=cut
