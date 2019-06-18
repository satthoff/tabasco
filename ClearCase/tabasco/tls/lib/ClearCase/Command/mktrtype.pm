package ClearCase::Command::mktrtype;

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
      Comment  => undef,
      All      => undef,
      ExecU    => undef,
      ExecW    => undef,
      Cmd      => undef,
      NUsers   => undef,
      Restrict => undef,
      Element  => undef,
      Type     => undef,
      TypeList => undef

   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()

sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $name, $comment, $all, $execu, $execw, $cmd, $nusers, $element, $restrict, $type, $typelist, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION NAME COMMENT ALL EXECU EXECW COMMAND NUSERS ELEMENT RESTRICT TYPE TYPELIST) ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   # we expect the full name trtype:<trigger>@vob in variable name
   $self->setElement( $element );
   $self->setName( $name );
   $self->setExecU( $execu );
   $self->setNUsers( $nusers );
   $self->setExecW( $execw );
   $self->setCmd( $cmd );
   $self->setAll( $all );
   $self->setComment( $comment );
   $self->setRestrict( $restrict );
   $self->setType( $type );
   $self->setTypeList( $typelist );

   return $self;
}

sub do_execute {
   my $self = shift;

   my @options = ();

   if ( defined $self->getComment() )
   {
      push @options, ' -c "' . $self->getComment() . '"';
   }
   else
   {
      push @options, ' -nc';
   }

   push @options, '-type'                        if $self->getType();
   push @options, $self->getTypeList()           if $self->getTypeList();
   push @options, '-all'                         if $self->getAll();
   push @options, '-element'                     if $self->getElement();
   push @options, '-execu ' . $self->getExecU()  if $self->getExecU();
   push @options, '-execw ' . $self->getExecW()  if $self->getExecW();
   push @options, '-nusers '. $self->getNUsers() if $self->getNUsers();
   push @options, $self->getRestrict()           if $self->getRestrict();
   push @options, $self->getCmd();
   push @options, $self->getName();

   ClearCase::Common::Cleartool::mktrtype( @options );
}

sub do_commit {
   my $self = shift;
}

sub do_rollback {
   my $self = shift;

   ClearCase::Common::Cleartool::rmtype( '-f', '-rmall', $self->getName() );
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
