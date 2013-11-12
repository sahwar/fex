# config for F*EX CGI fup

$info_1 = $info_login = <<EOD;
<p><hr><p>
<a href="/">F*EX (File EXchange)</a>
je služba pro odesílání velkých souborů.
<p>
Odesilatel (vy) nahraje soubor na F*EX server a ten příjemci autimaticky odešle 
e-mail s oznámením a s URL ke stažení.<br>
Po jeho stažení, nebo po uplynutí $keep_default dnů, server soubor smaže.
F*EX není archiv!
<p>
Přečtěte si také <a href="/FAQ.html">Otázky a odpovědi (FAQ)</a>.
<p><hr><p>
<address>
  <a href="mailto:$ENV{SERVER_ADMIN}">$ENV{SERVER_ADMIN}</a><br>
</address>
EOD

$info_2 = <<EOD;
<p><hr><p>
Po potrzení uvidíte lištu s průběhem nahrávání 
(pouze, pokud máte povolen javascript a povolené automatické otevírání oken).
<p>
<em>POZNÁMKA: Většina webových prohlížečů neumožňuje nahrávat soubory větší než 2 GB!</em><br>
Pokud je váš soubor větší, použíjte speciálního <a href="/fuc?show=tools">klienta pro F*EX</a>.<br>
Potřebuvoat budete také klient pro obnovení nahrávání v případě přerušení. Váš webový prohlížeč toto neumožňuje.
<p>
UPOZORNĚNÍ: Některé HTTP proxy servery, jako je třeba privoxy, spomalují průběh nahrávání!<br>
V případě, že se s tímto pborlémem setkáte, bude zřejmě třeba zakázat používání proxy pro $ENV{SERVER_NAME}.
<p>
Pro uživatele Firefoxu: Nemačkejte klávesu ESC, protože jinak se stahování přeruší!
<p>
Přečtěte si také <a href="/FAQ.html">FAQ<a>.
EOD
