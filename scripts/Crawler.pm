package Crawler;  

use strict;
use locale;
use utf8;
#use DB_File;

# prérequis : installation du module File::Type (taper cpan, puis install File::Type)  

# modules utilisés
use Encode;
use LWP::Simple;
use LWP::UserAgent;
use IO::Handle;
#~ use File::Type;
STDOUT->autoflush(1);	# permet de suivre les traces d'exécution en temps réel
binmode(STDOUT, ":utf8");

#------------------------------------------------------------------------------------------------
# code permettant d'exporter les var. et fonctions vers l'espace de nommage du module appelant (le module appelant n'aura pas à utiliser le préfixe Nomdumodule::)
use Exporter;


# définit le module courant comme une sous-classe du module Exporter, ce qui permet d'accéder à ses fonctions
our @ISA = qw(Exporter);
our @EXPORT = qw( &crawl $limitDepth $filePattern $saveDir $maxUrlGet $urlPattern  $limit $defaultLimitDepth $indexDepth $noFormData $verbose $saveFullHtml $global $guessFileType );			 # liste des variables et fonctions exportées implicitement (par défaut) vers le module appelant
our @EXPORT_OK = qw( );	# liste des variables et fonctions exportées à la demande par le module appelant, où on trouvera une invocation du type : use Nomdumolule qw(&ciao $var2);
our $VERSION		 = '1.0';						# numéro de version  




# bloc contenant les instructions exécutées dès le chargement du module
BEGIN {print "Chargement du module Crawler\n"; }


#------------------------------------------------------------------------------------------------
# Déclarations des variables globales


# Déclaration des variables globales partagées par le module appelant
our $limit;		# limite du nombre de pages téléchargées à chaque session, pour les tests
our $defaultLimitDepth;
our $indexDepth; # profondeur max des pages d'index (à revisiter à chaque fois)
our $noFormData;
our $verbose;
our $saveFullHtml;
our $guessFileType;

our %visited;	# DBM : stockage des url déjà crawlées
					# clé : url complète de la page
					# valeur : id de la page
our %currentVisited;   # hachage des pages visitées pendant la session courante
					# clé : url complète de la page
					# valeur : id de la page


dbmopen (%visited, 'visited', 0640) or die $!;
# structures de données globales

our $global=0;

# Déclaration des variables globales locales à ce module (mais exportables)




#------------------------------------------------------------------------------------------------
# Déclaration des fonctions du module


# fonction récursive de moissonnage d'es pages
# Entrées :
# arg1 : string -> répertoire de sauvegarde
# arg2 : string -> le domaine des url à crawler (ex : http://www.lemonde.fr)
# arg3 : string -> l'url à crawler
# arg4 : string -> le pattern indiquant le cas échéant le contenu à enregistrer
# arg5 : string -> le pattern indiquant le cas échéant si l'url doit être téléchargée intégralement
# arg6 : entier -> la profondeur de la page courante

sub crawl {
	
	my $dir=shift @_;
	my $domainUrl=shift @_;
	my $url=shift @_;
	my $urlPattern=shift @_;
	my $articlePattern=shift @_;
	my $blackList=shift @_;
	my $url2download=shift @_;
	my $nameSearchPattern=shift @_;
	my $nameReplacePattern=shift @_;
	my $postData= shift @_;
	my $limitDepth= shift @_;
	my $depth=shift @_;
	
	# terminaisons de la récursion
	if (!defined($limitDepth)) {
		if ($depth == $defaultLimitDepth ) {
			$verbose && print "Pronfondeur limite atteinte\n";
			return ;
		}
	} elsif ($depth == $limitDepth ) {
 			$verbose && print "Pronfondeur limite atteinte\n";
			return ;
	}
	if ($urlPattern && $url!~/$urlPattern/ )  {				  # si la page ne fait pas partie des pages à crawler	   
 			$verbose && print "$url non prise en compte dans le pattern ($urlPattern)\n";
			return;
	}
	if ($blackList && $url=~/$blackList/)  {				  # si la page n'appartient au domaine, ou est blacklistée, abandon							
 			$verbose && print "$url blacklistée (blacklist=$blackList)\n";
			return;
	}

	# si la page a déjà été visitée, on abandonne (sauf pour les premières pages, qui sont des pages d'index)
	if (($depth >$indexDepth  && exists($visited{$url})) ||  exists($currentVisited{$url})) {
		$verbose && print "$url déjà visitée\n";
		return ;
	 }
	
	select(undef, undef, undef, 0.1); #  latence de 1/2 de sec. pour éviter d'être blacklisté
 
	# traitement de la page
	my $page=getContent($url,$postData);
	
	if (! $page)  {
		# avec la méthode get() classique
		$page=get($url);
		if ($page) {
			# si l'url n'est pas valide, abandon
			print "Page $url non téléchargeable\n";
			return;
		}
	} 
 
	# si la page courante  n'a pas encore été enregistrée (pas page d'index)
	if (!  exists($visited{$url})) {
		print "----> Traitement de $url\n";

		
		if (!exists($visited{"last"})) {
			$visited{"last"}=0;
		}
		$visited{"last"}++;
		my $id = $visited{"last"};			   # attribution d'un idPage
		
		# le cas échéant calcul du nom de fichier à partir de l'url
		if ($nameSearchPattern && $url=~/$nameSearchPattern/) {
			$id=$url;
			$id=~s/$nameSearchPattern/eval('"'.$nameReplacePattern.'"');/e;
		}
		
		$visited{$url}=$id;						   # mise à jour du hash des pages extraites dans la dB
		open(VISITED,">>visited.txt");
		print VISITED $dir."/".$id."\t".$url."\n";
		close(VISITED);
		$currentVisited{$url}=1;

		# CAS 1 : filtrage sur l'url : téléchargement de l'intégralité du document le cas échéant
		if($url2download && $url=~/$url2download/) {
			if ($page=~/charset=UTF-8/) {
				#~ print "encodage de $url en utf8\n";
				$page=decode("utf8",$page);
			}
			my $type="";
			if ($guessFileType) {
				my $ft = File::Type->new();
				$type= $ft->mime_type($page);
				$type=~s/.*\///;
				$type=".".$type;
			}
			$verbose && print "Enregistrement de $url dans $dir/$id$type (No $global)\n";
			open(OUT,">:encoding(utf8)","$dir/".$id.$type);			# copie de la page
			print OUT $page;
			close OUT;
			$global++;	
		# CAS 2 : filtrage sur le contenu trouvé dans le fichier
		} elsif ($articlePattern && $page=~/$articlePattern/is) {
			if ($page=~/charset=UTF-8/i) {
				#~ print "encodage de $url en utf8\n";
				$page=decode("utf8",$page);
			}

			if ( $saveFullHtml) {

				$verbose && print "Enregistrement de $url (No $global)\n";
				open(OUT,">:encoding(utf8)","$dir/".$id.".html");			# copie de la page
				print OUT $page;
				close OUT;
			} else {
				# $content est pris dans la dernière parenthèse capturante
				my $content="";
				if ($1) {
					$content=$1;
				} elsif ($2) {
					$content=$2;
				} elsif ($3) {
					$content=$3;
				} elsif ($4) {
					$content=$4;
				} elsif ($5) {
					$content=$5;
				} elsif ($6) {
					$content=$6;
				} elsif ($7) {
					$content=$7;
				}
				
				$verbose && print "Enregistrement du pattern trouvé dans $url\n";
				open(OUT,">:encoding(utf8)","$dir/".$id.".extract.html");			# copie de la page
				print OUT $content;
				close OUT;
			}
		
			$global++;	
		}
	}
	 
	
	# récursion : parcours des pages pointées par des hyperliens, même si la page courante a déjà été crawlée précédemment (car les liens depuis une page peuvent évoluer avec le temps : pages d'accueil générale ou d'une rubrique, commentaires sur un article, blogs, etc...)
	my @links=extractUrl($page,$url,$urlPattern,$domainUrl);
	
	#~ $verbose && print "Parcours de @links\n";
	
	foreach my $link (@links) {
		if ($global <$limit) {	# compteur pour les tests, limite l'opération à 50 pages copiées
				crawl($dir,$domainUrl,$link,$urlPattern,$articlePattern,$blackList,$url2download,$nameSearchPattern,$nameReplacePattern,$postData,$limitDepth,$depth+1);
		}	
	}
}




# But : extraction des hyperliens d'une page
#	 appelée par crawl()
# Entrées :
# arg1 : string -> le contenu d'une page web
# arg2 : string -> l'url de la page (utile pour renvoyer les url en absolu)
# arg3 : string -> pattern du domaine à retenir
# arg4 : string -> url du domaine, pour concaténation
# Sortie : liste -> liste des urls extraites d'hyperliens en absolu
sub extractUrl {
	
	my $page=shift @_;
			#~ open(OUT,">:encoding(utf8)","1bis.html");
			#~ print OUT $page;
	my $currentUrl =shift @_;
	my $urlPattern= shift @_;
	my $domainUrl= shift @_;
	my %result;
	
	# cas où l'entête contient à paramètre base pour la construction des urls relatives
	if ($page=~/<base .*href="(.*?)"/) {
		$currentUrl=$1;
	}
	
	# si l'url courante se termine par un nom de fichier, il faut le tronquer
	$currentUrl=~s/[\w\-%]+\.[\w\-%]+[^\/]*$//;
	
	while ($page =~/<a[^>]*?href\s*=\s*(["'])(.+?)["']/sig ) {
		#~ print "$2\n";
		my $url=$2;
		
		# traitement des chemins relatifs
		if ($url=~/^[\.\-\w]/ && $url!~/^http/) {
			my $slash="/";
			if ($currentUrl=~/\/$/) {
					$slash="";
			}
			$url=$currentUrl.$slash.$url;
		} elsif ($url=~/^\/.+/) {				 	# chemins commençant par "/" : il faut leur concaténéer l'url du domaine, quelle que soit l'url de la page courante  ;
															#  ex : '/voyage/video/2011/11/30/un-voyage-en-porte-conteneurs-1-2_1611334_3546.html'
															# la page courante peut elle-même être un article ; or il faut simplemet concaténer 'http://lemonde.fr' au début de l'url du lien
				$url=$domainUrl.$url;
		}
		
		# remplacement éventuel de /rep1/../rep2 par rep2
		do {} while ($url=~s/	[^\/]+		# rep1
										\/				# slash
										\.\.			# ..
										\/				# slash
										([^\/]+)		# rep2
										/$1/x);  
		
		if ($noFormData) {
			$url=~s/[\?#].*//;
		}
		
		if ($url !~/^#|mailto:|javascript:|feed:http$/ ) {
			$result{$url}=1;
		}
	}	
	
	return grep { /$urlPattern/ } keys %result;
}
	
# requête HTTP pour obtenir le contenu de la page. Les données POST sont dans le tableau %postDATA
sub getContent {
	my $url=shift;
	my $postData=shift;

	my $ua= LWP::UserAgent->new(  agent => "Linux Mozilla");
	my $response ;
	# si formulaire POST
	if ($postData ) {
		foreach my $pair (@{$postData}) {
			my ($pattern,$formValues)=@{$pair};
			if ($url=~/$pattern/) {
				# remplissage et validation
				$response = $ua->post( $url, $formValues );
				my %h=%{$formValues};
				$verbose && print "Envoi des données [".(join (",",keys %h))."]\n";
				last;
			}
		}
	} 
	if (!defined($response)) {
		$response = $ua->get( $url);
	}
	if ($response->is_success) {
		return $response->content;  # or whatever
	} else {
		print "Attention, échec de la requête ($url) :  $response->status_line\n" 
	}
	return "";
}

#------------------------------------------------------------------------------------------------
# bloc contenant les instructions exécutées à la fin de l'exécution du script appelant
# contient en général le code permettant de faire le ménage
END {}

1; # valeur de retour du module


# la compilation s'arrête ici : on peut donner la documentation du module dans dans le style POD
__END__


=head1 NOMDUMODULE


Module.type.pm - Exemple de module


=head1 SYNOPSIS


 use Module.type;
 bonjour("Paul");


=head1 DESCRIPTION


 Blabla blabla


=head2 Variables globales partagées


$s string contenant ...


@l liste contenant ...


%h hachage destiné à ...




=head2 Exports


 Fonction bonjour() et gutenTag, ainsi que $s0 (export par défaut) et @l0 (export à la demande)


=over


=item :Fonction bonjour(STRING)


Blabla


=item : Fonction gutenTag


Blabla


=back


=head1 KRAIF


(c) 2010 - Université Stendhal


=cut
