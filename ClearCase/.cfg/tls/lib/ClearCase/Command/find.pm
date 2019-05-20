package ClearCase::Command::find;

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
      Name     => undef,
      Print    => undef,
      Version  => undef,
      Element  => undef,
      NRecurse => undef,
      Directory=> undef,
      All      => undef,
      Branch   => undef,
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

   my ( $element, $transaction, $name, $print, $argv, $version, $nrecurse, $directory, $all, $branch, @other ) =
      $class->rearrange(
         [ 'ELEMENT', 'TRANSACTION', 'NAME', 'PRINT', 'ARGV',
           'VERSION', 'NRECURSE', 'DIRECTORY', 'ALL', 'BRANCH' ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setName($name);
   $self->setPrint($print);
   $self->setVersion($version);
   $self->setElement($element);
   $self->setNRecurse($nrecurse);
   $self->setDirectory($directory);
   $self->setAll($all);
   $self->setBranch( $branch );
   $self->setArgv($argv);
   return $self;
}

sub do_execute {
   my $self = shift;
   my @options = ();

   push @options, $self->getArgv()                      if $self->getArgv();
   push @options, '-all'                                    if $self->getAll();
   push @options, '-element \'' . $self->getElement() .'\'' if $self->getElement();
   push @options, '-branch \'' . $self->getBranch() .'\''   if $self->getBranch();
   push @options, '-version \'' . $self->getVersion() .'\'' if $self->getVersion();
   push @options, '-name ' . $self->getName()               if $self->getName();
   push @options, '-print'                                  if $self->getPrint();
   push @options, '-nrecurse'                               if $self->getNRecurse();
   push @options, '-directory'                              if $self->getDirectory();

   ClearCase::Common::Cleartool::find(
      @options );
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
