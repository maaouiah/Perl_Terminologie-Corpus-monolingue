#!/usr/bin/perl

# Usage : perl exec_treetagger.pl
# les paramètres (répertoire à traiter et fichiers à traiter) sont à modifier directement dans le script

use strict;
use IO::Handle;
STDOUT->autoflush();

# paramètres du script
my $path="./corpus";
my $filePattern="PB.*\\.txt\|informatique_article_.*\\.txt\|article-.*\\.txt\$";			# forme des fichiers à traiter
my $recursion=1;								# traitement récursif des répertoire
my $ttExtension=".tt";						# extension à rajouter pour les fichiers en sortie
my $supprExt=1;									# si =1, l'extension du fichier est remplacée par $ttExtension. Sinon on concatène


# environnement de treetagger
my $ttPath="D:\\etude\\Master\\2em_semestre\\Kraif\\corpus_ecrits\\TP\\Toolkit\\treetagger";	# chemin d'installation de treetagger
my $options="-token -lemma -sgml -no-unknown";					# options de treetagger
my $language="french-utf8";
my $parFile="$language.par";											# nom du fichier de paramètres à utiliser
my $win=1; 																			# indique si l'exécution est sous windows

# MAIN
processDir($path);

# traitement récursif des dossiers
sub processDir {
	my $dir=shift;
	my $DIR;
	
	opendir($DIR,$dir);
	while (my $file=readdir($DIR)) {
		my $f=$dir."/".$file;
		if (-f  $f && $file=~/$filePattern/) {
			my $fileOut=$f;
			# suppression de l'extension
			if ($supprExt) {
				$fileOut=~s/\.[^.]+$//;
			}
			my $command="perl $ttPath/cmd/utf8-tokenize.perl -f -a $ttPath/lib/$language-abbreviations $f | $ttPath/bin/tree-tagger.exe $ttPath/lib/$parFile $options > $fileOut$ttExtension";

			if ($win) {
				$command=~s/\//\\/g;
			}
			print "Traitement de $f et creation de $fileOut$ttExtension\n";
			system( $command);
		}
		if (-d $f && $file ne "." && $file ne ".." && $recursion) {
			processDir($f);
		}
	}
	closedir($DIR);
}
			
			