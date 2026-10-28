<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:bib="urn:elec:bibliographie"
  exclude-result-prefixes="tei xs bib">
  <!-- CJC (Corpus Juris Civilis) : surcharge de hteiml, réécrite le 28/10/2026 en partant du rendu
       hteiml nu (la feuille précédente ne gardait plus que des modèles désactivés). Une seule feuille
       pour les 48 ressources : éditions (Jostice et plet, Code, Codi, Digeste, Authentiques,
       Institutes, Tres libri) et notices descriptives des traductions (description de manuscrits).
       La présentation est portée par la CSS (cjc.customCss.css). -->

  <!-- ==== 0. DÉCLARATIONS : imports, sortie, paramètres, variables, clés, fonctions ==== -->
  <xsl:import href="../../renderers/hteiml/xsl/tei2html.xsl"/>
  <!-- Bibliographies des notices (listBibl) : module commun, importé APRÈS hteiml. -->
  <xsl:import href="bibliographie.xsl"/>
  <!-- indent="no" : l'indentation de hteiml glissait un blanc entre un appel de note et la ponctuation qui le suit. -->
  <xsl:output indent="no"/>
  <!-- Stemmas des notices, copiés dans dots-vue/public/images/cjc/ (data/cjc_notices/*.png). -->
  <xsl:variable name="cjc-images" select="'../../images/cjc/'"/>

  <!-- ==== 1. HISTORIQUE : surcharge reprise de la feuille précédente (notices) ==== -->
  <!-- Contenu des manuscrits (msItem) : la grille « Locus / Incipit » de la feuille d'août 2026 est
       gardée. Un msItem qui regroupe des msItem sans petits-enfants (une « section ») donne son
       en-tête puis un tableau, une ligne par sous-item ; un groupe de groupes s'ouvre seulement ;
       un msItem isolé directement sous msContents fait un tableau d'une ligne. -->
  <xsl:template match="tei:msItem[tei:msItem/tei:msItem]" priority="30">
    <section class="msItem">
      <xsl:call-template name="cjc-msitem-tete"/>
      <xsl:apply-templates select="tei:msItem"/>
    </section>
  </xsl:template>
  <xsl:template match="tei:msItem[tei:msItem][not(tei:msItem/tei:msItem)]" priority="20">
    <section class="msItem">
      <xsl:call-template name="cjc-msitem-tete"/>
      <xsl:call-template name="cjc-msitems-tableau">
        <xsl:with-param name="lignes" select="tei:msItem"/>
      </xsl:call-template>
    </section>
  </xsl:template>
  <xsl:template match="tei:msContents/tei:msItem[not(tei:msItem)]" priority="20">
    <xsl:call-template name="cjc-msitems-tableau">
      <xsl:with-param name="lignes" select="."/>
    </xsl:call-template>
  </xsl:template>
  <xsl:template match="tei:msItem">
    <div class="msItem"><xsl:apply-templates/></div>
  </xsl:template>

  <xsl:template name="cjc-msitems-tableau">
    <xsl:param name="lignes"/>
    <div class="table-wrap">
      <table class="msItems">
        <thead>
          <tr><th class="locus">Locus</th><th class="incipit">Incipit</th></tr>
        </thead>
        <tbody>
          <xsl:apply-templates select="$lignes" mode="cjc-msitem-ligne"/>
        </tbody>
      </table>
    </div>
  </xsl:template>
  <xsl:template match="tei:msItem" mode="cjc-msitem-ligne">
    <tr class="msItem">
      <xsl:if test="@xml:id"><xsl:attribute name="id" select="@xml:id"/></xsl:if>
      <td>
        <xsl:for-each select="tei:title[1]">
          <cite class="title"><xsl:apply-templates/></cite>
        </xsl:for-each>
        <xsl:for-each select="tei:locus">
          <span class="locus"><xsl:call-template name="cjc-locus"/></span>
        </xsl:for-each>
      </td>
      <td>
        <xsl:apply-templates select="node()[not(self::tei:locus)][not(self::tei:title[not(preceding-sibling::tei:title)])]"/>
      </td>
    </tr>
  </xsl:template>

  <!-- En-tête d'un groupe : titre et foliotation sur une ligne, puis incipit, explicit, notes. -->
  <xsl:template name="cjc-msitem-tete">
    <xsl:if test="tei:title | tei:locus">
      <p class="msItem-titre">
        <xsl:for-each select="tei:title">
          <xsl:if test="position() > 1"><xsl:text> </xsl:text></xsl:if>
          <xsl:apply-templates/>
        </xsl:for-each>
        <xsl:for-each select="tei:locus">
          <xsl:text> </xsl:text>
          <span class="locus">(<xsl:call-template name="cjc-locus"/>)</span>
        </xsl:for-each>
      </p>
    </xsl:if>
    <xsl:apply-templates select="*[not(self::tei:title | self::tei:locus | self::tei:msItem)]"/>
  </xsl:template>

  <!-- ==== 2. BLOCS HTEIML GÉNÉRIQUES : enveloppe dts:wrapper, notes, apparat critique, bibliographie (listBibl) ==== -->
  <!-- Fragment DTS : hteiml affiche l'enveloppe en rouge. Un fragment qui contient un tei:text
       (titre de Jostice et plet) sort déjà ses notes ; les autres (titres du Code, du Digeste,
       des Authentiques…, pages des notices) les perdaient : on les appelle ici. -->
  <xsl:template match="*[local-name() = 'wrapper']" priority="20">
    <xsl:apply-templates/>
    <xsl:if test="not(.//tei:text) and (.//tei:note[not(@place = 'margin')] or .//tei:app)">
      <xsl:call-template name="footnotes">
        <xsl:with-param name="cont" select="."/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Apparat critique (Codi, notices) : hteiml n'avait pas de numéro pour les variantes (appel vide).
       Modèle note-n de hteiml repris, comme pour la CID : variantes en lettres (a, b, c…) ; notes
       portées par un <app> hors du décompte des notes. -->
  <xsl:template name="note-n">
    <xsl:variable name="resp" select="@resp"/>
    <xsl:variable name="hasformat" select="@rend != '' and boolean(translate(substring-before(concat(@rend, ' '), ' '), '1AaIi', '') = '')"/>
    <xsl:choose>
      <xsl:when test="self::tei:app">
        <xsl:number count="tei:app" format="a" level="any" from="/"/>
      </xsl:when>
      <xsl:when test="@n">
        <xsl:value-of select="@n"/>
      </xsl:when>
      <!-- Renvoi à une note -->
      <xsl:when test="self::tei:ref[@type='note']">
        <xsl:for-each select="key('id', substring-after(@target, '#'))[1]">
          <xsl:call-template name="n"/>
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="$hasformat">
        <xsl:number count="tei:note[@rend=$hasformat]" format="{@rend}" level="any" from="/"/>
      </xsl:when>
      <xsl:when test="@type='app'">
        <xsl:number count="tei:note[@type='app']" format="a" level="any" from="/"/>
      </xsl:when>
      <xsl:when test="@resp='editor'">
        <xsl:number count="tei:note[@resp=$resp]" format="I" level="any" from="/"/>
      </xsl:when>
      <xsl:when test="@resp">
        <xsl:number count="tei:note[@resp=$resp]" level="any" from="/"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:number count="tei:note[not(@resp) and not(@rend) and not(parent::tei:div) and not(parent::tei:notesStmt) and not(parent::tei:app)]" level="any" from="/"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Leçon retenue : hteiml la fait toujours précéder d'une espace insécable, qui doublait le blanc
       déjà présent dans le texte (« sunt  majors », Codi). Espace seulement si le texte précédent
       finit sur un caractère (ni blanc ni apostrophe). -->
  <xsl:template match="tei:lem">
    <xsl:variable name="prev" select="string(../preceding-sibling::node()[1])"/>
    <xsl:if test="$prev != '' and matches($prev, '[^\s''’]$')">
      <xsl:text> </xsl:text>
    </xsl:if>
    <span>
      <xsl:call-template name="atts"/>
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <!-- Blanc de mise en forme du TEI entre deux éléments (« </lang>⏎   <persName> ») : dots-vue retire les
       nœuds texte faits seulement de blancs et d'un retour à la ligne, et collait les mots
       (« françaiseanonyme »). Ramené à une espace, que dots-vue garde. -->
  <xsl:template match="text()[not(normalize-space())][contains(., '&#10;')]">
    <xsl:text> </xsl:text>
  </xsl:template>

  <!-- ==== 3. PROPRE AU PROJET ==== -->
  <!-- Description de manuscrit d'une notice (msDesc sous un div) : hteiml en faisait un seul
       paragraphe en italique, texte brut. Rendu par rubriques : cote, contenu, description
       matérielle, histoire, bibliographie (module commun). -->
  <xsl:template match="tei:msDesc[parent::tei:div]" priority="5">
    <div class="msDesc">
      <xsl:if test="@xml:id"><xsl:attribute name="id" select="@xml:id"/></xsl:if>
      <xsl:apply-templates select="tei:msIdentifier" mode="cjc-cote"/>
      <xsl:apply-templates select="* except tei:msIdentifier"/>
    </div>
  </xsl:template>
  <!-- Cote en tête de notice : l'intertitre (head du div) la donne déjà ; on n'ajoute que le sigle
       (msName type="sigle" ou altIdentifier, qui porte ici le sigle et non une ancienne cote). La cote
       entière n'est écrite qu'en l'absence d'intertitre. -->
  <xsl:template match="tei:msIdentifier" mode="cjc-cote">
    <xsl:variable name="sigles" select="distinct-values((tei:msName[@type = 'sigle'], tei:altIdentifier/tei:idno)[normalize-space()] ! normalize-space(.))"/>
    <xsl:variable name="avec-cote" select="not(../../tei:head[normalize-space()])"/>
    <xsl:if test="$avec-cote or exists($sigles)">
      <p class="ms-cote">
        <xsl:if test="$avec-cote">
          <span class="ms-cote-principale">
            <xsl:value-of select="string-join((tei:settlement, tei:repository, tei:collection, tei:idno)[normalize-space()] ! normalize-space(.), ', ')"/>
          </span>
          <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:if test="exists($sigles)">
          <span class="ms-sigle">Sigle <i><xsl:value-of select="string-join($sigles, ', ')"/></i></span>
        </xsl:if>
      </p>
    </xsl:if>
  </xsl:template>
  <!-- Manuscrit appelé dans le texte (témoin du conspectus, renvoi) : « Paris, Bibl. nat. de Fr., fr. 498 »,
       sans le pays ; le sigle est déjà donné par le témoin (witness/@xml:id), sinon entre parenthèses. -->
  <xsl:template match="tei:msDesc[not(parent::tei:div)]/tei:msIdentifier" priority="5">
    <span class="msIdentifier">
      <xsl:value-of select="string-join((tei:settlement, tei:repository, tei:collection, tei:idno)[normalize-space()] ! normalize-space(.), ', ')"/>
      <xsl:if test="not(ancestor::tei:witness) and (tei:altIdentifier/tei:idno | tei:msName)[normalize-space()]">
        <xsl:text> (</xsl:text>
        <i><xsl:value-of select="normalize-space((tei:altIdentifier/tei:idno, tei:msName)[normalize-space()][1])"/></i>
        <xsl:text>)</xsl:text>
      </xsl:if>
    </span>
  </xsl:template>

  <!-- Rubriques de la description. -->
  <xsl:template match="tei:msContents">
    <section class="ms-rubrique msContents">
      <p class="ms-rubrique-titre">Contenu</p>
      <xsl:apply-templates/>
    </section>
  </xsl:template>
  <xsl:template match="tei:physDesc">
    <section class="ms-rubrique physDesc">
      <p class="ms-rubrique-titre">Description matérielle</p>
      <xsl:apply-templates/>
    </section>
  </xsl:template>
  <xsl:template match="tei:history">
    <section class="ms-rubrique history">
      <p class="ms-rubrique-titre">Histoire</p>
      <xsl:apply-templates/>
    </section>
  </xsl:template>
  <xsl:template match="tei:additional">
    <section class="ms-rubrique additional">
      <xsl:apply-templates/>
    </section>
  </xsl:template>
  <xsl:template match="tei:summary">
    <p class="summary"><xsl:apply-templates/></p>
  </xsl:template>
  <!-- Champs à intitulé : une ligne « Intitulé : texte ». -->
  <xsl:template match="tei:support | tei:extent | tei:collation | tei:condition | tei:origin | tei:bindingDesc">
    <xsl:variable name="intitule" select="map {
      'support' : 'Support', 'extent' : 'Composition', 'collation' : 'Cahiers', 'condition' : 'État',
      'origin' : 'Origine', 'bindingDesc' : 'Reliure' }(local-name())"/>
    <div class="ms-champ {local-name()}">
      <span class="ms-intitule"><xsl:value-of select="$intitule"/></span>
      <xsl:text> : </xsl:text>
      <xsl:apply-templates/>
    </div>
  </xsl:template>
  <xsl:template match="tei:origin/tei:origDate | tei:origin/tei:origPlace">
    <xsl:if test="preceding-sibling::*[1][self::tei:origDate | self::tei:origPlace]"><xsl:text>, </xsl:text></xsl:if>
    <span class="{local-name()}"><xsl:apply-templates/></span>
  </xsl:template>
  <xsl:template match="tei:provenance">
    <div class="ms-champ provenance">
      <xsl:if test="not(tei:p[1]/node()[normalize-space()][1][self::tei:label])">
        <span class="ms-intitule">Provenance</span>
        <xsl:text> : </xsl:text>
      </xsl:if>
      <xsl:apply-templates/>
    </div>
  </xsl:template>
  <!-- Les p d'un champ (reliure, provenance) restent dans la ligne du champ. -->
  <xsl:template match="tei:bindingDesc/tei:p | tei:provenance/tei:p | tei:origin/tei:p">
    <span class="p"><xsl:apply-templates/></span>
  </xsl:template>
  <xsl:template match="tei:objectDesc | tei:supportDesc | tei:handDesc | tei:decoDesc">
    <div class="{local-name()}"><xsl:apply-templates/></div>
  </xsl:template>
  <!-- Écriture, décor : l'intitulé (label) ouvre le paragraphe. -->
  <!-- Le deux-points n'est ajouté que si le texte qui suit ne l'a pas déjà (« <label>Anciennes cotes</label> : … »). -->
  <xsl:template match="tei:handDesc/tei:p/tei:label | tei:provenance/tei:p/tei:label | tei:decoNote/tei:label">
    <span class="ms-intitule"><xsl:apply-templates/></span>
    <xsl:if test="not(starts-with(normalize-space(following-sibling::node()[1][self::text()]), ':'))"><xsl:text> :</xsl:text></xsl:if>
    <xsl:text> </xsl:text>
  </xsl:template>
  <xsl:template match="tei:decoNote">
    <div class="decoNote"><xsl:apply-templates/></div>
  </xsl:template>
  <xsl:template match="tei:decoNote/tei:label[following-sibling::*[1][self::tei:p]]" priority="2"/>
  <xsl:template match="tei:decoNote/tei:p[preceding-sibling::*[1][self::tei:label]]">
    <p class="p">
      <xsl:for-each select="preceding-sibling::*[1]">
        <span class="ms-intitule"><xsl:apply-templates/></span>
        <xsl:text> : </xsl:text>
      </xsl:for-each>
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  <xsl:template match="tei:material | tei:rdgGrp">
    <span class="{local-name()}"><xsl:apply-templates/></span>
  </xsl:template>
  <xsl:template match="tei:lang">
    <span class="lang">
      <xsl:if test="@xml:lang"><xsl:attribute name="lang" select="@xml:lang"/></xsl:if>
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <!-- Incipit, explicit : en tête de groupe, avec leur intitulé ; dans le tableau, la colonne suffit. -->
  <xsl:template match="tei:incipit | tei:explicit">
    <div class="{local-name()}">
      <xsl:if test="@xml:lang"><xsl:attribute name="lang" select="@xml:lang"/></xsl:if>
      <xsl:if test="not(parent::tei:msItem[not(tei:msItem)])">
        <span class="ms-intitule"><xsl:value-of select="if (self::tei:incipit) then 'Incipit' else 'Explicit'"/></span>
        <xsl:text> : </xsl:text>
      </xsl:if>
      <xsl:apply-templates/>
    </div>
  </xsl:template>
  <!-- Foliotation : <locus from="6a" to="133b"/> vide → « f. 6a-133b ». -->
  <xsl:template name="cjc-locus">
    <xsl:choose>
      <xsl:when test="normalize-space(.) != ''"><xsl:apply-templates/></xsl:when>
      <xsl:when test="@from and @to and @to != @from">f. <xsl:value-of select="@from"/>-<xsl:value-of select="@to"/></xsl:when>
      <xsl:when test="@from">f. <xsl:value-of select="@from"/></xsl:when>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="tei:locus">
    <span class="locus"><xsl:call-template name="cjc-locus"/></span>
  </xsl:template>

  <!-- Renvois entre notices : anciens noms de fichiers du site (« authenticum.xml#fr_498 ») ramenés
       à la ressource DoTS et à la page (part) qui contient la cible ; lien relatif. -->
  <xsl:template match="tei:ref[matches(@target, '^[a-z_]+\.xml#')]" priority="5">
    <xsl:variable name="fichier" select="substring-before(@target, '#')"/>
    <xsl:variable name="page" select="map {
      'authenticum.xml' : 'justinien_authenticum_notice?refId=fran%C3%A7aises',
      'codex.xml' : 'justinien_codex_notice?refId=sommes_code',
      'digestum_vetus.xml' : 'justinien_digestus-vetus_notice?refId=fran%C3%A7aises' }($fichier)"/>
    <xsl:choose>
      <xsl:when test="$page">
        <a class="ref" href="{$page}#{substring-after(@target, '#')}"><xsl:apply-templates/></a>
      </xsl:when>
      <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Stemma : image du dépôt. L'arbre encodé qui la suit (eTree) dit la même chose : il n'est
       affiché qu'en l'absence d'image, en liste emboîtée. -->
  <xsl:template match="tei:graphic">
    <img src="{$cjc-images}{@url}" alt="Stemma" loading="lazy"/>
  </xsl:template>
  <xsl:template match="tei:eTree[preceding-sibling::*[1][self::tei:figure]]" priority="5"/>
  <xsl:template match="tei:eTree | tei:eLeaf">
    <xsl:element name="{if (parent::tei:eTree) then 'li' else 'div'}">
      <xsl:attribute name="class" select="string-join(('stemma', local-name(), @type), ' ')"/>
      <span class="stemma-noeud"><xsl:apply-templates select="tei:label/node()"/></span>
      <xsl:if test="tei:eTree | tei:eLeaf">
        <ul><xsl:apply-templates select="tei:eTree | tei:eLeaf"/></ul>
      </xsl:if>
    </xsl:element>
  </xsl:template>

  <!-- Lacune matérielle : « […] » (hteiml écrivait la raison brute, en anglais : « [damage] »). -->
  <xsl:template match="tei:gap[@reason]" priority="2">
    <span class="gap" title="{map { 'damage' : 'lacune matérielle', 'illegible' : 'illisible', 'cancelled' : 'biffé' }(@reason)}">[…]</span>
  </xsl:template>
  <!-- Changements de main, début et fin de lacune (Codi, l. 3) : jalons sans texte (hteiml les signalait en rouge). -->
  <xsl:template match="tei:handShift | tei:lacunaStart | tei:lacunaEnd" priority="2"/>

  <!-- ==== 4. MÉCANISMES COMMUNS ==== -->
  <!-- (aucun) -->
</xsl:transform>
