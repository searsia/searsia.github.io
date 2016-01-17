#!/usr/bin/perl -w

use strict;
use FindBin qw($Bin);

my $SITE = 'http:\/\/searsia.org\/';
my $TITLE = 'Searsia';

&json_begin;

my $file;
my $anchor_results = "";
my $file_results = "";
$file_results .= &json_result($SITE, "", $TITLE, "");
foreach $file (glob("$Bin/../*.html")) {
  $file =~ m/([^\/]+$)/;
  my $name = $1;
  unless($name eq '404.html' or $name eq 'index.html') {
    open(I, $file);
    my $line;
    my $page_title = $name;
    my $page_descr = "";
    while ($line = <I>) {
      if ($line =~ /<title>([^>]+)<\/title>/) {
        $page_title = $1; 
      }
      elsif ($line =~ /<h2[^>]+id=\"([^\"]+)\"[^>]*>([^>]+)<\/h2>/) {
        my $url   = $1;
        my $title = $page_title . ': ' . $2;
        my $descr = "";
        $descr =~ s/\s+/ /g;
        $anchor_results .= ",\n"; 
        $anchor_results .= &json_result($name, $url, $title, $descr);
      }
      elsif ($line =~ /<h1/) {
        $page_descr = "";
      }
      else {
        $line =~ s/<[^>]+>/ /g;
        $page_descr .= $line;
      }
    }
    close I;
    if (length($page_descr) > 400) {
      $page_descr = substr($page_descr, 0, 400) . "...";
    }
    $page_descr =~ s/\s+/ /g; $page_descr =~ s/^ | $//g;
    $file_results .= ",\n";
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
  $title =~ s/([\"\/])/\\$1/g;
  $url   =~ s/([\"\/])/\\$1/g;
  $descr =~ s/([\"\/])/\\$1/g;
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
    "id": "searsia.org",
    "mimetype": "application\/searsia+json",
    "favicon": "http:\\/\\/searsia.org\\/images\\/search.png",
    "banner": "http:\\/\\/searsia.org\\/images\\/banner.png",
    "name": "Searsia",
    "rerank": "lm",
    "apitemplate": "http:\\/\\/searsia.org\\/searsia\\/searsia.json",
    "usertemplate": "http:\\/\\/searsia.org\\/searsiaclient\\/search.html?q={q}"
  },
  "searsia": "v0.1.3"
}
EndJSON
}
