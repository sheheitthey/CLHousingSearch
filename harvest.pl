#!/usr/bin/perl -w
use strict;

require LWP::UserAgent;
require HTML::Parser;
require DBI;
require CLHousingSearch;

my $SITE = "sfbay";

my $HOST = "meiwu";
my $DRIVER = "mysql";
my $USER = "cl_housing";
my $PASSWORD = "password";
my $DATABASE = "cl_housing";
my $TABLE = "posts";

my $clhs = CLHousingSearch->new();

$clhs->site($SITE);
#$clhs->area("sby");
#$clhs->minAsk(0);
#$clhs->maxAsk(2000);
#$clhs->bedrooms(2);
#$clhs->neighborhood(35);
#print $clhs->uri()."\n";

my $dsn = "DBI:$DRIVER:$DATABASE:$HOST";
my $dbh = DBI->connect($dsn, $USER, $PASSWORD);
if(!$dbh)
{
    die("Error connecting to database.\n");
}

sub test_unparsed_field
{
    my ($field) = @_;

    if($field =~ /\(UNPARSED\)/)
    {
        return undef;
    }
    return 1;
}

sub escape_and_wrap
{
    my ($str) = @_;

    $str =~ s/"/\\"/g;
    return "\"".$str."\"";
}

sub harvest
{
    my ($result) = @_;

    my $url = escape_and_wrap($result->{url});
    my $rent = escape_and_wrap($result->{rent});
    my $bedrooms = escape_and_wrap($result->{bedrooms});
    my $neighborhood = escape_and_wrap($result->{neighborhood});
    my $description = escape_and_wrap($result->{description});

    my $query = "INSERT INTO $TABLE ".
                "(url, rent, bedrooms, neighborhood, description) VALUES ".
                "($url, $rent, $bedrooms, $neighborhood, $description);";
    $dbh->do($query);
}

$dbh->do("DROP TABLE $TABLE;");
$dbh->do("CREATE TABLE $TABLE (url VARCHAR(1000), rent INT NOT NULL, ".
         "bedrooms INT NOT NULL, neighborhood VARCHAR(1000), ".
         "description VARCHAR(10000));");

my $results;
$clhs->search();
while(($results = $clhs->results()))
{
    my $result;
    for $result(@$results)
    {
        if(test_unparsed_field($result->{url}) &&
           test_unparsed_field($result->{rent}) &&
           test_unparsed_field($result->{bedrooms}) &&
           test_unparsed_field($result->{neighborhood}) &&
           test_unparsed_field($result->{description}))
        {
            harvest($result);
        }
    }
}

$dbh->disconnect();
