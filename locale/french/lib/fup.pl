# config for F*EX CGI fup

$info_1 = $info_login = <<EOD;
<p><hr><p>
<a href="/">F*EX (File EXchange)</a>
est un service pour envoyer des fichiers très volumineux (grand, énorme, géant, ...).
<p>
L'expéditeur (vous) upload le fichier vers un serveur F*EX et le destinataire reçoit automatiquement un message
de notification par mail avec l'URL de téléchargement.<br>
Après un téléchargement ou après $keep_default jours, le serveur efface le fichier.
F*EX n'est pas un système d'archivage!
<p>
Voir les <a href="/FAQ/FAQ.html">questions & réponses</a>.
<p><hr><p>
<address>
  <a href="mailto:$ENV{SERVER_ADMIN}">$ENV{SERVER_ADMIN}</a><br>
</address>
EOD

$info_2 = <<EOD;
<p><hr><p>
Après soumission de votre fichier pour l'upload, vous verrez une barre de progression
(si vous avez javascript activé et que les popups sont autorisés)
<p>
<em>REMARQUE: La plupart des navigateurs ne peuvent pas uploader des fichiers > 2 GB!</em><br>
Si votre fichier est plus gros, vous devez utiliser un <a href="/fuc?show=tools">client F*EX spécial</a>.<br>
Vous devez aussi en utiliser un pour la reprise d'upload interrompu. Votre navigateur ne peut pas le faire.
<p>
Pour les utilisateurs de Firefox : ne pas appuyer sur [ESC] parce que cela stoppera l'upload !
<p>
Voir aussi la <a href="/FAQ/FAQ.html">FAQ<a>.
EOD
