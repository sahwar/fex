sub faq {
  my ($faq,$var,$env,$q,$a,$c,$n);
  local $/ = "Q:";
  local $_;

  foreach $faq (@_) {

    $c = $faq;
    $c =~ s/(.)/uc $1/e;
    $c = '' if $c eq 'Local';
  
    open $faq,"$faq.faq" or return;
    $_ = <$faq>;
    $n = 0;
    while (<$faq>) {
      chomp;
      while (/\$([\w_]+)\$/) {
        $var = $1;
        $env = $ENV{$var} || '';
        #s/\$$var\$/<tt>$env<\/tt>/g;
        s/\$$var\$/$env/g;
      };
      ($q,$a) = split /A:s*/;
      $a =~ s/[\s\n]+$/\n/;
      while ($a =~ s/^(\s*)\*/$1<ul>\n$1<li>/m) { 
        while ($a =~ s/(<li>.*\n\s*)\*/$1<li>/g) {}
        $a =~ s:(.*\n)(\s*)(<li>[^\n]+\n):$1$2$3$2</ul>\n:s
      }
      $a =~ s/\n\n/\n<p>\n/g;
      $a =~ s/([^>\n\\])\n/$1<br>\n/g;
      $a =~ s/\\\n/\n/g;
      $a =~ s/^\s*<br>\s*//mg;
      $a =~ s/<([^\s<>\@]+\@[\w.-]+)>/<a href="mailto:$1">&lt;$1><\/a>/g;
      $a =~ s: (/\w[\S]+/[\S]+): <tt>$1</tt>:g;
      $a =~ s/(https?:[^\s<>]+)/<a href="$1">[$1]<\/a>/g;
      $n++;
      print qq(<div class="question"><div class="label"><u>$c Q$n:</u></div>\n);
      print qq(<div class="content">$q</div></div>\n);
      print qq(<div class="answer"><div class="label"><p>$c A$n:</div>\n);
      print qq(<div class="content">$a</div></div>\n);
    }
    close $faq;
  }
}
