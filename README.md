Projet Master 1 (Perl) : Projet Corpus Ecrit
===================

###Objectif

Le but principal de ce projet est d’extraire des pages web dans le domaine informatique afin d’obtenir un corpus. Un ensemble de traitements ont été faits sur ce corpus pour arriver à extraire les concordances.

######Les étapes à suivre pour arriver à un corpus annoté :

- Extraction des pages web.
- Transformation sous format texte.
- Etiqueter le corpus.
- Extraction des concordances.

######Les sources de corpus utilisées:

J'ai choisi de travailler sur le domaine informatique. Le corpus a été obtenu à partir des liens suivants :
	- http://www.ldlc.com
	- http://www.zmaster.fr
	- http://www.tplpc.com
Cette étape était faite avec le script PERL donné en cours « launch_crawler.pl»

######Le volume du corpus constitué :
Notre corpus contient 175 510 mots.

######Les formats et encodages sources :
Pour réaliser notre corpus j'ai fait des traitements sur des pages html.
L’encodage d’origine est UTF-8

######Les traitements effectués :
Tout d’abord, j'ai téléchargé les pages web avec launch_crawler.pl, ce script met les fichiers téléchargé dans corpus/html et fait la création des dossiers sous le dossier html. Il nomme ensuite les dossiers créés à l’aide de chiffres par ordre croissant en commençant par 1 pour l’extraction du premier site. Le compteur de nomination de dossiers est incrémenté à chaque nouveau site. Une fois que j'ai obtenu ces pages nous faisons la conversion de HTML vers TXT avec html2txt.pl. Ce script génère des fichiers textes dans corpus/txt. L’étiquetage se fait ensuite à l’aide de exec_treetagger.pl afin de trouver la catégorie syntaxique de chaque mot. Ce script permet la création des fichiers tt à partir desquels nous faisons la conversion vers ttxt avec tt2taggedtxt.pl. L’avant dernière étape se fait à l’aide d’un script qui génère des fichiers contenant tous les mots du corpus suivi d’un « _ » et de la catégorie du mot. Enfin nous réalisons l’extraction de concordance avec concord.pl.

######Les problèmes rencontrés (format/encodage/etc.) :
- Crawler ne peut pas extraire toutes les pages.
- S’il trouve des espaces dans l’url il affiche que la page est non téléchargeable.
- Si l’encodage est autre que UTF-8 il affiche un problème d’affichage des certains caractères

######Discussion sur les résultats obtenus :
J'ai constaté que le script ne trouvent pas tous les mots dont j'ai besoin mais il respecte l’expression régulière par exemple nous lui donnons le mot à gauche et le mot à droite et n’importe quoi au milieu. Donc il va chercher les phrases encadrées par ces deux mots. Ilya trop du bruit le script concord.pl il nous affiche les mêmes phrases plusieurs fois.
Pour conclure ce qui est bien ce qu’il nous affiche tous les résultats engendrés par l’expression régulière mais il fait la redondance des résultats.
