#!/usr/bin/perl

###	Transforme les fichiers html d'un rÃ©pertoire en txt	###

# USAGE : trois paramÃ¨tres principaux

# $htmlPath : le rÃ©pertoire contenant les fichiers HTML Ã  convertir
# $txtPath : le rÃ©pertoire contenant les fichiers TXT extraits
# $filePattern =  la forme des fichiers Ã  traiter

use strict;
use utf8;
use warnings;
use Encode;
use Entity2uni;	# pour la conversion des entitÃ©s html en caractÃ¨res unicode
use IO::Handle;
STDOUT->autoflush();

binmode(STDOUT,":utf8");

# ParamÃ¨tres du script

my $dataPath="corpus"; #chemin pour accÃ©der au corpus Ã   traiter
my $filePattern=".*html";
my $htmlPath="$dataPath/html";
my $txtPath="$dataPath/txt";
my $supprExt=1;				# supprime l'extension de l'ancien fichier pour la remplacer par txt
my $verbose=1;				# boolÃ©en indiquant s'il faut afficher les traces d'exÃ©cution
my $recursion=1;			# si =1, traitement rÃ©cursif des rÃ©pertoires


# crÃ©ation du rÃ©pertoire txt s'il n'existe pas
if (! -d $txtPath) {
	mkdir $txtPath or die "impossible de crÃ©er le rÃ©pertoire $txtPath\n";
}

extractText("");

#------------------------------------------------------------------------------------------ Fonctions

#------------------------------- FONCTION HTML2TXT-------------------------------#
# But :  dÃ©balisage du texte
# entrÃ©e : 
#	arg1 -> string, contenu du fichier html
# retour : string, le texte dÃ©balisÃ©
	
sub html2txt {
	my $text = shift(@_);

	my @deleteTags=("script","style","head");
	my @blockTags=("p","div","h1","h2","h3","li","br","hr","td");

	# suppression des retours chariots

	$text=~s/\n//g;

	# suppression des commentaires
	$text=~s/<!--.*?-->//sg;

	# suppression des sections CDATA
	$text=~s/<![CDATA[.*?]]>//sg;

	# cas 1 : Ã©limination des balises Ã  contenu

	foreach my $deleteTag (@deleteTags) {
		$text=~s/<$deleteTag.*?<\/$deleteTag>//sg;
	}

	# cas 2 : remplacement des balises de block

	foreach my $blockTag (@blockTags) {
		$text=~s/<\/$blockTag>|<$blockTag\/>/\n/sg;
	}

	#  cas 3 : Ã©limination des balises restantes
	$text =~s/<[^>]*>//sg;

	# transformation des entitÃ©s
	$text=convertEntities($text,0);

	return $text;

}


#------------------------------- FONCTION EXTRACT-TEXT-------------------------------#
# but : parcourir l'arborescence des dossiers oÃ¹ sont enregistrÃ©es les pages html
# 	les ouvrir, appliquer le traitement de dÃ©balisage,  et enregistrer le rÃ©sultat dans un fichier .txt
# entrÃ©e : le chemin du dossier courant $currentPath Ã  traiter rÃ©cursivement
# sortie : les fichiers txt extraits dans le dossier $currentTxtPath


sub extractText{	
	my $currentPath=shift @_;

	my $DIR;
	my $currentHtmlPath=$htmlPath.$currentPath;
	my $currentTxtPath=$txtPath.$currentPath;
	
	if (! -d $currentTxtPath) {
		mkdir $currentTxtPath or die "Impossible de crÃ©er le rÃ©pertoire $currentTxtPath\n";
	}
	
	if ( -e $currentHtmlPath) {
		opendir($DIR,$currentHtmlPath);
		while (my $name=readdir($DIR)) {
			if (-d $currentHtmlPath."/".$name && $name ne "." && $name ne ".." && $recursion) { # sous-rÃ©pertoire Ã  traiter
				extractText($currentPath."/".$name);
			}
			if ($name =~/$filePattern/ && -f $currentHtmlPath."/".$name ) {
			
				my $htmlFile= $currentHtmlPath."/".$name;
				my $txtFile= $currentTxtPath."/".$name;
				if ($supprExt) {
					$txtFile=~s/\.\w+$/.txt/; 							# on transforme l'extension en txt
				} else {
					$txtFile=$txtFile.".txt"; 							# on ajoute l'extension  txt
				}
				$verbose && print "Traitement du fichier $htmlFile et crÃ©ation de $txtFile\n";
				# lecture du fichier HTML
				open(HTML,"<:encoding(utf8)",$htmlFile);
				my $htmlContent=join("",<HTML>);
				close(HTML);
				
				my $txtContent=html2txt($htmlContent);	# on apelle la fonction html2txt, qui fait un traitement sur le code html pour en extraire le texte brut
				open(TXT,">:encoding(utf8)",$txtFile);
				print TXT $txtContent;
				close(TXT);
			}																# on ferme le repertoire en lecture
		}
		closedir($DIR);
	} else {
		print "Il n'existe pas de rÃ©pertoire $currentHtmlPath !\n";
	}	
}
