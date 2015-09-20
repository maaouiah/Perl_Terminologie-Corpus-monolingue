
my $ref_sources=[
	{
		# téléchargement de rapports
		url=>'http://www.europarl.europa.eu/plenary/fr/reports.html',
		domain=>'http://www.europarl.europa.eu',
		url_pattern=>'www.europarl.europa.eu/plenary/fr/reports.html|www.europarl.europa.eu/sides/getDoc.do.*A\\d-\\d\\d\\d\\d-\\d+.*DOC.*XML.*(FR|EN)',
		article_pattern=>'',
		url2download=>'www.europarl.europa.eu/sides/getDoc.do',
		name_search_pattern=>'.*(A\\d-\\d\\d\\d\\d-\\d+).*(\\w\\w)$',
		name_replace_pattern=>'$1.$2.html',
		black_list=>'',
		post_data=> [["http://www.europarl.europa.eu/plenary/fr/reports.html",{miText=>'environnement'}]],
		limit_depth=>100,
	},
	#~ {
		#~ url=>'http://www.slate.fr',
		#~ domain=>'http://www.slate.fr',
		#~ url_pattern=>'slate',
		#~ article_pattern=>'<div id="article">(.*)<\\/strong><\\/em><\\/p>',
		#~ black_list=>'slate.fr.personnalites|slate.fr.wiki',
	#~ },
	#~ {
		#~ url=>'http://www.lemonde.fr',
		#~ domain=>'http://www.lemonde.fr',
		#~ url_pattern=>'lemonde',
		#~ article_pattern=>'<!-- DEBUT  LAYOUT ARTICLE -->(.*)<!-- \\/ CONTENU ARTICLE  -->|<article .*?>(.*)<\\/article>',
		#~ black_list=>'produit-du-terroir|vins.lemonde.fr|conjugaison.lemonde|www.lemonde.fr.conjugaison|\.blog\.'
	#~ },
	#~ {
		#~ url=>'http://www.rue89.com',
		#~ domain=>'http://www.rue89.com',
		#~ url_pattern=>'rue89',
		#~ article_pattern=>'<div id="article">(.*)<div class="title89"',
		#~ black_list=>'####'
	#~ },
	#~ {
		#~ url=>'http://www.liberation.fr',
		#~ domain=>'http://www.liberation.fr',
		#~ url_pattern=>'liberation',
		#~ article_pattern=>'<div class="article">(.*)<!-- \\/\\/ Item -->',
		#~ black_list=>'www.liberation.fr\\/abonnes|programmes-podcasts|cours-anglais.liberation'
	#~ },
	#~ {
		#~ domain=>'http://www.lefigaro.fr',
		#~ url=>'http://www.lefigaro.fr',
		#~ url_pattern=>'lefigaro',
		#~ article_pattern=>'<!--sdvD=ARTICLE-->(.*)<!--sdvF=ARTICLE-->',
		#~ black_list=>'www.lefigaro.fr\\/abonnement|recherche.lefigaro.fr|blog.tvmag.lefigaro.fr|www.lefigaro.fr\\/fpservice|www.lefigaro.fr\\/marque'
	#~ },
	#~ {
		#~ domain=>'http://www.ledauphine.com',
		#~ url=>'http://www.ledauphine.com',
		#~ url_pattern=>'ledauphine',
		#~ article_pattern=>'<div class="content">(.*)<div class="content">',
		#~ black_list=>'####'
	#~ }	
];
