package ClearCase::Command::rmname;

use strict;
use Carp;
use Cwd;
use File::Basename;
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
      UndoList  => undef,
      Force     => undef,
      Argv      => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()


sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $force, $argv, @other ) =
      $class->rearrange(
         [ 'TRANSACTION', 'FORCE', 'ARGV' ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setForce( $force );
   $self->setArgv( $argv );
   return $self;
}

sub do_execute {
   my $self = shift;
   my @options;

   push @options, '-force'       if $self->getForce();

   #  warning the following code is not able to rollback a half done command!

   ClearCase::Common::Cleartool::rmname(
      $self->getComment(),
      @options,
      $self->getArgv() );

   my @undoList;
   my $regex_remove  = $ClearCase::Common::Config::CC_RMNAME_OUTPUT{'RMNAME'};
   my $regex_lf      = $ClearCase::Common::Config::CC_RMNAME_OUTPUT{'LF'};
   foreach( ClearCase::Common::Cleartool::getOutput() )
   {
      /^$regex_remove$/o && do {
         push @undoList, [ 'RMNAME', Cwd::abs_path( dirname( $1 )) . '/' . basename( $1 ) ];
      };
      /^$regex_lf$/o && do {
         push @undoList, [ 'LF', Cwd::abs_path( dirname( $1 )) . '/' . basename( $1 ) ];
      };
   }

   $self->setUndoList( \@undoList );
}

sub do_commit {
   my $self = shift;
}

sub do_rollback {
   my $self = shift;

   my $regex = $ClearCase::Common::Config::CC_LS_OUTPUT{'NORMAL'};

   my $lfFile;
   foreach( @{$self->getUndoList() } )
   {
      my ( $action, $file ) = @$_;
      print $action, $file, '\n';

      for( $action )
      {
         /^LF$/ && do {
            confess "ATTENTION: Not implemented rolback from lost and found";
            next;
         };
         /^RMNAME$/ && do {
            my $element  = basename $file;
            my $directory = dirname $file;

            ClearCase::Common::Cleartool::ls( -directory, $directory );
            ClearCase::Common::Cleartool::getOutputLine() =~ /$regex/o;

            ClearCase::Common::Cleartool::ln(
               $directory . '@@' . $2 . '/' . $element, "$directory/$element" );
            next;
         };
      }
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
