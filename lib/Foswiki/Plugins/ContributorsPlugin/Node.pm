# See bottom of file for license and copyright information

=begin TML

---+ package Foswiki::Plugins::ContributorsPlugin::Node

A Query object is a representation of a query over the Logger API elements

I _think_ this code needs to be closer (or in) the Logger implementation, as some backends should have the evaluate delegate to the backends
ie, MongoDB logger.. SysLogLogger etc might be able to provide faster ways to acheive the same thing.

additionally, the Logger API and impl needs a 'query' method that implements most of what is in ContributorsPlugin::_SEARCHLOG

so that we don't have to brute force eachChangeSince

=cut

package Foswiki::Plugins::ContributorsPlugin::Node;
use strict;
use warnings;
use Foswiki::Infix::Node ();
our @ISA = ('Foswiki::Infix::Node');

use Assert;
use Error qw( :try );

# <DEBUG SUPPORT>

use constant MONITOR_EVAL => 0;

sub toString {
    my ($a) = @_;
    return 'undef' unless defined($a);
    if ( ref($a) eq 'ARRAY' ) {
        return '[' . join( ',', map { toString($_) } @$a ) . ']';
    }
    if ( ref($a) eq 'HASH' ) {
        return
          '{'
          . join( ',', map { "$_=>" . toString( $a->{$_} ) } keys %$a ) . '}';
    }
    if ( UNIVERSAL::isa( $a, 'Foswiki::Meta' ) ) {
        return $a->stringify();
    }
    return $a;
}

my $ind = 0;

# </DEBUG SUPPORT>

sub newLeaf {
    my ( $class, $val, $type ) = @_;

    return $class->SUPER::newLeaf( $val, $type );
}

#my $match = $query->evaluate( tom => $meta, data => $meta );
#my $match = $query->evaluate( time=>$time, user=>$user, action=>$action, webtopic=>$webTopic, extra=>$extra, addr=>$remoteAddr);
sub evaluate {
    my $this = shift;
    ASSERT( scalar(@_) % 2 == 0 );
    my $result;

    print STDERR ( '-' x $ind ) . $this->stringify() if MONITOR_EVAL;

    if ( !ref( $this->{op} ) ) {
        my %domain = @_;

#Foswiki::Infix::Node::NAME = 1 (in foswiki1.0, these are variables = $Foswiki::Infix::Node::NAME)
        if ( $this->{op} == 1 ) {
            $result = $domain{ $this->{params}[0] };
        }
        else {
            $result = $this->{params}[0];
        }
    }
    else {
        print STDERR " {\n" if MONITOR_EVAL;
        $ind++ if MONITOR_EVAL;
        $result = $this->{op}->evaluate( $this, @_ );
        $ind-- if MONITOR_EVAL;
        print STDERR ( '-' x $ind ) . '}' . $this->{op}->{name} if MONITOR_EVAL;
    }
    print STDERR ' -> ' . toString($result) . "\n" if MONITOR_EVAL;

    return $result;
}

##########################################################################
package Foswiki::Plugins::ContributorsPlugin::Parser;

#TODO: make our own simplified parser, and cache it
use Error qw( :try );
use Foswiki::Infix::Error;
use Foswiki::Query::Parser;

sub parseLogFilter {
    my $searchString = shift;
    my $params = shift || {};
    $params->{nodeClass} = 'Foswiki::Plugins::ContributorsPlugin::Node';

    my $theParser = new Foswiki::Query::Parser($params);

    my $query;

    try {
        $query = $theParser->parse( $searchString, $params );
    }
    catch Foswiki::Infix::Error with {

        # Pass the error on to the caller
        #throw Error::Simple( shift->stringify() );
        #print STDERR "ERROR: ".shift->stringify()."\n";
    };
    return $query;
}

1;
__END__
Author: Sven Dowideit http://fosiki.com

Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2008-2010 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 3
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
