package ClearCase::Command::setcs;

use strict;
use Carp;

use File::Temp;
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
      CSpec    => undef,
      OldCSpec => undef,
      Current  => undef,
      ViewTag  => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()



sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $cspec, $current, $tag, @other ) =
      $class->rearrange(
         [ 'TRANSACTION', 'CSPEC', 'CURRENT' , 'TAG' ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( @_ );
   bless $self, $class;

   $self->setCSpec( $cspec );
   $self->setCurrent( $current );
   $self->setViewTag( $tag );

   return $self;
}

sub do_execute {
   my $self = shift;
   my @options;
   my $file;

   # we go and save the old config spec
   ClearCase::Common::Cleartool::catcs( -tag => $self->getViewTag() );

   $self->setOldCSpec( join( '', ClearCase::Common::Cleartool::getOutput() ));

   push @options, '-tag ' . $self->getViewTag() if $self->getViewTag();

   # 'cleartool setcs' need the new config spec in a file.
   if( defined $self->getCSpec() )
   {
      $file = File::Temp::mktemp($OS::Common::Config::tempDir . $OS::Common::Config::slash . "newcspecXXXXX");
      open FILE, ">$file";
      print FILE $self->getCSpec();
      close FILE;

      push @options, $file;
   }

   push @options, '-current'  if $self->getCurrent();

   ClearCase::Common::Cleartool::setcs(
      @options
   );
   unlink $file;  
}

sub do_commit {
# nothing to do
}

sub do_rollback {
   my $self = shift;

   # we can only roll back setting a new config spec. subsequent 'setcs
   # -current' can not be undone.
   # 'cleartool setcs' need the new config spec in a file.
   if( defined $self->getOldCSpec() )
   {
      my $file = File::Temp::mktemp($OS::Common::Config::tempDir . $OS::Common::Config::slash ."oldcspecXXXXX");
      open FILE, ">$file";
      print FILE $self->getOldCSpec();
      close FILE;

      my @options = ();
      push @options, '-tag ' . $self->getViewTag() if $self->getViewTag();
      push @options, $file;
      ClearCase::Common::Cleartool::setcs( @options );  
      unlink $file;
   }
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
