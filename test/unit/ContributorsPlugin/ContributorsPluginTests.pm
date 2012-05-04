use strict;

package ContributorsPluginTests;

use FoswikiTestCase;
our @ISA = qw( FoswikiTestCase );

use strict;
use TWiki;
use CGI;

use Foswiki::Query::Parser;
use Foswiki::Plugins::ContributorsPlugin::Node;

my $twiki;

sub new {
    my $self = shift()->SUPER::new(@_);
    return $self;
}

# Set up the test fixture
sub set_up {
    my $this = shift;

    $this->SUPER::set_up();

    $TWiki::Plugins::SESSION = $twiki;
}

sub tear_down {
    my $this = shift;
    $this->SUPER::tear_down();
}

sub test_self {
    my $this = shift;
}

sub parseLogFilter {
    my $searchString = shift;
    my $params = shift || {};
    $params->{nodeClass} = 'Foswiki::Plugins::ContributorsPlugin::Node';

    require Foswiki::Query::Parser;
    print STDERR "create parser\n";
    my $theParser = new Foswiki::Query::Parser($params);
    my $query;

    #try {
    print STDERR "parse $searchString\n";
    $query = $theParser->parse( $searchString, $params );
    print STDERR "parse done\n";

    #}
    #catch Foswiki::Infix::Error with {
    # Pass the error on to the caller
    #throw Error::Simple( shift->stringify() );
    #    print STDERR "ERROR: ".shift->stringify()."\n";
    #};
    return $query;
}

sub testUserQuery_EQ {
    my $self = shift;

    my $query = parseLogFilter( "user = 'AdminUser'", {} );
    $self->assert(
        $query->evaluate(
            time     => Foswiki::Time::parseTime('20 Oct 2010'),
            user     => 'AdminUser',
            action   => 'save',
            webtopic => 'Main.WebHome',
            extra    => '',
            addr     => '192.168.1.21'
        )
    );
    $self->assert(
        not $query->evaluate(
            time     => Foswiki::Time::parseTime('20 Oct 2010'),
            user     => 'OtherUser',
            action   => 'save',
            webtopic => 'Main.WebHome',
            extra    => '',
            addr     => '192.168.1.21'
        )
    );
}

sub testActionQuery_EQ {
    my $self = shift;

    my $query = parseLogFilter( "action = 'save'", {} );
    $self->assert(
        $query->evaluate(
            time     => Foswiki::Time::parseTime('20 Oct 2010'),
            user     => 'AdminUser',
            action   => 'save',
            webtopic => 'Main.WebHome',
            extra    => '',
            addr     => '192.168.1.21'
        )
    );
    $self->assert(
        not $query->evaluate(
            time     => Foswiki::Time::parseTime('20 Oct 2010'),
            user     => 'OtherUser',
            action   => 'view',
            webtopic => 'Main.WebHome',
            extra    => '',
            addr     => '192.168.1.21'
        )
    );
}

sub testTimeQuery_GT_LT {
    my $self = shift;

    my $query =
      parseLogFilter( "d2n('05 Oct 2010') < time AND time < d2n('20 Oct 2010')",
        {} );
    $self->assert(
        not $query->evaluate(
            time     => Foswiki::Time::parseTime('04 Oct 2010'),
            user     => 'AdminUser',
            action   => 'save',
            webtopic => 'Main.WebHome',
            extra    => '',
            addr     => '192.168.1.21'
        )
    );
    $self->assert(
        $query->evaluate(
            time     => Foswiki::Time::parseTime('05 Oct 2010'),
            user     => 'OtherUser',
            action   => 'save',
            webtopic => 'Main.WebHome',
            extra    => '',
            addr     => '192.168.1.21'
        )
    );
    $self->assert(
        $query->evaluate(
            time     => Foswiki::Time::parseTime('06 Oct 2010'),
            user     => 'OtherUser',
            action   => 'save',
            webtopic => 'Main.WebHome',
            extra    => '',
            addr     => '192.168.1.21'
        )
    );

    $self->assert(
        $query->evaluate(
            time     => Foswiki::Time::parseTime('19 Oct 2010'),
            user     => 'AdminUser',
            action   => 'save',
            webtopic => 'Main.WebHome',
            extra    => '',
            addr     => '192.168.1.21'
        )
    );
    $self->assert(
        not $query->evaluate(
            time     => Foswiki::Time::parseTime('20 Oct 2010'),
            user     => 'OtherUser',
            action   => 'save',
            webtopic => 'Main.WebHome',
            extra    => '',
            addr     => '192.168.1.21'
        )
    );
    $self->assert(
        not $query->evaluate(
            time     => Foswiki::Time::parseTime('21 Oct 2010'),
            user     => 'OtherUser',
            action   => 'save',
            webtopic => 'Main.WebHome',
            extra    => '',
            addr     => '192.168.1.21'
        )
    );
}

sub testTimeQuery_GTEQ_LTEQ {
    my $self = shift;

    my $query = parseLogFilter(
        "d2n('05 Oct 2010') <= time AND time <= d2n('20 Oct 2010')", {} );
    $self->assert(
        not $query->evaluate(
            time     => Foswiki::Time::parseTime('04 Oct 2010'),
            user     => 'AdminUser',
            action   => 'save',
            webtopic => 'Main.WebHome',
            extra    => '',
            addr     => '192.168.1.21'
        )
    );
    $self->assert(
        $query->evaluate(
            time     => Foswiki::Time::parseTime('05 Oct 2010'),
            user     => 'OtherUser',
            action   => 'save',
            webtopic => 'Main.WebHome',
            extra    => '',
            addr     => '192.168.1.21'
        )
    );
    $self->assert(
        $query->evaluate(
            time     => Foswiki::Time::parseTime('06 Oct 2010'),
            user     => 'OtherUser',
            action   => 'save',
            webtopic => 'Main.WebHome',
            extra    => '',
            addr     => '192.168.1.21'
        )
    );

    $self->assert(
        $query->evaluate(
            time     => Foswiki::Time::parseTime('19 Oct 2010'),
            user     => 'AdminUser',
            action   => 'save',
            webtopic => 'Main.WebHome',
            extra    => '',
            addr     => '192.168.1.21'
        )
    );
    $self->assert(
        not $query->evaluate(
            time     => Foswiki::Time::parseTime('20 Oct 2010'),
            user     => 'OtherUser',
            action   => 'save',
            webtopic => 'Main.WebHome',
            extra    => '',
            addr     => '192.168.1.21'
        )
    );
    $self->assert(
        not $query->evaluate(
            time     => Foswiki::Time::parseTime('21 Oct 2010'),
            user     => 'OtherUser',
            action   => 'save',
            webtopic => 'Main.WebHome',
            extra    => '',
            addr     => '192.168.1.21'
        )
    );
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
