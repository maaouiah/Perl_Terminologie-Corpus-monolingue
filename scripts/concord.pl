#!/usr/bin/perl

# Usage : perl concord.pl
# les paramÃ¨tres (motif Ã  chercher, rÃ©pertoire Ã  traiter, fichiers Ã  traiter, nom de la concordance) sont Ã  modifier directement dans le script

use strict;
use utf8;
use warnings;
use Encode;
use locale;

binmode(STDOUT,":utf8");

use IO::Handle;
STDOUT->autoflush();

###	Extrait une concordance Ã  partir d'un ensemble de fichiers traitÃ©s avec treetagger (puis compactÃ©s au format ttxt)	###

# USAGE : 4 paramÃ¨tres principaux

# $path : le rÃ©pertoire contenant les fichiers Ã  examiner
# $filePattern : la forme des fichiers Ã  traiter
# $concordFile : le nom du fichier en sortie
# $searchPattern : le motif de recherche

# ParamÃ¨tres du script
my $path="./corpus";
my $filePattern="PB.*\\.ttxt\|informatique_article_.*\\.ttxt\|article-.*\\.ttxt\$";			# forme des fichiers Ã  traiter
my $concordFile="info.conc.txt";
# ******* MOTIF Ã  chercher pour la concordance
# pour un lemme chercher ;:							\w+_LEMME_\w+
# pour une catÃ©gorie, chercher:					 	\w+_\w+_CAT
# pour une suite de n Ã  m tokens quelconcques :	(?: [^ ]+){n,m}
my $tokens="(?: [^ ]+){0,10} ";
my $searchPattern='\w+_processeur_ADJ'.$tokens.'\w+_core_VER|\w+_ordinateur_NOM'.$tokens.'\w+_et_KON|\w+_virus_NOM'.$tokens.'\w+_programmer_VER|\w+_Internet_NOM'.$tokens.'\w+_condition_NOM\w+_article_NOM'.$tokens.'\w+_Programmation_NAM';	# pour chercher la collocation "obtenir un rÃ©sultat" (fenÃªtre de 10 mots)
#~ $searchPattern='\w+_obtenir_VER'.$tokens.'\w+_emploi_NOM';	
#~ $searchPattern='\w+_\w+_NOM\w+_de_\w+\w+_NOM';	
my $span=50;										# taille de l'empan pour la concordance
my $recursion=1;									# si =1, traitement rÃ©cursif des rÃ©pertoires
my $verbose=1;										# boolÃ©en indiquant s'il faut afficher les traces d'exÃ©cution

# MAIN

my $found=0;
open(CONCORD,">:encoding(utf8)",$concordFile);
processDir($path);
close(CONCORD);
print "\n$found occurrences trouvÃ©es !\n";

# traitement rÃ©cursif des dossiers
sub processDir {
	my $dir=shift;
	my $DIR;
	
	opendir($DIR,$dir);
	while (my $file=readdir($DIR)) {
		my $f=$dir."/".$file;
		if (-f  $f && $file=~/$filePattern/) {
			my $foundInFile=0;
			$verbose && print "\nTraitement du fichier $f\n";
			open(IN,"<:encoding(utf8)",$f);
			while (!eof(IN)) {
				my $line=<IN>;
				my $span2=2*$span;
				
				while ($line=~/(.*) ($searchPattern) (.{0,$span2})/ig) {
					$found++;
					$foundInFile=1;
					$verbose && print ".";
						
					# on rÃ©cupÃ¨re le contexte gauche
					my $left=$1;
					# on rÃ©cupÃ¨re le pivot
					my $pivot=$2;
					# on rÃ©cupÃ¨re le contexte droit 
					my $right=$3;
		
					# dans les sÃ©quences FORM_LEM_CAT, on supprime _LEM_CAT (qui n'Ã©tait utile que pour la recherche, mais qu'on Ã©limine de la concordance)
					$left=~s/^[^ ]+//;	# suppression du premier token Ã  gauche (fragmentaire)
					$right=~s/[^ ]+$//; # suppression du dernier token Ã  droite (fragmentaire)
					$left=~s/_[^_ ]+_[^_ ]+//g;
					$pivot=~s/_[^_ ]+_[^_ ]+//g;
					$right=~s/_[^_ ]+_[^_ ]+//g;
					
					# ajout des caractÃ¨res de remplissage Ã  gauche
					$left=(" "x$span).$left;
					$left=~s/.*(.{$span})$/$1/;
					print CONCORD "$left\t<< $pivot >>\t$right\t$f\n";
				}
			}
			close(IN);
			# saut de ligne Ã  chaque fichier
			$foundInFile && print CONCORD "\n";
		}
		if (-d $f && $file ne "." && $file ne ".." && $recursion) {
			processDir($f);
		}
	}
	closedir($DIR);
}
