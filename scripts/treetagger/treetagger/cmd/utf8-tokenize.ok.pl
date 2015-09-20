#==============================================================================
# Script:   tokenize.ok.pl
# Auteur:   Olivier Kraif
# Objectif:  tokenisation for treetagger (en conservant dans un fichier xml le résultat de la tokenisation xml réversible
#==============================================================================

#==================================== modules externes
use IO::handle;			# import d'une librairie pour le traitement des E/S
use locale;				# paramétrage locaux pour les regex, le tri, etc.
use Getopt::Std;
use utf8;
use open ':utf8';
use Entity2uni;

STDOUT->autoflush();	# permet de vider le tampons d'écriture à mesure qu'on écrit à l'écran

binmode(STDIN,":utf8");
binmode(STDOUT,":utf8");

my ($opt_e,$opt_i,$opt_f,$opt_a);
getopts('hfeia:');

my $input="test.xml";
if (@ARGV) {
	$input=shift @ARGV;
}

#==================================== déclaration des variables globales

# character sequences which have to be cut off at the beginning of a word
my $PClitic='';

# character sequences which have to be cut off at the end of a word
my $FClitic='';

if (defined($opt_e)) {
  # English
  $FClitic = '\'(s|re|ve|d|m|em|ll)|n\'t';
}
if (defined($opt_i)) {
  # Italian
  $PClitic = '[dD][ae]ll\'|[nN]ell\'|[Aa]ll\'|[lLDd]\'|[Ss]ull\'|[Qq]uest\'|[Uu]n\'|[Ss]enz\'|[Tt]utt\'';
}
if (defined($opt_f)) {
  # French
  $PClitic = '[dcjlmnstDCJLNMST]\'|[Qq]u\'|[Jj]usqu\'|[Ll]orsqu\'';
  $FClitic = '-t-elles|-t-ils|-t-on|-ce|-elles|-ils|-je|-la|-les|-leur|-lui|-mmes|-m\'|-moi|-nous|-on|-toi|-tu|-t\'|-vous|-en|-y|-ci|-l';
}

my $abrev="";
if (defined($opt_a)) {
  die "Can't read: $opt_a: $!\n"  unless (open(FILE, $opt_a));
  while (<FILE>) {
    s/^[ \t\r\n]+//;
    s/[ \t\r\n]+$//;
    next if (/^\#/ || /^\s$/);    # ignore comments
	s/\./\./g;	# escape dots in regexp
	if ($abrev) {
		$abrev.="|".$_;
	} else {
		$abrev=$_;
	}
  }
  close FILE;
  if ($abrev) {
	$pattern_abrev='('.$abrev.')';
 }
}



# définition des motifs pour la tokenisation (attention à doubler tous les \, pour ne pas qu'ils disparaissent de la chaîne de car.)
our $pattern_num="(((\\-\\+)\\s)?(\\d+)((\\,|\\s)\\d\\d\\d)*((\\.|\\,)\\d+)?)";
our $pattern_punct="(\\.\\.\\.|[…,;:.?!()[\\]{}\"“”„—`])"; # à l'intérieur des crochets les seuls méta-car. sont ] et - 
our $pattern_email="([\\w\\-]+(\\.[\\w\\-]+)*@[\\w\\-]+(\\.[\\w\\-]+)+)";
our $pattern_url="((http:\\/\\/)?www(\\.[\\w\\-]+)+((\\/[\\w\\-]+)+\\.[\\w\\-]+)?)";
our $pattern_word="([\\w\\-']+)"; 	# attention \w n'inclut pas les car accentués si on oublie use locale
our $pattern_char="([\\W])"; 		# définition d'un caractère isolé n'appartenant pas à un des précédents tokens
# on stocke les motifs dans une liste (ainsi que les types correspondants) afin de les traiter dans une boucle for
our @patterns=($pattern_email,$pattern_url,$pattern_num,$pattern_punct,$pattern_word,$pattern_char);
our @types=("eml","url","num","punct","word","char"); # il faut ajouter le type "spc" pour les espaces
# attention : l'ordre des motifs n'est pas indifférents (les plus contraints et moins ambigus d'abord).

if ($abrev) {
	unshift(@patterns,$pattern_abrev);
	unshift(@types,"abrev");
}

#******************************************************************************************************************* sous programmes 


#===================================== texte2Toks ()

# Tokenization of a string without xml tags
#Input : 
# 	* arg1 : string to tokenize
# Output :
# 	* return @toks a list of pairs (token,type)

sub text2toks {

	my $text=shift @_;
	my ($tok,$tokType);
	my @toks;

		
	while ($text !~/^\s*$/) { 		# on sort de la boucle quand $text est vide ou ne contient que des espaces
		if ($text=~/^(\s+)(.*)/) { 	# lecture et suppression d'éventuels espaces en début de ligne
			push(@toks,[$1,"spc"]); # on enregistre les espacements
			$text=$2;
			next;
		}
		for (my $i=0;$i<=$#patterns;$i++) {
			if ($text=~/^$patterns[$i]/) {				# les éventuels espaces de tête sont avalés à ce niveau !!!
				$tok=$1;								# on enregistre le token
				$text=substr($text,length($tok));	# on ne peut utiliser $2, car les motifs contiennent des sous-parties parenthésées
				$tokType=$types[$i];
				last;				# on sort de la boucle for (on ne veut reconnaître qu'un seul token à chaque passage)
			}
		}
		# traitement des clitiques séparés par ' ou -
		if ($tokType eq "word") {
			if ($PClitic && $tok=~/^($PClitic)(.*)/) {
				$tok=$2;
				if ($1) {
					push(@toks, [$1,"word"]);
				}
			}
			if ($FClitic && $tok=~/^(.*)($FClitic)$/) {
				$tok=$2;
				if ($1) {
					push(@toks, [$1,"word"]);
				}
			}
		}
		#~ print "$tok -> $tokType\n";
		push (@toks, [$tok,$tokType]);
	}
	# il se peut qu'il reste des blancs en fin de chaîne
	if ($text=~/^\s+$/) {
		push(@toks,[$text,"spc"])
	}
	return (@toks);
}



#****************************************************************************************************** Main

my $buffer="";
my $idTok=0;

open(IN,"<:encoding(utf8)",$input);
$output=$input.".tok";
if ($input=~/(.*)\.(\w\w\w)$/) {
	$output="$1.tok.$2";
}
open(XML,">:encoding(utf8)",$output);
while (!eof(IN)) {
	# reading until the next tag
	while ( !eof(IN) && $buffer!~/^([^<]*)(<[^>]*>)(.*)$/s ) {
		$buffer.=<IN>;
	}
	
	my $before=$buffer;
	my $tag="";
	my $after="";
	
	if ($buffer=~/^([^<]*)(<[^>]*>)(.*)$/s) {
		$before=$1;
		$tag=$2;
		$after=$3;
	}
		
	if (!defined($before)) { $before=""; }
	if (!defined($after)) { $after=""; }
	
	# convert all entities in utf8 char
	$before=convertEntities($before,1);
	my @toks=text2toks($before);
	my $nb=@toks;

	while (@toks) {
		my $adr=shift(@toks);
		my $tok=$adr->[0];
		my $type=$adr->[1];
		
		if ($tok) {
			my $spc="";

			# blankspaces that follow a token are conserved in the spc attribute
			if ($type ne "spc") {
				if (defined($toks[0][1]) && $toks[0][1] eq "spc") {
					$spc=$toks[0][0];
					shift @toks;
				} 
				
				print STDOUT $tok."\n";
				$idTok++;
				
				$tok=~s/"/&quot;/g;
				$spc=~s/\n/&#013;/g;
				print XML "<tok id=\"$idTok\" w=\"$tok\" spc=\"$spc\" />\n";		# other blankspaces are skipped
			}
		}

	}
	if ($tag) {
		print STDOUT $tag."\n";
		print XML $tag."\n";
	}
	$buffer=$after;

}
close(IN);
close(XML);

