package ClearCase::Command::describe;

use strict;
use Carp;
use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;
   require Transaction::Command;

   @ISA = qw(Exporter Transaction::Command);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   %DATA = (
       Short    => undef,
       Format   => undef,
       Long     => undef,
       Ahl      => undef,
       Aat      => undef,
       Version  => undef,
       Local    => undef,
       Argv     => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );


} # sub BEGIN()


sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $argv, $short, $fmt, $ahl, $aat, $long, $version, $localquery, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION ARGV SHORT FMT AHL AAT LONG VERSION LOCALQUERY) ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setVersion($version);
   $self->setShort($short);
   $self->setAhl($ahl);
   $self->setAat($aat);
   $self->setFormat($fmt);
   $self->setLong($long);
   $self->setArgv( $argv );
   $self->setLocal( $localquery );

   return $self;
}

sub do_execute {
   my $self = shift;
   my @options = ();

   push @options, '-local' if $self->getLocal();
   push @options, '-s' if $self->getShort();
   push @options, '-l' if $self->getLong();
   push @options, '-ahl '. $self->getAhl() if $self->getAhl();
   push @options, '-aat '. $self->getAat() if $self->getAat();
   push @options, '-fmt '. $self->getFormat() if $self->getFormat();

   my $pathname = $self->getArgv();

   if( $self->getVersion() )
     {
      my $version = $self->getVersion();
      $pathname = $pathname . "\@\@" . $self->getVersion()
        if defined $version and $version ne '';
      ClearCase::Common::Cleartool::describe( @options, $pathname );
     }
   else
     {
       ClearCase::Common::Cleartool::describe( @options, $pathname );
     }
}

sub do_commit {
}

sub do_rollback {
}

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
