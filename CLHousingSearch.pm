package CLHousingSearch;
use strict;

require URI;

sub new
{
    my ($class) = @_;
    my $self = {};

    $self->{uri} = URI->new();
    $self->{uri}->scheme("http");
    $self->{site} = "";
    $self->{area} = "";
    $self->{query} = "";
    $self->{minAsk} = "min";
    $self->{maxAsk} = "max";
    $self->{bedrooms} = "";
    $self->{neighborhood} = "";
    $self->{results} = [];
    $self->{next_url} = undef;
    bless($self, $class);

    return $self;
}

sub search
{
    my ($self) = @_;

    $self->get_page($self->uri());
    return $self->{results};
}

sub results
{
    my ($self) = @_;

    my $ret = $self->{results};
    if($self->{next_url})
    {
        $self->get_page($self->{next_url});
    }
    else
    {
        $self->{results} = undef;
    }

    return $ret;
}

sub uri
{
    my ($self) = @_;

    return $self->{uri};
}

sub site
{
    my ($self, $site) = @_;

    $self->{site} = $site;
    return $self->updateURI();
}

sub area
{
    my ($self, $area) = @_;

    $self->{area} = $area;
    return $self->updateURI();
}

sub query
{
    my ($self, $query) = @_;

    $self->{query} = $query;
    return $self->updateURI();
}

sub minAsk
{
    my ($self, $minAsk) = @_;

    $self->{minAsk} = $minAsk;
    return $self->updateURI();
}

sub maxAsk
{
    my ($self, $maxAsk) = @_;

    $self->{maxAsk} = $maxAsk;
    return $self->updateURI();
}

sub bedrooms
{
    my ($self, $bedrooms) = @_;

    $self->{bedrooms} = $bedrooms;
    return $self->updateURI();
}

sub neighborhood
{
    my ($self, $neighborhood) = @_;

    $self->{neighborhood} = $neighborhood;
    return $self->updateURI();
}

# private

sub host
{
    my ($self, $site) = @_;

    return $site.".craigslist.org";
}

sub updateURI
{
    my ($self) = @_;
    my $uri = $self->{uri};
    my $query_form =
    [
        query => $self->{query},
        minAsk => $self->{minAsk},
        maxAsk => $self->{maxAsk},
        bedrooms => $self->{bedrooms},
        neighborhood => $self->{neighborhood}
    ];

    $uri->host($self->host($self->{site}));

    if($self->{area})
    {
        $uri->path("search/apa/".$self->{area});
    }
    else
    {
        $uri->path("search/apa/");
    }

    $uri->query_form($query_form);

    return $uri;
}

sub get_page
{
    my ($self, $url) = @_;

    my $ua = LWP::UserAgent->new();
    my $request = HTTP::Request->new("GET", $url);
    my $response = $ua->request($request);
    if($response->is_success())
    {
        $self->{current_url} = $response->request()->uri();
        $self->parse_page($response->content());
    }
}

sub parse_page
{
    my ($self, $content) = @_;
    my $p = HTML::Parser->new(api_version => 3);
    my $date;
    my $url;
    my $url_text;
    my $just_got_url = undef;
    my $just_got_url_text = undef;
    my $next_url = undef;
    my $got_next_url = undef;

    $self->{next_url} = undef;

    my $handle_text = sub
    {
        my ($text) = @_;

        if($just_got_url)
        {
            $url_text = $text;
            $just_got_url = undef;
            $just_got_url_text = 1;
        }
        elsif($just_got_url_text)
        {
            $just_got_url_text = undef;
            push(@{$self->{results}},
                 $self->parse_result($date, $url, $url_text, $text));
        }
        elsif(($text =~ /^\s*Next&gt;&gt;\s*$/ ||
               $text =~ /^\s*next\s+100\s+postings\s*$/) &&
              !$got_next_url)
        {
            $self->{next_url} = $self->complete_url($next_url);
            $got_next_url = 1;
        }
        else
        {
            $date = $text;
        }
    };

    my $handle_start = sub
    {
        my ($tagname, $attr) = @_;
        my ($key, $val);

        if($tagname eq "a")
        {
            if(defined($$attr{"href"}))
            {
                $url = $$attr{"href"};
                if($url =~ /\/[0-9]+\.html$/)
                {
                    $just_got_url = 1;
                }
                else
                {
                    $next_url = $url;
                }
            }
        }
    };

    $self->{results} = [];
    $p->handler("text", $handle_text, 'text');
    $p->handler("start", $handle_start, 'tagname, attr');
    $p->parse($content);
    $p->eof();

    if(!($self->{results}) || scalar(@{$self->{results}}) <= 0)
    {
        $self->{results} = undef;
        $self->{next_url} = undef;
    }
}

sub parse_result
{
    my ($self, $date, $url, $url_text, $neighborhood) = @_;
    my $ret;

    if($date =~ /^\s*(.*\S)\s*-\s*$/)
    {
        $ret->{date} = $1;
    }
    else
    {
        $ret->{date} = "(UNPARSED) ".$date;
    }

    $ret->{url} = $self->complete_post_url($url);

    if($url_text =~ /^\s*\$([0-9]+)\s*\/\s*([0-9]+)br\s*\-\s*(.*\S)\s*\-\s*$/)
    {
        $ret->{rent} = $1;
        $ret->{bedrooms} = $2;
        $ret->{description} = $3;
    }
    else
    {
        $ret->{rent} = "(UNPARSED)";
        $ret->{bedrooms} = "(UNPARSED)";
        $ret->{description} = "(UNPARSED) ".$url_text;
    }

    if($neighborhood =~ /^\s*\((.+)\)\s*$/)
    {
        $ret->{neighborhood} = $1;
    }
    else
    {
        $ret->{neighborhood} = "(UNPARSED) ".$neighborhood;
    }

    return $ret;
}

sub complete_post_url
{
    my ($self, $url) = @_;
    my $uri = URI->new();

    $uri->scheme("http");
    $uri->host($self->host($self->{site}));
    $uri->path($url);

    return $uri;
}

sub complete_url
{
    my ($self, $url) = @_;
    my $base;
    my $current_url = $self->{current_url};

    if($current_url =~ /^(.+)\/([^\/]*)$/)
    {
        $base = $1;
    }
    else
    {
        $base = "";
    }

    if(!($url =~ /^\//))
    {
        $url = "/".$url;
    }

    return $base.$url;
}

1;
