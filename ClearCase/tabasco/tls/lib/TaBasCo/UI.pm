package TaBasCo::UI;

use strict;
use Carp;
use ClearCase::Common::ClearPrompt qw(clearprompt clearprompt_dir +ERRORS);
use IO::File;
use POSIX;

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

sub okMessage
  {
    my $self = shift;
    my $message = shift;

    my $rc = clearprompt(qw(proceed -type ok), '-prompt', $message, '-pre');
    return $rc;
  }

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

sub selectDirectory
  {
    my $self = shift;
    my ( $question, $dir, @other ) = $self->rearrange(
						      [ 'QUESTION', 'DIRECTORY' ],
						      @_ );
    confess @other if @other;
    my $rc = clearprompt_dir( $dir, $question );
    return undef if( $rc eq '' );
    return $rc;
  }
sub selectFile
  {
   my $self=shift;
   my ( $question, $dir, @other ) = $self->rearrange(
      [ 'QUESTION', 'DIRECTORY' ],
      @_ );
   confess @other if @other;

   my $rc = clearprompt(
                        'file',
                        '-prompt', $question,
                        '-dir', $dir,
                        '-pre'
                       );
   return undef if( $rc eq '' );
   return $rc;
  }

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

 Copyright (C) 2007  Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com

=head1 SEE ALSO

=cut
