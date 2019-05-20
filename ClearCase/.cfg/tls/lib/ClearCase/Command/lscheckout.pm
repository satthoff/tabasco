package ClearCase::Command::lscheckout;

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
      CView       => undef,
      Me          => undef,
      Short       => undef,
      Dir         => undef,
      Recursive   => undef,
      All         => undef,
      BrType      => undef,
      Avobs       => undef,
      Long        => undef,
       Argv => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()



sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $argv, $dir, $short, $me, $cview, $recursive, $all, $brtype, $avobs, $long, @other ) =
      $class->rearrange(
         [  'TRANSACTION', 'ARGV', 'DIRECTORY', 'SHORT',
            'ME', 'CVIEW', 'RECURSIVE', 'ALL', 'BRTYPE', 'AVOBS', 'LONG' ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setAll( $all );
   $self->setDir( $dir );
   $self->setShort( $short );
   $self->setLong( $long );
   $self->setMe( $me );
   $self->setCView( $cview );
   $self->setRecursive( $recursive );
   $self->setBrType( $brtype );
   $self->setAvobs( $avobs );
   $self->setArgv($argv);

   return $self;
}

sub do_execute {
   my $self = shift;
   my @options = ();

   push @options , '-s'       if $self->getShort();
   push @options , '-l'       if $self->getLong();
   push @options , '-cview'   if $self->getCView();
   push @options , '-d'       if $self->getDir();
   push @options , '-me'      if $self->getMe();
   push @options , '-r'       if $self->getRecursive();
   push @options , '-all'     if $self->getAll();
   push @options , '-avobs'   if $self->getAvobs();
   push (@options , '-brtype ' . $self->getBrType()) if $self->getBrType();
   push @options, $self->getArgv() if( $self->getArgv() and ($self->getArgv() ne '') );

   ClearCase::Common::Cleartool::lscheckout(@options);
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
