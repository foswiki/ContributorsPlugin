#4:30

package Foswiki::Plugins::ContributorsPlugin;

use strict;
use warnings;

use Foswiki::Func    ();    # The plugins API
use Foswiki::Plugins ();    # For the API version
use Foswiki::Func    ();
use Foswiki::Time    ();
use Digest::MD5 qw(md5_hex);

use Foswiki::Plugins::ContributorsPlugin::Node;

use constant MONITOR => 1;

our $VERSION          = '$Rev: 9771 $';
our $RELEASE          = '2.0';
our $SHORTDESCRIPTION = 'List editors of a topic, and topics edited by a user"';
our $NO_PREFS_IN_TOPIC = 1;

sub initPlugin {
    my ( $topic, $web, $user, $installWeb ) = @_;

    # check for Plugins.pm versions
    if ( $Foswiki::Plugins::VERSION < 2.0 ) {
        Foswiki::Func::writeWarning( 'Version mismatch between ',
            __PACKAGE__, ' and Plugins.pm' );
        return 0;
    }

    Foswiki::Func::registerTagHandler( 'CONTRIBUTORS', \&_CONTRIBUTORS );
    Foswiki::Func::registerTagHandler( 'SEARCHLOG',    \&_SEARCHLOG );

    return 1;
}

#use Monitor ();
#Monitor::MonitorMethod( 'Foswiki::Plugins::ContributorsPlugin',
#    '_CONTRIBUTORS' );

#TODO: avoid the rush, move this into Foswiki::Macros::CONTRIBUTORS
sub _CONTRIBUTORS {
    my ( $session, $params, $topic, $web, $viewedTopicObject ) = @_;

    my $showWeb   = $params->{web}   || $web;
    my $showTopic = $params->{topic} || $topic;
    ( $showWeb, $showTopic ) =
      Foswiki::Func::normalizeWebTopicName( $showWeb, $showTopic );

    #BOM out if topic does not exist (red error?)

    my $header    = $params->{header};
    my $footer    = $params->{footer};
    my $separator = $params->{separator};
    $separator = '$n' unless (defined($separator));

    #TODO: move into tmpl file too
    my $format = $params->{format}
      || '   * $wikiusername -- [[%SCRIPTURL{view}%/$web/$topic?rev=$rev][Revision $rev]] on date $date';

    #adjust $format to be inline with renderRevisionInfo
    $format =~ s/\$author/\$wikiusername/g;

    my $showLast = $params->{last} || 4;
    my $rev      = $params->{rev};                         #undef == latest..
    my $nodups   = Foswiki::isTrue( $params->{nodups} );
    my %dupHash  = ();

    my @result = ();
    $header = '' unless ( defined($header) );

    my ( $topicObject, $text ) =
      Foswiki::Func::readTopic( $showWeb, $showTopic, $rev );
    my ( $revDate, $author, $startVersion, $comment ) =
      $topicObject->getRevisionInfo();
    $rev = $startVersion;

#TEST TO SEE IF WE HAVE THIS PRE_RENDERED IN THE WorkingDIR, and if so, just toss it out, no more processing.
    my $hash = md5_hex(
        join(
            ',',
            (
                $header || '', $format, $footer || '', $separator,
                $showLast, $nodups
            )
        )
    );
    my $cached = getFromCache( $hash, $showWeb, $showTopic, $startVersion );
    return $cached if ( defined($cached) );
    
    my $newRev; #Item9969: there's a really frustrating issue where the ,v file can be created using the wrong meta:info, so the value returned by getRevisionInfo != $rev--

    while ( $showLast > 0 ) {
        $showLast--;

        #print STDERR "---- $showWeb, $showTopic , $revDate, $author, $rev, $comment\n";
        if ( ( not $nodups ) or ( not defined $dupHash{$author} ) ) {
            $dupHash{$author} = $rev;
            push( @result,
                    '%REVINFO{"' 
                  . $format
                  . '" web="'
                  . $showWeb
                  . '" topic="'
                  . $showTopic
                  . '" rev="'
                  . $rev
                  . '"}%' );
        }
        $rev--;
        last if ( $rev <= 0 );
        ( $topicObject, $text ) =
          Foswiki::Func::readTopic( $showWeb, $showTopic, $rev );
        ( $revDate, $author, $newRev, $comment ) = $topicObject->getRevisionInfo();
    }
    

    $footer = '' unless ( defined($footer) );

    return addToCache( $hash, $showWeb, $showTopic, $startVersion,
        Foswiki::expandStandardEscapes( $header.join( $separator, @result ).$footer ) );
}

sub _SEARCHLOG {
    my ( $session, $params, $topic, $web, $viewedTopicObject ) = @_;

    my $filter = $params->{_DEFAULT} || '1';
    my $reverse = Foswiki::isTrue($params->{reverse});
    my $showRepRev = Foswiki::isTrue($params->{showRepRev});

    my $query =
      Foswiki::Plugins::ContributorsPlugin::Parser::parseLogFilter( $filter,
        {} );
    return "%RED% __SEARCHLOG__ error parsing: $filter%ENDCOLOR%"
      if ( not defined($query) );

    my $separator = $params->{separator};
    $separator = '$n' unless (defined($separator));

    my $header = $params->{header};
    $header = '| *Date* | *Action* | *Topic* | *User* | *Extra* |' unless defined($header);
    my $format = $params->{format};
    $format = '| $time | $action | $webtopic [[%SCRIPTURL{view}%/$web/$topic?rev=$rev][Revision $rev]] | $user | $extra |' unless defined($format);
    my $footer = $params->{footer};
    $footer = '||||| $from to $last |' unless defined($footer);

#TODO: from and to should really be part of the query too - ie, "'05 Oct 2010' < time AND time > '10 Oct 2010'"

    my $from;
    if ( defined( $params->{from} ) ) {
        if ( $params->{from} =~ /^\d\d\d\d\d\d+$/ ) {

            #attempt to detect epochseconds
            #we're unlikely to actually want the year 10000
            $from = 0 + $params->{from};
        }
        else {
            $from = Foswiki::Time::parseTime( $params->{from} );
        }
    }
    $from = time() - ( 60 * 60 * 24 * 7 )
      if ( not defined($from) )
      ;    #default to 7 days ago (deal with parse error..)

    my $to;
    if ( defined( $params->{to} ) ) {
        if ( $params->{to} =~ /^\d\d\d\d\d\d+$/ ) {

            #attempt to detect epochseconds
            #we're unlikely to actually want the year 10000
            $to = 0 + $params->{to};
        }
        else {
            $to = Foswiki::Time::parseTime( $params->{to} );
        }
    }
    $to = time()
      if ( not defined($to) );    #default now() (deal with parse error..)

    my $pageLimit = $params->{limit} || 100;

    my $logger = $session->logger();
    my $iterator = $logger->eachEventSince( $from, 'info' );

    my @result = ();
    my ( $time, $user, $action, $webTopic, $extra, $remoteAddr );

    my $count = 0;
    while ( $iterator->hasNext ) {
        my $eventRef = $iterator->next;
        ( $time, $user, $action, $webTopic, $extra, $remoteAddr ) = @$eventRef;
        $extra ||= '';

        last if ( $time > $to );
        next if ( $from > $time );

        if ( defined($filter) ) {
            my $match = $query->evaluate(
                time     => $time,
                user     => $user,
                action   => $action,
                webtopic => $webTopic,
                extra    => $extra,
                addr     => $remoteAddr
            );
            next if ( not $match );
        }

        my $line = $format;
        if ($line =~ /\$(web|topic|rev)/ ) {
            my ($web, $topic) = Foswiki::Func::normalizeWebTopicName('', $webTopic);
            $line =~ s/\$web/$web/g;
            $line =~ s/\$topic/$topic/g;
            if ($line =~ /\$rev/ ) {
                my $revision = Foswiki::Func::getRevisionAtTime( $web, $topic, $time );
                if (!$showRepRev) {
                    #WATCHOUT. reprev comments are somewhat confusing 
                    $extra = '' if ($extra =~ /^repRev (\d*).*$/);
                    next if (!defined($revision)); 
                    my ( $TESTdate, $TESTuser, $TESTrev, $TESTcomment ) = Foswiki::Func::getRevisionInfo($web, $topic, $revision );
                    next if ($TESTdate != $time);
                }
                $line =~ s/\$rev/$revision/ge;
            }
        }
        $count++;
        $line =~ s/\$index/$count/g;
        $line =~ s/\$user/$user/g;
        $line =~ s/\$action/$action/g;
        $line =~ s/\$webtopic/$webTopic/g;
        $line =~ s/\$extra/$extra/g;

        #NO$line =~ s/\$remoteAddr/$remoteAddr/g;

        $line =~ s/\$time/
          Foswiki::Time::formatTime($time)/ge;
        $line =~ s/\$date/
          Foswiki::Time::formatTime(
              $time, $Foswiki::cfg{DefaultDateFormat} )/ge;
        $line =~ s/(\$(rcs|http|email|iso|longdate|epoch))/
          Foswiki::Time::formatTime($time, $1 )/ge;

        if ( $line =~ /\$(sec|min|hou|day|wday|dow|week|mo|ye|epoch|tz)/ ) {
            $line = Foswiki::Time::formatTime( $time, $line );
        }
        if ($reverse) {
            unshift( @result, $line );
        } else {
            push( @result, $line );
        }

        last if ( $pageLimit <= $count );
    }

    #by doing the header and footer at the end, we can implement paging there.
    if ( defined($header) ) {
        $header =~ s/\$index//g;

        $header =~ s/\$epochfrom/Foswiki::Time::formatTime($from, '$epoch')/ge;
        $header =~ s/\$epochto/Foswiki::Time::formatTime($to, '$epoch')/ge;
        $header =~ s/\$epochlast/Foswiki::Time::formatTime($time, '$epoch')/ge;

        $header =~ s/\$from\((.*?)\)/Foswiki::Time::formatTime($from, $1)/ge;
        $header =~ s/\$to\((.*?)\)/Foswiki::Time::formatTime($to, $1)/ge;
        $header =~ s/\$last\((.*?)\)/Foswiki::Time::formatTime($time, $1)/ge;

        $header =~ s/\$from/Foswiki::Time::formatTime($from)/ge;
        $header =~ s/\$to/Foswiki::Time::formatTime($to)/ge;
        $header =~ s/\$last/Foswiki::Time::formatTime($time)/ge;
    }
    if ( defined($footer) ) {
        $footer =~ s/\$index/$count/g;

        $footer =~ s/\$epochfrom/Foswiki::Time::formatTime($from, '$epoch')/ge;
        $footer =~ s/\$epochto/Foswiki::Time::formatTime($to, '$epoch')/ge;
        $footer =~ s/\$epochlast/Foswiki::Time::formatTime($time, '$epoch')/ge;

        $footer =~ s/\$from\((.*?)\)/Foswiki::Time::formatTime($from, $1)/ge;
        $footer =~ s/\$to\((.*?)\)/Foswiki::Time::formatTime($to, $1)/ge;
        $footer =~ s/\$last\((.*?)\)/Foswiki::Time::formatTime($time, $1)/ge;

        $footer =~ s/\$from/Foswiki::Time::formatTime($from)/ge;
        $footer =~ s/\$to/Foswiki::Time::formatTime($to)/ge;
        $footer =~ s/\$last/Foswiki::Time::formatTime($time)/ge;
    }
    return Foswiki::expandStandardEscapes( $header.join( $separator, @result ).$footer );
}

##########################################################################
#poormanscache
sub makeCacheFilename {
    my ( $hash, $showWeb, $showTopic, $rev ) = @_;

    my $dir = Foswiki::Func::getWorkArea('ContributorsPlugin');

    my $file = join( '_', ( $showWeb, $showTopic, $rev, $hash ) );
    my $filepath = $dir . '/' . $file;

    return $filepath;
}

sub addToCache {
    my ( $hash, $showWeb, $showTopic, $rev, $html ) = @_;

    open( TICK, '>', makeCacheFilename( $hash, $showWeb, $showTopic, $rev ) )
      or warn "$!";
    print TICK $html;
    close(TICK);

    return $html;
}

sub getFromCache {

    #    my ($hash, $showWeb, $showTopic, $rev) = @_;
    my $filepath = makeCacheFilename(@_);
    if ( -e $filepath ) {
        local $/ = undef;
        open( TICK, '<', $filepath ) or warn "$!";
        my $html = <TICK>;
        close(TICK);

        #need to untaint :/
        $html =~ /^(.*)$/s;
        $html = $1;
        return $html;
    }
    return;

}

1;

__END__
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

author: SvenDowideit@fosiki.com
