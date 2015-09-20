#!/usr/bin/perl

###	Transforme les fichiers issus de treetagger en txt etiquettÃ© ###	

# USAGE : principaux paramÃ¨tres

# $dataPath : le rÃ©pertoire contenant les fichiers Ã  traiter 
# $filePattern :  la forme des fichiers Ã  traiter

use strict;
use utf8;
use warnings;
use Encode;

binmode(STDOUT,":utf8");

# variables globales

# paramÃ¨tres du script
my $dataPath="corpus";
my $filePattern="PB.*tt\|informatique_article_.*tt\|article-.*tt\$";
my $outputExt=".ttxt";

my $supprExt=1;	# supprime l'extension de l'ancien fichier pour la remplacer par txt
my $verbose=1;	# boolÃ©en indiquant s'il faut afficher les traces d'exÃ©cution
my $recursion=1;# boolÃ©en indiquant s'il faut parcourir les rÃ©pertoires rÃ©cursivement
my $endOfLinePattern="\tSENT";	# pattern indiquant où il faut ajouter des retours chariot

processDir($dataPath);

#****************************************************** fonction
# traitement rÃ©cursif des dossiers
sub processDir {
	my $dir=shift;
	my $DIR;
	
	opendir($DIR,$dir);
	while (my $file=readdir($DIR)) {
		my $fileIn=$dir."/".$file;
		if (-f  $fileIn && $file=~/$filePattern/) {
			my $fileOut=$fileIn;
			# suppression de l'extension
			if ($supprExt) {
				$fileOut=~s/\.[^.]+$//;
			}
			$fileOut.=$outputExt;
			$verbose && print "Traitement de $fileIn et crÃ©ation de $fileOut\n";

			open(TTG,"<",$fileIn);
			open(TXT,">",$fileOut);
			while (! eof(TTG) ) {
				my $line=<TTG>;
				if ($line=~/(.*)\t(.*)\t(.*)/) {
					my $form=$1;
					my $cat=$2;
					my $lem=$3;
					if ($cat=~/(.+):.+/) {
						$cat=$1;
					}
					if ($cat=~/^[.,:;()]$/) {
						$cat="PUN";
					}
					print TXT $form."_".$lem."_".$cat." ";
				}
				if ($line=~/$endOfLinePattern/) {
					print TXT "\n";
				}
			}
			close(TXT);
			close(TTG);
		}

		if (-d $fileIn && $file ne "." && $file ne ".." && $recursion) {
			processDir($fileIn);
		}
	}
	closedir($DIR);
}
