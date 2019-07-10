package ClearCase::Command::findmerge;

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
      All      => undef,
      Name     => undef,
      Print    => undef,
      Silent   => undef,
      Merge    => undef,
      Directory=> undef,
      GMerge   => undef,
      Print    => undef,
      Short    => undef,
      Abort    => undef,
      Element  => undef,
      FVe      => undef,
      Log      => undef,
      UndoList => undef,
      Type     => undef,
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

   my ( $transaction, $log, $all, $fve, $print, $short, $merge, $abort, $argv, $element, $gmerge, $silent,
        $directory, $type, @other ) =
      $class->rearrange(
         [ 'TRANSACTION','LOG', 'ALL', 'FVE', 'PRINT', 'SHORT', 'MERGE', 'ABORT',
          'ARGV', 'ELEMENT', 'GMERGE', 'SILENT', 'DIRECTORY', 'TYPE'
         ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setAll($all);
   $self->setSilent($silent);
   $self->setLog($log);
   $self->setPrint($print);
   $self->setShort($short);
   $self->setElement($element);
   $self->setDirectory($directory);
   $self->setMerge($merge);
   $self->setGMerge($gmerge);
   $self->setAbort($abort);
   $self->setLog($log);
   $self->setFVe($fve);
   $self->setType( $type );
   $self->setArgv( $argv );

   return $self;
}

sub do_execute {
   my $self = shift;
   my @options = ();

   push @options, $self->getArgv()               if $self->getArgv();
   push @options, '-all '                            if $self->getAll();
   push @options, '-name ' . $self->getName()        if $self->getName();
   push @options, '-type ' . $self->getType()        if $self->getType();
   push @options, $self->getComment();
   push @options, '-element \'' . $self->getElement() . '\''  if $self->getElement();
   push @options, '-log '  . $self->getLog()         if $self->getLog();
   push @options, '-fve '  . $self->getFVe()         if $self->getFVe();
   push @options, '-short '                          if $self->getShort();
   push @options, '-directory'                       if $self->getDirectory();
   push @options, '-gmerge '                         if $self->getGMerge();
   push @options, '-merge '                          if $self->getMerge();
   push @options, '-abort '                          if $self->getAbort();
   push @options, '-print '                          if $self->getPrint();


   eval {
      my $oldEcho = ClearCase::Common::Cleartool::setEcho( 1==1 ) unless ($self->getSilent());
      ClearCase::Common::Cleartool::findmerge( @options );
      ClearCase::Common::Cleartool::setEcho( $oldEcho ) unless ($self->getSilent());
   };
   if ( $@ ) {
      # Findmerge had errors. Mark successfully merged files for rollback.
      # Then rethrow exception.
      $self->extractUndoList();
      die $@;
   }

   $self->extractUndoList();
}

sub extractUndoList {
   my $self=shift;
   my @undoList;
   my $co = $ClearCase::Common::Config::CC_CHECKOUT_OUTPUT;
   foreach( ClearCase::Common::Cleartool::getOutput() )
   {
      /^$co$/o && do {
         push @undoList, [ $1, $2 ];
      };
   }

   $self->setUndoList( \@undoList );
}

sub do_commit {
   my $self=shift;

   my @elements;
   foreach( reverse @{ $self->getUndoList() } )
   {
      my ( $element, $version ) = @$_;
      push ( @elements, $element . '@@' . $version );
   }

   ClearCase::Common::Cleartool::checkin(
      '-nc',
      @elements )
      if @elements;

}

sub do_rollback {
   my $self=shift;

   my @elements;
   foreach( reverse @{ $self->getUndoList() } )
   {
      my ( $element, $version ) = @$_;
      push ( @elements, $element . '@@' . $version );
   }

   ClearCase::Common::Cleartool::uncheckout( '-rm', @elements )
      if @elements;

}


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
