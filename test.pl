#!/usr/bin/perl -w
use strict;

require LWP::UserAgent;
require HTML::Parser;
require CLHousingSearch;

my $SITE = "sfbay";
my $clhs = CLHousingSearch->new();

$clhs->site("sfbay");
#$clhs->area("sby");
#$clhs->minAsk(0);
#$clhs->maxAsk(2000);
#$clhs->bedrooms(2);
#$clhs->neighborhood(35);
#print $clhs->uri()."\n";

my $results;
$clhs->search();
while(($results = $clhs->results()))
{
    my $result;
    for $result(@$results)
    {
        #print "date: ".$result->{date}."\n";

        print "url: ".$result->{url}."\n";
        print "rent: \$".$result->{rent}."\n";
        print "bedrooms: ".$result->{bedrooms}."\n";
        print "neighborhood: ".$result->{neighborhood}."\n";
        print "description: \"".$result->{description}."\"\n";
        print "\n";
    }
}
