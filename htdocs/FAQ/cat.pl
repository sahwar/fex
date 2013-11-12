$ENV{PATH_INFO} =~ /(\w+)/ and $ENV{faq} = $faq = $title = $1; 
$title =~ s/(\w)/uc($1)/e;
print qq(<h1><a href="/index.html">F*EX</a> <a href="FAQ.html">FAQ</a> $title</h1>\n);
print "<h3>";
foreach (qw'Meta User Admin Misc All') {
  print sprintf('<a href="%s.html?0">%s</a> ',lc($_),$_);
}
print "</h3>\n";

$ENV{QUERY_STRING} =~ /(\d+)/ and $q = $1;
my $n = 0;
local $/ = "Q:";
local $_;
$faq .= '.faq';
open $faq,"$docdir/locale/$locale/FAQ/$faq" or open $faq,$faq or return;
print "<table border=0>\n";
$_ = <$faq>;
while (<$faq>) {
  chomp;
  while (/\$([\w_]+)\$/) {
    $var = $1;
    $env = $ENV{$var} || '';
    s/\$$var\$/$env/g;
  };
  ($Q,$A) = split /A:s*/;
  $A =~ s/([^>\n\\])\n/$1<br>\n/g;
  $A =~ s/\\\n/\n/g;
  $A =~ s/<([^\s<>\@]+\@[\w.-]+)>/<a href="mailto:$1">&lt;$1><\/a>/g;
  $A =~ s: (/\w[\S]+/[\S]+): <tt>$1</tt>:g;
  $A =~ s/(https?:[^\s<>]+)/<a href="$1">[$1]<\/a>/g;
  $n++;
  if ($q) {
    if ($q == $n) {
      print "<tr><th>Q$n:<td>$Q</tr>\n";
      print "<tr valign=top><th>A$n:<td>$A</tr>\n";
    }
  } else {
    print "<tr><th>Q$n:<td>$Q</tr>\n";
    print "<tr valign=top><th>A$n:<td>$A</tr>\n";
    print "<tr><th><td></tr>\n";
  }
}
print "</table>\n";
