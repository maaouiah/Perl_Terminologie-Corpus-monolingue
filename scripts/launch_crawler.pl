use strict;
use Crawler;
use IO::Handle;
use utf8;

# INSTALLATION : prÃ©requis : installation du module File::Type (taper cpan, puis install File::Type)
# le module Crawler.pm doit Ã©galement Ãªtre accessible dans le rÃ©pertoire courant. Au besoin, si la launch_crawler est appelÃ© depuis un autre rÃ©pertoire, ajouter : 
# use lib "CHEMIN_VERS_PM"; 

# USAGE : 
#		* rÃ©gler les paramÃ¨tres ci-dessous
#		* dÃ©clarer les sources Ã  tÃ©lÃ©charger et leurs propriÃ©tÃ©s
#		* les fichiers tÃ©lÃ©chargÃ©s sont enregistrÃ©s dans les sous-rÃ©pertoires 1, 2, etc. (un rÃ©pertoire par source) du rÃ©pertoire $targetPath
#		* exÃ©cuter : perl launch_crawler.pl

# FONCTIONNEMENT : 
# A chaque exÃ©cution on lance une nouvelle session de crawling : pour chaque site dÃ©clarÃ© dans le tableau ref_source, on crawle les pages en partant de l'url de dÃ©part. Le crawling est limitÃ© par :
#		* les pages dÃ©jÃ  visitÃ©es, enregistrÃ©es dans le fichier "visited" qui ne sont pas revisitÃ©es, sauf les pages d'index situÃ©es Ã  une profondeur infÃ©rieure ou Ã©gale Ã  $indexDepth
#		(il suffit de supprimer le fichier "visited" pour recommencer le crawling Ã  0)
#		* la limite du nombre de pages tÃ©lÃ©chargÃ©es ($limit) : dÃ¨s ce nombre atteint le crawling s'arrÃªte
#		* la limite de profondeur indiquÃ©e dans la propriÃ©tÃ© "limit_depth" de la source. Si cette propriÃ©tÃ© n'est pas indiquÃ©e, on utilise la valeur spÃ©cifiÃ©e par la variable $defaultLimitDepth
#		* le pattern dÃ©fini (le cas Ã©chÃ©ant) par la propriÃ©tÃ© "url_pattern" qui dÃ©finit la forme des urls Ã  suivre. ATTENTION : l'url de dÃ©part doit aussi se conformer Ã  ce pattern, sinon le crawling s'arrÃªte immÃ©diatement
# 		* ne sont tÃ©lÃ©chargÃ©es que les pages dont l'url matche avec  "url2download" (enregistrement intÃ©gral) ou dont le contenu matche avec "article_pattern" (enregistrement partiel si $saveFullHtml=0 - seule l'expression capturÃ©e dans $1 est enregistrÃ©e)

STDOUT->autoflush();

#****************************************************************** PARAMETRES
# principaux paramÃ¨tres

our $limit=10;				# limite du nombre de pages tÃ©lÃ©chargÃ©es Ã  chaque session de tÃ©lÃ©chargement
our $defaultLimitDepth=2;		# limite de profondeur dans le parcours rÃ©cursif des liens
our $indexDepth=3; 	# profondeur max des pages Ã  revisiter Ã  chaque fois (pages d'index)
our $noFormData=0;	# indique si les donnÃ©es GET ( .data=value&data=value, etc.) doivent Ãªtre conservÃ©es dans les url Ã  parcourir
our $saveFullHtml=0;	#indique si on enregistre la totalitÃ© du fichier oÃ¹ seulement le fragment qui correspond au pattern cherchÃ©
my $targetPath="../corpus/html";	 # rÃ©pertoire oÃ¹ on sauvegarde les pages tÃ©lÃ©chargÃ©es, classÃ©es dans des sous-rÃ©pertoires .../1 .../2 .../3 en fonction des sources
our $verbose=1;			# affichage des traces d'exÃ©cution
our $guessFileType=0;	# identification automatique du type mime des pages
our $global;

# DÃ©finition des sources

# propriÃ©tÃ© des sources :
#	* url : l'url Ã  crawler
#  * domain : domaine auquel on rattache les liens commenÃ§ant par /
#	* url_pattern : regex dÃ©finissant la forme des urls des pages Ã  crawler (on peut indiquer des urls complÃ¨tes, pas seulement un domaine)
# 	* article_pattern : regex dÃ©finissant le contenu Ã  sauvegarder (seuls sont enregistrÃ©s les articles qui contiennent ce motif). Si vide, on considÃ¨re .*
#  * url2download : regex dÃ©finissant la forme des urls Ã  enregistrer. Si vide, on considÃ¨re .*
#	* name_search_pattern et name_replace_pattern: respectivement motif de recherche et chaine de remplacement permettant de construire, le cas Ã©chÃ©ant, le nom du fichier tÃ©lÃ©chargÃ© Ã  partir de l'url
#	* black_list : regex dÃ©finissant les url Ã  ne pas crawler. Si vide, on n'en tient pas compte.
#	* post_data : permet d'envoyer des donnÃ©es POST (p.ex. pour cibler une recherche d'articles) -> liste de couples [$urlPattern,%form_values]). Pour chaque url matchant $urlPattern on envoie les donnÃ©es %form_values
#  * limit_depth : profondeur limite du crawling. Si pas dÃ©fini, on utilise defaultLimitDepth

my $ref_sources=[
	#~ {
		#~ # tÃ©lÃ©chargement de rapports
		#~ domain=>'http://www.medicalnewstoday.com',
		#~ url=>'http://www.medicalnewstoday.com/articles/244972.php',
		#~ url_pattern=>'http://www.medicalnewstoday.com|http://www.medicalnewstoday.com/articles/\\d\\d\\d\\d\\d\\d',
		#~ article_pattern=>'',
		#~ url2download=>'http://www.medicalnewstoday.com/articles',
		#~ name_search_pattern=>'.*(\\d\\d\\d\\d\\d\\d).php$',
		#~ name_replace_pattern=>'$1.html',
		#~ black_list=>'',
		#~ limit_depth=>100,
	#~ },
	{
		#~ # tÃ©lÃ©chargement de rapports
		domain=>'http://www.ldlc.com',
		url=>'http://www.ldlc.com/informatique/ordinateur-de-bureau/barebone-pc/c4247/',
		url_pattern=>'http://www.ldlc.com/informatique|http://www.ldlc.com/fiche/PB.*.html',
		article_pattern=>'',
		url2download=>'http://www.ldlc.com',
		name_search_pattern=>'.*(PB.*).html$',
		name_replace_pattern=>'$1.html',
		black_list=>'',
		limit_depth=>100,
		#~ domain=>'http://www.clubic.com',
		#~ url=>'http://www.clubic.com/actualites-informatique/page_1.html',
		#~ url_pattern=>'http://www.clubic.com/actualites-informatique/page_1.html|http://www.clubic.com/actualites-informatique/page_\\d+.html|http://www.clubic.com/[-\\w]+/actualite-\\d+-[-\\w]+.html',
		#~ article_pattern=>'',
		#~ url2download=>'http://www.clubic.com',
		#~ name_search_pattern=>'.*?([^\\/]+).html.*$',		
		#~ name_replace_pattern=>'$1.html',
		#~ black_list=>'',
		#~ limit_depth=>1000
	}
	#~ ,
	#~ {
		#~ # tÃ©lÃ©chargement de rapports
		#~ domain=>'http://www.zmaster.fr',
		#~ url=>'http://www.zmaster.fr/informatique_article_.*.html#select',
		#~ url_pattern=>'http://www.zmaster.fr|http://www.zmaster.fr/informatique_article_.*.html#select/',
		#~ article_pattern=>'',
		#~ url2download=>'http://www.zmaster.fr',
		#~ name_search_pattern=>'.*(informatique_article_.*).html$',
		#~ name_replace_pattern=>'$1.html',
		#~ black_list=>'',
		#~ limit_depth=>100,
	#~ },
	#~ {
		#~ # tÃ©lÃ©chargement de rapports
		#~ domain=>'http://www.tplpc.com/modules/news/',
		#~ url=>'http://www.tplpc.com/modules/news/article-.*.html',
		#~ url_pattern=>'http://www.tplpc.com|http://www.tplpc.com/modules/news/article-.*.html',
		#~ article_pattern=>'',
		#~ url2download=>'http://www.tplpc.com/modules/news/',
		#~ name_search_pattern=>'.*(article-.*).html$',
		#~ name_replace_pattern=>'$1.html',
		#~ black_list=>'',
		#~ limit_depth=>100,
	#~ },
];
#****************************************************************** FIN PARAMETRES



#######
#APPEL DE LA FONCTION
#######

launch_crawler($ref_sources);

# procÃ©dure launch_crawler($ref_array,$depth)
#
###########
#Description
###########
#     RÃ©cupÃ¨re le code html brut de pages web non encore visitÃ©es sur des sites d'actualitÃ©.
#    Utilise pour cela la fonction crawl($dir,$domainUrl,$url,$domainPattern,$depth,$refDone) du module Crawler.pm
#     Les url des  pages d'accueil de chacun des site ('http://www.lemonde.fr' par exemple), et le pattern identifiant les pages du site ('lemonde' par exemple),  sont transmise par la fonction readUrl2Crawls()
#     Toutes les pages html pointÃ©es par hypertexte et contenant le pattern  sont rÃ©cupÃ©rÃ©es, et ce rÃ©cursivement n fois, le nombre n Ã©tant un autre paramÃ¨tre de la fonction.
#     
#     Les pages sont stockÃ©s dans : "$targetPath/indiceSource/indicePage.html",
#     oÃ¹ IndiceSource est un id attribuÃ© Ã  chacune des sources :
#     par exemple
#     le Monde : 1    ($targetPath/1)
#     le Figaro : 2    ($targetPath/2)    
#     etc...
#
#     indicePAge est un entier incrÃ©mentÃ© Ã  chaque nouvelle page rÃ©cupÃ©rÃ©e, indÃ©pendemment de la source ; il sert Ã  nommer le fichier
#     1.html : premier document
#     2.html : second document
#     etc....
#
#     Un hash %visited est mis Ã  jour, qui contient les url dÃ©jÃ  visitÃ©es et, pour chaque url, l'id numÃ©rique correspondant
#
###########
# ParamÃ¨tres
###########
#     En entrÃ©e :
#     arg1 : $ref_array : rÃ©fÃ©rence au tableau d'objets dÃ©finissant les sources : des hachages dont la structure est du type	{ url=>'http://www.ledauphine.com', domain=>'ledauphine',	article_pattern=>'<div class="content">(.*)<div class="content">',	black_list=>'' }
#     arg2 : $limitDepth : entier : le nombre maximum de niveaux de liens hypertextes Ã  explorer
#
#     En sortie : rien
#
###########
# Traitements
###########
#             Stockage des pages web dans le dossier $targetPath
#            Mise Ã  jour dans la base de donÃ©es du hash %visited
#                    clÃ©s : url complÃ¨te dâ€™une page
#                    valeurs : id de la page
#


sub launch_crawler
{    
    my $ref_array = shift @_;
    our %visited;    # DBM : stockage des url dÃ©jÃ  crawlÃ©es dans la dB (le tie est fait dans le module Crawler.pm)
                            # clÃ© : url de la page
                            # valeur : id  de la page     

    
    if (! -e $targetPath)                    # crÃ©ation Ã©ventuelle du rÃ©pertoire de sauvegarde des pages html
    {
            mkdir $targetPath or die "impossible de crÃ©er le rÃ©pertoire '$targetPath'\n";
    }
    
    for (my $i=0; $i< @{$ref_array};$i++)            # pour chaque site
    {
            
            # construction de l'identifiant du site ($idSource)  (1 -> le monde, 2 -> le Figaro, etc...)
            my $idSource = $i+1;    
    
            
            my $dir="$targetPath/$idSource";                    # crÃ©ation Ã©ventuelle du sous-rÃ©pertoire pour le site traitÃ©
            if(! -e $dir)
            {
                    mkdir $dir or die "impossible de crÃ©er le sous-rÃ©pertoire '$targetPath/$idSource'\n";
            }
            
			$verbose && print "crawl de ".$ref_array->[$i]->{url}."\n";
			
			# reinitialisation pour chaque appel
			$global=0;
            crawl (	$dir,$ref_array->[$i]->{domain},
						$ref_array->[$i]->{url},
						$ref_array->[$i]->{url_pattern},
						$ref_array->[$i]->{article_pattern},
						$ref_array->[$i]->{black_list},
						$ref_array->[$i]->{url2download},
						$ref_array->[$i]->{name_search_pattern},
						$ref_array->[$i]->{name_replace_pattern},
						$ref_array->[$i]->{post_data},
						$ref_array->[$i]->{limit_depth},
						0
					)    #  lancement du crawler    
    }
    
    dbmclose( %visited );
}


