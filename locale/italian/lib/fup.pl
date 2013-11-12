# configurazione per F*EX CGI fup

$info_1 = $info_login = <<EOD;
<p><hr><p>
<a href="/">F*EX (File EXchange)</a>
e' un servizio per spedire grossi (grandi, enormi, giganti, ...) file.
<p>
Il mittente (tu) carica il file nel server F*EX ed automaticamente il destinatario si vede recapitare
una e-mail di notifica con il link per effettuare il download.<br>
Dopo il download o dopo $keep_default giorni, il server cancella il file.
F*EX non e' un sistema di archiviazione!
<p>
Guardate anche <a href="/FAQ.html">domande e risposte (Q&A)</a>.
<p><hr><p>
<address>
  <a href="mailto:$ENV{SERVER_ADMIN}">$ENV{SERVER_ADMIN}</a><br>
</address>
EOD

$info_2 = <<EOD;
<p><hr><p>
Dopo il caricamento del file vedrete una barra di avanzamento 
(bisogna avere javascript abilitato ed i popup abilitati).
<p>
<em>NOTA: Parte dei browser-WEB non possono caricare file > 2 GB!</em><br>
Se il tuo file e' piu' grande devi usare un <a href="/fuc?show=tools">client F*EX particolare</a>.<br>
Hai bisogno anche di un tool per recuperare i download interrotti. Il tuo browser-WEB non puo' farlo.
<p>
Attenzione: alcuni proxy HTTP come privoxy ritardano lo stattttto della barra di avanzamento!<br>
Potresti voler disabilitare il proxying $ENV{SERVER_NAME} se ti capita di incorrere in questo problema.
<p>
Utenti Firefox: non digitare [ESC] perche' questo interrompera' il caricamento!
<p>
Vedere anche <a href="/FAQ.html">FAQ<a>.
EOD
