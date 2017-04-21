#!/usr/bin/perl -w
#
# Creates static Searsia search results file.
# Usage: perl indexer.pl >search.json 

# Use wget to obtain the directories blog/ and deck.js/ as follows:
# wget --timeout=9 --wait=2 --random-wait --level=inf --html-extension \
# --recursive --span-hosts --domains=searsia.org --no-clobber --tries=2 \
# --user-agent='NAME' --html-extension --restrict-file-names=windows \
# --reject=json,jpg,js,css,png,gif,doc,docx,jpeg,pdf,mp3,avi,mpeg,txt,ico \
# http://searsia.org/

use strict;
use FindBin qw($Bin);

my $SITE = 'http:\/\/searsia.org\/';
my $TITLE = 'Searsia';
my $DESCR = 'Build a beautiful search engine: Searsia is a protocol and implementation for large scale federated web search.';

&json_begin;

my $file;
my $anchor_results = "";
my $file_results = "";
$file_results .= &json_result("", "", $TITLE, $DESCR);
foreach $file (glob("$Bin/../*.html"), glob("$Bin/../blog/*.html"), glob("$Bin/../blog/*/*.html"), glob("$Bin/../deck.js/*.html"), glob("$Bin/../cran/index.html")) {
  $file =~ m/searsia\/\.\.\/(.+$)/;
  my $name = $1;
  unless($name eq '404.html' or $name eq 'index.html') {
    print STDERR "OPEN: $name\n";
    open(I, $file);
    my $line;
    # For page results:
    my $page_title = $name;
    my $page_descr = "";
    # For anchor results:
    my $url   = "";
    my $title = "";
    my $descr = "";
    while ($line = <I>) {
      if ($line =~ /<title>([^>]+)<\/title>/) {
        $page_title = $1; 
      }
      elsif ($line =~ /<h2[^>]+id=\"([^\"]+)\"[^>]*>([^>]+)<\/h2>/ or
             $line =~ /<tr[^>]+id=\"([^\"]+)\"[^>]*><td[^>]*>([^>]+)<\/td>/ or
             $line =~ /<li[^>]+id=\"([^\"]+)\"[^>]*><code>([^>]+)<\/code>/) {
        my $new_url   = $1;
        my $new_title = $page_title . ': ' . $2;
        if ($url ne "") {
            $anchor_results .= ",\n"; 
            $anchor_results .= &json_result($name, $url, $title, $descr);
        }
        $url   = $new_url;
        $title = $new_title;
        $descr = '';
      }
      elsif ($line =~ /<h1/) {
        $page_descr = "";
      }
      else {
        $line =~ s/<[^>]+>/ /g;
        $page_descr .= $line;
        $descr .= $line;
      }
    }
    close I;
    if ($url ne "") {
        $anchor_results .= ",\n";
        $anchor_results .= &json_result($name, $url, $title, $descr);
    }
    $file_results .= ",\n";
    if ($name eq 'search.html') { 
      $page_descr = "Search searsia.org"; 
    }
    if ($name eq 'resultsdemo.html') { 
      $page_descr = "This is a mockup for demonstration purposes: A search for the query informat shows 7 presentations of the same Wikipedia search results.";
    }
    if ($name eq 'deck.js/isoc2017.html') {
      $page_descr = "Slides; Presented at the ISOC NL New Year 2017. Web Search? 1. Influences people ... 2. Invades privacy ... 3. Is expensive ... Our approach... Federated search Demo! Conclusion Distribution of responsibilities: More objective — harder to manipulate or censor. Queries via broker: More private — Search engines cannot track individuals. No web crawling: Cheaper — easy to maintain. People. Check it out! Acknowledgments Thanks!";
    }
    $name =~ s/\//\\\//g;
    $file_results .= &json_result($name, "", $page_title, $page_descr);
  }
}
print $file_results;
print $anchor_results;
&json_end;


sub json_begin {
    print "{\n";
    print "  \"hits\": [\n";
}


sub json_result {
  my $name  = shift;
  my $url   = shift;
  my $title = shift;
  my $descr = shift;

  $descr =~ s/if \(typeof jQuery.*$//;
  $url =~ s/\/index\.html$/\//;
  $url =~ s/\/index\.html#/\/#/g;

  $descr =~ s/\s+/ /g;
  if (length($descr) > 4000) {
    $descr = substr($descr, 0, 4000);
    my $rindex = rindex($descr, " ");
    if ($rindex != -1) {
      $descr = substr($descr, 0, $rindex);
    }
    $descr .= "...";
  }
  $descr =~ s/\s+/ /g; $descr =~ s/^ | $//g;
  $descr =~ s/<!--.*?-->//g;

  $title =~ s/([\"\/])/\\$1/g;
  $title =~ s/&lt;/</g; $title =~ s/&gt;/>/g;  $title =~ s/&amp;/&/g;  $title =~ s/&nbsp;/ /g;
  $url   =~ s/([\"\/])/\\$1/g;
  $descr =~ s/([\"\/])/\\$1/g;
  $descr =~ s/&lt;/</g; $descr =~ s/&gt;/>/g;  $descr =~ s/&amp;/&/g;  $descr =~ s/&nbsp;/ /g;

  my $link = $SITE . $name;
  if ($url) { $link .= '#' . $url; } 

  my $result = "    {\n";
  $result .= '      "title": "' . $title . "\",\n";
  $result .= '      "url": "' . $link . "\",\n";
  $result .= '      "description": "' . $descr . "\"\n";
  $result .= "    }";
  return $result;
}


sub json_end {
  print "\n";
  print <<EndJSON;
  ],
  "resource": {
    "id": "searsia",
    "mimetype": "application\\/searsia+json",
    "favicon": "http:\\/\\/searsia.org\\/images\\/searsia.png",
    "banner": "http:\\/\\/searsia.org\\/images\\/banner.png",
    "name": "Searsia",
    "rerank": "lm",
    "apitemplate": "http:\\/\\/searsia.org\\/searsia\\/search.json",
    "usertemplate": "http:\\/\\/searsia.org\\/searsiaclient\\/search.html?q={q}"
  },
  "searsia": "v1.0.0"
}
EndJSON
}
