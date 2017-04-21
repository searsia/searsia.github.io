#!/usr/bin/perl -w

use JSON;

my $get = "";
my ($docid, $newdocid, $title, $author, $by, $words);

sub normalize_text {
  my $text = shift;
  $text =~ s/,/, /g;
  $text =~ s/ \././g;
  $text =~ s/\s+/ /g;
  $text =~ s/^ | $//g;
  $text =~ s/^([a-z])/\U$1/;
  $text =~ s/\. ([a-z])/. \U$1/g;
  $text =~ s/\b([a-z])\./\U$1./g;
  $text =~ s/\bAnd ([a-z])/and \U$1/g;
  return $text;
}

sub print_json {
  my $docid = shift;
  my $title = normalize_text(shift);
  my $author = normalize_text(shift);
  my $by = normalize_text(shift);
  my $words = normalize_text(shift);
  print "<h2 id=\"doc$docid\">$title</h2>\n";
  print "<p>By: $author</p>\n";
  print "<p>In: <em>$by</em></p>\n";
  print "<p>$words</p>\n";
  print "<hr>\n";
}


while (<STDIN>) {
  if (/^\.I ([0-9]+)/) {
    $newdocid = $1;
    if ($get ne "" and $title ne "") {
      print_json($docid, $title, $author, $by, $words);
    }
    $docid = $newdocid;
    $get = "";
    $title = $author = $by = $words = "";
  }
  if (/^\.([TABW])/) {
    $get = $1;
  } elsif ($get eq 'T') {
    $title .= $_ . " ";
  } elsif ($get eq 'A') {
    $author .= $_ . " ";
  } elsif ($get eq 'B') {
    $by .= $_ . " ";
  } elsif ($get eq 'W') {
    $words .= $_ . " ";
  }
}
if ($get ne "") {
  print_json($docid, $title, $author, $by, $words);
}

