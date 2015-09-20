#!/usr/bin/perl

# Usage : perl exec_treetagger.pl
# les param�tres (r�pertoire � traiter et fichiers � traiter) sont � modifier directement dans le script

use strict;
use IO::Handle;
STDOUT->autoflush();

# param�tres du script
my $path=".";
my $filePattern="*\\.txt\$";				# forme des fichiers � traiter
my $recursion=1;								# traitement r�cursif des r�pertoire
my $ttExtension=".tt";						# extension � rajouter pour les fichiers en sortie

# environnement de treetagger
my $ttPath="D:/Mesdoc~1/Recherches/Dvelop~1/treetagger";	# chemin d'installation de treetagger
my $options="-token -lemma -sgml -no-unknown";					# options de treetagger
my $language="french";
my $parFile="$language-utf8.par";											# nom du fichier de param�tres � utiliser
my $win=1; 																			# indique si l'ex�cution est sous windows

# MAIN
processDir($path);

# traitement r�cursif des dossiers
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
			
			