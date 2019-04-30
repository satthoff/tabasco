package Data;

use strict;
use Carp;
use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA );
   $VERSION = '0.01';
   require Exporter;

   @ISA = qw(Exporter);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );
} # sub BEGIN()

init(
   PACKAGE  => __PACKAGE__,
   SUPER    => ''
   );

%DATA = ();

sub init {
   my %params = ( @_ );

   my $package = $params{'PACKAGE'};
   my $super   =
      defined $params{'SUPER'}
      ?  $params{'SUPER'}
      :  '';

   confess if not defined $package;

   no strict 'refs';
   my $fctname;
   $fctname = $package.'::get';
   *$fctname = sub { return Data::_get( shift, $package, $super , @_ ); };
   $fctname = $package.'::set';
   *$fctname = sub { return Data::_set( shift, $package, $super , @_ ); };

   my $DATA = \%{ $package . '::DATA' };

   foreach my $field ( keys %$DATA )
   {
      next if $field=~ /^_/;

      $fctname = $package.'::set'. $field;
      *$fctname = sub { my $self=shift; return $self->set( $field, @_ ); };
      $fctname = $package.'::get'. $field;
      *$fctname = sub { my $self=shift; return $self->get( $field, @_ ); };
   }
}

sub _set {
   my ( $self, $package, $super, $field, $value ) = @_;
   no strict 'refs';

   my %hn = %{ $package . '::DATA' };
   if( !exists $hn{ $field } )
   {
      if( "$super" eq "" )
      {
         Die( ["SET: Unknown Field $field in package ", $self] );
      }
      else
      {
         my $fct = $super . '::set';
         return $self -> $fct ( $field, $value );
      }
   }

   return $self->{ $package . '::' . $field } = $value;
}


sub _get {
   my ( $self, $package, $super, $field ) = @_;
   no strict 'refs';

   my %hn = %{ $package . '::DATA' };
   # check if a field with specified name exists
   if( !exists $hn{ $field } )
   {
      if( "$super" eq "" )
      {
         Die( [ "GET: Unknown Field $field in package ", $self ]);
      }
      else
      {
         my $fct = $super . '::get';
         return $self -> $fct ( $field );
      }
   }

   # check if the field is set
   my $function = $hn{ $field }->{'CALCULATE'};

   if( !exists $self->{ $package . '::' . $field } and defined $function )
   {
      # it is not set, so
      my $rc = $self -> $function ( $field );
      return $rc if defined $rc;

   }
   return $self->{ $package . '::' . $field };
};

sub dump {
   my $self = shift;

   require Data::Dumper;
   print Data::Dumper::Dumper( $self );
} # dump

sub rearrange {
   shift if $_[0]->isa( __PACKAGE__ );
   my( $order,@param ) = @_;

   # Nothing to do if there are no parameters
   return () unless @param;

   # user supplied a hash ?
   if (ref($param[0]) eq 'HASH') {
      @param = %{$param[0]};
      }
   # no check for named parameters
   else {
      return @param
            unless( defined($param[0]) && substr($param[0],0,1) eq '-')
      }

   # map parameters into positional indices
   my ($i,%pos);
   $i = 0;
   foreach (@$order) {
      foreach (ref($_) eq 'ARRAY' ? @$_ : $_) { $pos{$_} = $i; }
      $i++;
      }

   my (@result,@leftover);
   $#result = $#$order;  # preextend

   while (@param) {
      my $key = uc(shift(@param));
      $key =~ s/^\-//;
      if (exists $pos{$key}) {
          $result[$pos{$key}] = shift(@param);
      } else {
          push @leftover, ( $key, shift(@param) );
      }
  }

  push (@result, @leftover) if @leftover;
  @result;
} # rearrange

1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2004 Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com

=head1 SEE ALSO

=cut

# ============================================================================
