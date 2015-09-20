#!/usr/bin/perl

# Usage : perl exec_treetagger.pl
# les paramètres (répertoire à traiter et fichiers à traiter) sont à modifier directement dans le script

use strict;
use IO::Handle;
STDOUT->autoflush();

# paramètres du script
my $path=".";
my $filePattern="*\\.txt\$";				# forme des fichiers à traiter
my $recursion=1;								# traitement récursif des répertoire
my $ttExtension=".tt";						# extension à rajouter pour les fichiers en sortie

# environnement de treetagger
my $ttPath="D:/Mesdoc~1/Recherches/Dvelop~1/treetagger";	# chemin d'installation de treetagger
my $options="-token -lemma -sgml -no-unknown";					# options de treetagger
my $language="french";
my $parFile="$language-utf8.par";											# nom du fichier de paramètres à utiliser
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
			my $command="perl $ttPath/cmd/utf8-tokenize.perl -f -a $ttPath/lib/$language-abbreviations-utf8 $file | $ttPath/bin/tree-tagger.exe $ttPath/lib/$parFile $options > $file$ttExtension";

			if ($win) {
				$command=~s/\//\\/g;
			}
			print "Traitement de $file et creatiion de $file$ttExtension$\n";
			system( $command);
		}
		if (-d $f && $file ne "." && $file ne ".." && $recursion) {
			processDir($f);
		}
	}
	closedir($DIR);
}
			
			