<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:bib="urn:elec:bibliographie"
  xmlns:cjc="urn:elec:cjc"
  xmlns:exslt="http://exslt.org/common"
  xmlns:epub="http://www.idpf.org/2007/ops"
  exclude-result-prefixes="tei xs bib cjc exslt epub">
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
      <xsl:when test="self::tei:app or self::tei:note[cjc:var(.)]">
        <!-- 2026-10-29 : une variante emboîtée dans le lemme d'une autre (Codi, 4 cas) n'a pas d'appel propre :
             elle est décrite dans l'entrée de la variante qui la contient (sa lettre venait en double). -->
        <xsl:number count="tei:app[tei:lem][not(ancestor::tei:app)] | tei:note[cjc:var(.)]" format="a" level="any" from="/"/>
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
        <xsl:number count="tei:note[@resp=$resp][not(cjc:var(.))]" format="I" level="any" from="/"/>
      </xsl:when>
      <!-- 2026-10-29 : notes signées (@resp="#FD", "#HB"…, notices) dans la même suite que les autres : hteiml les
           numérotait à part (« 31, 32, 33, 2, 34… »). Seules les notes de l'éditeur gardent leur suite propre. -->
      <xsl:otherwise>
        <xsl:number count="tei:note[not(@resp = 'editor') and not(@rend) and not(parent::tei:div) and not(parent::tei:notesStmt) and not(parent::tei:app) and not(cjc:var(.))]" level="any" from="/"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- 2026-10-29 — APPARAT CRITIQUE DES ÉDITIONS. Hors du Codi, les éditions n'ont pas d'<app> : les
       variantes sont des <note> (« de P.] de Persie F » : lemme fermé par un crochet ; Code : notes
       place="bottom", leçons et faits de copie). Demande de Maxime : « c'est de l'apparat, pas des notes ».
       Une telle note est rendue comme une variante : appel en lettre, entrée dans p.apparatus, hors du
       décompte et de la liste des notes. Les notices (aucune note de cette forme) ne sont pas touchées. -->
  <!-- 2026-10-29 (relecture de toutes les ressources) : règle élargie aux variantes restées en notes, mesurées
       ressource par ressource sur le rendu servi :
       - notices : note faite d'un seul <app> sans lemme dont une leçon au moins a son témoin (« xii B / lat. duodecim »,
         « s'accordent A / OF / lat. convenerit » : leçons des autres témoins sur un mot du spécimen) ; la note qui ne
         donne que le latin (« lat. per eum locum ») reste une note ;
       - Authentiques : lemme abrégé par « [...] » avant le crochet (« Et nos [...] penser] Més desci… F », 24 cas) ;
       - éditions (hors description de manuscrit) : faits de copie (« n exponctué après nus », Code de Montpellier ;
         « Ms. : hoi exp. après fait », Codi, sauf lettrines et renvois aux éditions Fitting/Derrer ; « Répété ms. »,
         « sur grattage », Digeste) et leçons suivies de leurs sigles (« reüser AHI », « se om. AHIL », Code de Giessen).
       Restent des notes : sources, renvois au latin, remarques de l'éditeur, descriptions. -->
  <xsl:function name="cjc:var" as="xs:boolean">
    <xsl:param name="n" as="element()"/>
    <xsl:variable name="t" select="normalize-space(string-join($n//text(), ''))"/>
    <xsl:sequence select="exists($n/self::tei:note) and not($n/@type = 'citation') and not($n/parent::tei:app)
      and not($n/ancestor::tei:teiHeader)
      and ($n/@place = 'bottom' or matches($t, '^([^\[\]]|\[(\.\.\.|…)\]){1,200}\]')
           (: notices : leçon suivie de ses sigles, « Tient valet [P-] », « … [HL+] », « … [L hypométrique ; P+] » :)
           or matches($t, '\[[^\[\]]*([A-Z]{1,6}\s*[+\-]|hypométrique|hypermétrique|rime)[^\[\]]*\]\s*\.?$')
           (: notices : note faite des seules leçons d'un app sans lemme :)
           or ($n/tei:app/tei:rdg[@wit] and matches(normalize-space(string-join($n/text(), '')), '^(\[[^\]]*\])?\s*\.?$'))
           or (not($n/ancestor::tei:msDesc) and (
                 matches($t, 'exponctu|^R[ée]p[ée]t[ée] ms|sur grattage')
                 or (matches($t, '^Ms\.? ?:') and not(matches($t, 'lettrine|Dans l')))
                 or (matches($t, '^[^.;:\[\]]{1,120}\s(om\.\s)?[A-Z]{1,6}(\([^)]*\))?([A-Z]{1,6}(\([^)]*\))?)*\s*\.?$')
                     and not(matches($t, '\s[IVXLC]{2,}\.?$|d.après|manque|dans'))))))"/>
  </xsl:function>
  <xsl:template match="tei:note[cjc:var(.)]" mode="fn" priority="30"/>
  <!-- Pied de notes de hteiml repris, avec les notes-variantes dans l'apparat et hors des notes. -->
  <xsl:template name="footnotes">
    <!-- children from which find notes -->
    <xsl:param name="cont" select="*"/>
    <!-- for notes by pages -->
    <xsl:param name="pb" select="$cont//tei:pb[@n][not(@ed)]"/>
    <xsl:variable name="notes">
      <xsl:if test="$cont//tei:app[tei:lem][not(ancestor::tei:app)] or $cont//tei:note[cjc:var(.)]">
        <xsl:variable name="apparatus">
          <xsl:choose>
            <xsl:when test="$cont">
              <xsl:for-each select="$cont // (tei:app[tei:lem][not(ancestor::tei:app)] | tei:note[cjc:var(.)])">
                <xsl:call-template name="note-inline"/>
              </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
              <xsl:for-each select="$cont // (tei:app[tei:lem][not(ancestor::tei:app)] | tei:note[cjc:var(.)])">
                <xsl:call-template name="note-inline"/>
              </xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:if test="$apparatus != ''">
          <p class="apparatus">
            <xsl:copy-of select="$apparatus"/>
          </p>
        </xsl:if>
      </xsl:if>
      <!--
      <xsl:for-each select="$cont //tei:*[@rend='note']">
        <xsl:sort select="local-name()"/>
        <xsl:call-template name="fn"/>
      </xsl:for-each>
      -->
      <xsl:choose>
        <xsl:when test=" $pb">
          <!-- notes before the first pb, via the note-pb key (notes with no preceding pb) -->
          <xsl:variable name="notes1" select="key('note-pb', '')[not(cjc:var(.))]"/>
          <xsl:if test="$notes1">
            <div class="page">
              <xsl:for-each select="$notes1[@resp = 'author'][not(@place = 'margin')]">
                <xsl:call-template name="note"/>
              </xsl:for-each>
              <xsl:for-each select="$notes1[@resp = 'editor'][not(@place = 'margin')]">
                <xsl:call-template name="note"/>
              </xsl:for-each>
              <xsl:for-each select="$notes1[not(@resp) or (@resp != 'editor' and @resp != 'author')][not(@place = 'margin')]">
                <xsl:call-template name="note"/>
              </xsl:for-each>
            </div>
          </xsl:if>
          <xsl:for-each select="$pb">
            <xsl:variable name="notes4page">
              <!-- notes abc ? @n and translate(@n, 'abcdefghijklmnopqrstuvwxyz-.', '') -->
              <xsl:for-each select="key('note-pb', generate-id())[not(cjc:var(.))][@resp = 'author'][not(@place = 'margin')]">
                <xsl:call-template name="note"/>
              </xsl:for-each>
              <xsl:for-each select="key('note-pb', generate-id())[not(cjc:var(.))][@resp = 'editor'][not(@place = 'margin')]">
                <xsl:call-template name="note"/>
              </xsl:for-each>
              <xsl:for-each select="key('note-pb', generate-id())[not(cjc:var(.))][not(@resp) or (@resp != 'editor' and @resp != 'author')][not(@place = 'margin')]">
                <xsl:call-template name="note"/>
              </xsl:for-each>
            </xsl:variable>
            <xsl:if test="$notes4page != ''">
              <div class="page">
                <div class="b note-page">
                  <xsl:call-template name="a"/>
                </div>
                <xsl:copy-of select="$notes4page"/>
              </div>
            </xsl:if>
          </xsl:for-each>
        </xsl:when>
        <!-- handle notes by split sections ? -->
        <xsl:when test="$cont and function-available('exslt:node-set')">
          <xsl:apply-templates select="exslt:node-set($cont)" mode="fn">
            <xsl:with-param name="resp">author</xsl:with-param>
          </xsl:apply-templates>
          <xsl:apply-templates select="exslt:node-set($cont)" mode="fn">
            <xsl:with-param name="resp">editor</xsl:with-param>
          </xsl:apply-templates>
          <xsl:apply-templates select="exslt:node-set($cont)" mode="fn"/>
        </xsl:when>
        <!-- !! especially not efficient -->
        <xsl:when test="$cont">
          <xsl:for-each select="$cont //tei:note[not(cjc:var(.))]">
            <xsl:sort select="@place|@resp"/>
            <xsl:call-template name="fn"/>
          </xsl:for-each>
        </xsl:when>
        <xsl:when test="key('id', 'note-footseq')">
          <xsl:apply-templates select="*" mode="fn"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="*" mode="fn">
            <xsl:with-param name="resp">author</xsl:with-param>
          </xsl:apply-templates>
          <xsl:apply-templates select="*" mode="fn">
            <xsl:with-param name="resp">editor</xsl:with-param>
          </xsl:apply-templates>
          <xsl:apply-templates select="*" mode="fn"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$notes != ''">
      <xsl:variable name="el">
        <xsl:choose>
          <xsl:when test="$format=$epub2">div</xsl:when>
          <xsl:otherwise>section</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:element name="{$el}" namespace="http://www.w3.org/1999/xhtml">
        <xsl:attribute name="class">footnotes</xsl:attribute>
        <xsl:if test="$format = $epub3">
          <xsl:attribute name="epub:type">footnotes</xsl:attribute>
        </xsl:if>
        <!--
        <hr class="footnotes" width="30%"/>
        -->
        <xsl:copy-of select="$notes"/>
      </xsl:element>
    </xsl:if>
  </xsl:template>
  <!-- Entrée d'apparat (modèle de hteiml repris) : la ponctuation finale (« . ») va DANS l'entrée. hteiml
       la mettait après, hors du span ; le bloc commun met chaque entrée sur sa ligne (display: block) :
       le point isolé faisait une ligne presque vide entre deux variantes (Tancrède, notice). -->
  <xsl:template name="note-inline">
    <!-- identifiant de la note -->
    <xsl:variable name="id">
      <xsl:call-template name="id"/>
    </xsl:variable>
    <xsl:variable name="text">
      <xsl:for-each select="text()">
        <xsl:value-of select="normalize-space(.)"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="html">
      <xsl:choose>
        <xsl:when test="$text='' and count(*)=1 and tei:p">
          <span class="note" id="{$id}">
            <xsl:if test="$format = $epub3">
              <xsl:attribute name="epub:type">note</xsl:attribute>
            </xsl:if>
            <xsl:call-template name="noteback">
              <xsl:with-param name="class"/>
            </xsl:call-template>
            <xsl:text>, </xsl:text>
            <xsl:apply-templates select="*/node()"/>
          </span>
        </xsl:when>
        <xsl:when test="$text='' and *[1][self::tei:p]">
          <div class="note" id="{$id}">
            <p class="noindent">
              <xsl:call-template name="noteback"/>
              <xsl:apply-templates select="*[1]/node()"/>
            </p>
            <xsl:apply-templates select="*[position() &gt; 1]"/>
          </div>
        </xsl:when>
        <xsl:otherwise>
          <span class="note" id="{$id}">
            <xsl:call-template name="noteback">
              <xsl:with-param name="class"/>
            </xsl:call-template>
            <xsl:choose>
              <xsl:when test="self::tei:app"><xsl:call-template name="cjc-app-entree"/></xsl:when>
              <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
            </xsl:choose>
          </span>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$html != ''">
      <!-- regarder si la ligne est déjà ponctuée avant d'ajouter un point -->
      <xsl:variable name="norm" select="normalize-space($html)"/>
      <xsl:variable name="last" select="substring($norm, string-length($norm))"/>
      <xsl:variable name="ponct"><xsl:choose>
        <!-- block -->
        <xsl:when test="count(*) &gt; 1 and $text='' "/>
        <!-- Déja ponctué -->
        <xsl:when test="$last=',' or $last=';' or $last='.'">
          <xsl:text> </xsl:text>
        </xsl:when>
        <xsl:otherwise>. </xsl:otherwise>
      </xsl:choose></xsl:variable>
      <xsl:for-each select="$html/node()">
        <xsl:choose>
          <xsl:when test="self::*">
            <xsl:copy>
              <xsl:copy-of select="@* | node()"/>
              <xsl:value-of select="normalize-space($ponct)"/>
            </xsl:copy>
          </xsl:when>
          <xsl:otherwise><xsl:copy-of select="."/></xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>
  <!-- 2026-10-29 — ENTRÉE D'APPARAT DU CODI (seuls <app> à lemme du corpus, 1 000 cas). hteiml recopiait le lemme
       tel qu'il est balisé dans le texte : « majors] : major[…] H » (deux séparateurs), « Omis » pour une lacune, et,
       quand la variante est décrite DANS le lemme (correction, exponctuation, ajout : 630 cas sans <rdg>), une entrée
       qui ne disait rien (« fermances. »). Entrée refaite : lemme tel qu'on le lit] leçons et sigles (« om. » si vide) ;
       sinon ce que montre le manuscrit (« persones exponctué, fermances ajouté H », « edendo H »). -->
  <xsl:function name="cjc:sigles" as="xs:string">
    <xsl:param name="w"/>
    <xsl:sequence select="string-join(tokenize(normalize-space(translate(string($w), ',#', '  ')), ' '), '')"/>
  </xsl:function>
  <xsl:template name="cjc-app-entree">
    <xsl:variable name="app" select="."/>
    <xsl:variable name="lemme"><xsl:apply-templates select="tei:lem/node()" mode="cjc-lecon"/></xsl:variable>
    <xsl:variable name="wit" select="cjc:sigles(tei:lem/@wit)"/>
    <xsl:if test="normalize-space(string($lemme)) != ''">
      <span class="lem"><xsl:copy-of select="$lemme"/></span>
    </xsl:if>
    <xsl:variable name="parties" as="element()*">
      <xsl:for-each select="tei:rdg | tei:witDetail">
        <xsl:choose>
          <xsl:when test="self::tei:witDetail">
            <span class="witDetail"><xsl:apply-templates mode="cjc-lecon"/></span>
          </xsl:when>
          <xsl:otherwise>
            <span class="rdg">
              <xsl:choose>
                <xsl:when test="normalize-space(.) = '' and not(.//tei:gap)"><i>om.</i></xsl:when>
                <xsl:otherwise><xsl:apply-templates mode="cjc-lecon"/></xsl:otherwise>
              </xsl:choose>
              <xsl:if test="cjc:sigles(@wit) != ''"><xsl:text> </xsl:text><i class="wit"><xsl:value-of select="cjc:sigles(@wit)"/></i></xsl:if>
            </span>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
      <xsl:for-each select="tei:lem//(tei:choice[tei:sic | tei:orig] | tei:subst | tei:del[not(parent::tei:subst)] | tei:add[not(parent::tei:subst)] | tei:app)[ancestor::tei:app[1] is $app]">
        <xsl:choose>
          <xsl:when test="self::tei:app">
            <span class="sous-app"><xsl:call-template name="cjc-app-entree"/></span>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="desc">
              <xsl:choose>
                <xsl:when test="self::tei:choice">
                  <xsl:apply-templates select="(tei:sic, tei:orig)[1]/node()" mode="cjc-lecon"/>
                  <xsl:if test="$wit != ''"><xsl:text> </xsl:text><i class="wit"><xsl:value-of select="$wit"/></i></xsl:if>
                  <xsl:if test="tei:corr and normalize-space(tei:corr) = ''"><xsl:text>, supprimé par l’éditeur</xsl:text></xsl:if>
                </xsl:when>
                <xsl:when test="self::tei:subst">
                  <xsl:apply-templates select="tei:del" mode="cjc-modif"/>
                  <xsl:text>, </xsl:text>
                  <xsl:apply-templates select="tei:add" mode="cjc-modif"/>
                  <xsl:if test="$wit != ''"><xsl:text> </xsl:text><i class="wit"><xsl:value-of select="$wit"/></i></xsl:if>
                </xsl:when>
                <xsl:when test="normalize-space(.) != ''">
                  <xsl:apply-templates select="." mode="cjc-modif"/>
                  <xsl:if test="$wit != ''"><xsl:text> </xsl:text><i class="wit"><xsl:value-of select="$wit"/></i></xsl:if>
                </xsl:when>
              </xsl:choose>
            </xsl:variable>
            <xsl:if test="normalize-space(string($desc)) != ''">
              <span class="rdg"><xsl:copy-of select="$desc"/></span>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>
    <xsl:for-each select="$parties">
      <xsl:if test="position() &gt; 1">
        <xsl:value-of select="if (@class = 'witDetail') then ' : ' else ' ; '"/>
      </xsl:if>
      <xsl:copy-of select="."/>
    </xsl:for-each>
  </xsl:template>
  <!-- Ce que fait le copiste : « persones exponctué », « la ajouté dans l’interligne ». -->
  <xsl:template match="tei:del" mode="cjc-modif">
    <xsl:apply-templates mode="cjc-lecon"/>
    <xsl:value-of select="if (@rend = 'expunction') then ' exponctué' else if (@rend = 'overstrike') then ' biffé' else ' supprimé'"/>
  </xsl:template>
  <xsl:template match="tei:add" mode="cjc-modif">
    <xsl:apply-templates mode="cjc-lecon"/>
    <xsl:value-of select="if (@place = ('above', 'interlinear')) then ' ajouté dans l’interligne' else if (@place = 'margin') then ' ajouté en marge' else ' ajouté'"/>
  </xsl:template>
  <!-- Leçon telle qu'on la lit (lemme ou leçon d'un témoin) : correction retenue, ajouts gardés, suppressions ôtées,
       sans appel ni infobulle. -->
  <xsl:template match="*" mode="cjc-lecon"><xsl:apply-templates mode="cjc-lecon"/></xsl:template>
  <xsl:template match="text()" mode="cjc-lecon"><xsl:value-of select="."/></xsl:template>
  <xsl:template match="tei:choice" mode="cjc-lecon">
    <xsl:apply-templates select="(tei:corr, tei:reg, tei:expan, *)[1]/node()" mode="cjc-lecon"/>
  </xsl:template>
  <xsl:template match="tei:subst" mode="cjc-lecon"><xsl:apply-templates select="tei:add" mode="cjc-lecon"/></xsl:template>
  <xsl:template match="tei:del | tei:note | tei:witDetail | tei:handShift | tei:lacunaStart | tei:lacunaEnd" mode="cjc-lecon"/>
  <xsl:template match="tei:app" mode="cjc-lecon"><xsl:apply-templates select="tei:lem" mode="cjc-lecon"/></xsl:template>
  <xsl:template match="tei:gap" mode="cjc-lecon">[…]</xsl:template>
  <xsl:template match="tei:foreign | tei:hi[@rend = 'i']" mode="cjc-lecon"><i><xsl:apply-templates mode="cjc-lecon"/></i></xsl:template>
  <!-- Variante emboîtée : dans le texte, sa leçon retenue seulement (son entrée est dans celle qui la contient). -->
  <xsl:template match="tei:app[tei:lem][ancestor::tei:app]" priority="30">
    <xsl:apply-templates select="tei:lem"/>
  </xsl:template>

  <!-- 2026-10-29 — INSTITUTES (fr. 1064). « Le projet a pour but de donner la leçon de C » (teiHeader) : chaque
       <choice> réunit la leçon de C (sic source="#C"), celle de l'édition Olivier-Martin (sic resp="#ed") et parfois
       une correction (corr). hteiml ne connaît pas deux <sic> dans un <choice> : il les sortait tous les deux,
       barrés. Comme hteiml pour sic/corr : la leçon retenue dans le texte (la correction, sinon C), les autres en
       infobulle avec leur origine. -->
  <xsl:template match="tei:choice[count(tei:sic) &gt; 1 or (tei:sic[@source = '#C'] and not(tei:corr))]" priority="30">
    <xsl:variable name="retenue" select="(tei:corr, tei:sic[@source = '#C'], *)[1]"/>
    <span class="choice">
      <xsl:attribute name="title">
        <xsl:for-each select="* except $retenue">
          <xsl:value-of select="if (@source = '#C') then 'C' else if (@resp = '#ed') then 'éd. Olivier-Martin'
            else if (@resp = '#ned') then 'correction' else translate(string((@source, @resp)[1]), '#', '')"/>
          <xsl:text> : </xsl:text>
          <xsl:value-of select="if (normalize-space(.) = '') then 'om.' else normalize-space(.)"/>
          <xsl:if test="position() != last()"> ; </xsl:if>
        </xsl:for-each>
      </xsl:attribute>
      <xsl:apply-templates select="$retenue/node()"/>
    </span>
  </xsl:template>

  <!-- 2026-10-29 : <seg type="title"> = titre (rubrique) d'un chapitre du manuscrit, cité dans une note ou un incipit,
       pas un titre d'ouvrage : hteiml lui donnait la classe « title », que html.css met en italique. -->
  <xsl:template match="tei:seg[@type = 'title']" priority="5">
    <span class="titre-ms"><xsl:apply-templates/></span>
  </xsl:template>

  <!-- 2026-10-29 — LEÇONS CITÉES DANS LES NOTICES. Dans les notices, <app> sans <lem> (847 cas, aucun dans les
       éditions) ne fait pas apparat : il cite des leçons dans le texte (« Fautes communes AFL : Auth. 81.pr
       desordeneement AFL / desanorrement O / lat. inornatum »). hteiml le remplaçait par un appel en lettre et
       renvoyait les leçons en pied de page (« [a] s'oppose à [b] »). Rendu en ligne : chaque leçon suivie de ses
       sigles en italique, leçons séparées par « / », leçon latine sans témoin précédée de « lat. ». -->
  <xsl:template match="tei:app[not(tei:lem)]" priority="30">
    <span class="lecons">
      <xsl:for-each select="tei:rdg">
        <xsl:if test="position() &gt; 1"><xsl:text> / </xsl:text></xsl:if>
        <xsl:choose>
          <xsl:when test="not(@wit) and starts-with(@xml:lang, 'la')">
            <xsl:text>lat. </xsl:text><i class="lecon"><xsl:apply-templates/></i>
          </xsl:when>
          <xsl:otherwise>
            <span class="lecon"><xsl:apply-templates/></span>
            <xsl:if test="normalize-space(@wit)">
              <xsl:text> </xsl:text>
              <i class="sigles"><xsl:value-of select="string-join(for $w in tokenize(normalize-space(@wit), ' ') return substring-after($w, '#'), '')"/></i>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </span>
  </xsl:template>

  <!-- Titres : modèle head de hteiml repris à l'identique, sauf le plafond. hteiml testait « $level > 7 » et
       sortait donc des <h7> pour les div profondes des notices (HTML s'arrête à h6 ; dots-vue :
       « Failed to resolve component: h7 »). -->
  <xsl:template match="tei:head">
    <xsl:param name="level" select="count(ancestor::tei:*) - 2"/>
    <xsl:variable name="name">
      <xsl:choose>
        <xsl:when test="normalize-space(.) = ''"/>
        <xsl:when test="parent::tei:front | parent::tei:text | parent::tei:back ">h1</xsl:when>
        <xsl:when test="$level &lt; 1">h1</xsl:when>
        <xsl:when test="$level &gt; 6">h6</xsl:when>
        <xsl:otherwise>h<xsl:value-of select="$level"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$name != ''">
      <xsl:apply-templates select="tei:pb"/>
      <xsl:element name="{$name}" namespace="http://www.w3.org/1999/xhtml">
        <xsl:call-template name="atts">
          <xsl:with-param name="class"><xsl:value-of select="../@type"/></xsl:with-param>
        </xsl:call-template>
        <xsl:apply-templates select="node()[local-name()!='pb']"/>
        <xsl:if test="not(following-sibling::*[1][self::tei:head]) and $format != $epub2 and $format != $epub3">
          <a class="bookmark">
            <xsl:attribute name="href">
              <xsl:for-each select="ancestor::tei:div[1]">
                <xsl:call-template name="href"/>
              </xsl:for-each>
            </xsl:attribute>
            <xsl:text> §</xsl:text>
          </a>
        </xsl:if>
      </xsl:element>
    </xsl:if>
  </xsl:template>

  <!-- 2026-10-29 : note dans une référence (Digestum vetus, « Bien qu'elles aient fait l'objet… ») : hteiml l'écrivait
       en ligne ET la listait en pied de page sans appel (note 747 orpheline) ; appel ordinaire. -->
  <xsl:template match="tei:bibl/tei:note" priority="5">
    <xsl:call-template name="noteref"/>
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
  <!-- 2026-10-29 — ABRÉVIATIONS DÉVELOPPÉES (spécimens des notices, 10 000 <expan>). hteiml mettait le mot entier entre
       crochets (« [p<ins>ar</ins>tie] »), ce qui se confondait avec les repères [1], [pr.] et les restitutions. Les notices
       comptent les lettres développées « en caractères italiques » (coefficient d'abréviation, notice de Tancrède) :
       mot sans crochets, lettres développées en italique. -->
  <xsl:template match="tei:expan[not(parent::tei:choice)]" priority="5">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="tei:ex" priority="5">
    <i class="ex"><xsl:apply-templates/></i>
  </xsl:template>

  <!-- 2026-10-29 — SUBDIVISIONS NUMÉROTÉES EN LISTE. Code, Digeste, Tres libri et spécimens des notices mettent
       plusieurs subdivisions dans un même <p> (« [pr.] … [1] … [2] … [3.1] … », 3 400 repères en cours de
       paragraphe) : un bloc illisible. Demande de Maxime : « faut avoir une liste ». Chaque repère <label>[…]</label>
       ouvre une ligne (un <p class="repere">, repère en tête) ; ce qui précède le premier repère (rubrique) garde sa
       ligne. Les <p> qui commencent déjà par leur repère (Codi, Authentiques) prennent la même forme.
       Hors description de manuscrit (« <label>Écriture</label> »). -->
  <xsl:function name="cjc:repere" as="xs:boolean">
    <xsl:param name="l" as="node()"/>
    <xsl:sequence select="exists($l/self::tei:label[matches(normalize-space(.), '^[^\[]{0,2}\[.*$')])"/>
  </xsl:function>
  <!-- Code de Giessen : le repère est parfois porté par un <seg xml:id> qui l'ouvre (8 cas) ; même traitement. -->
  <xsl:template match="tei:p[not(ancestor::tei:msDesc | ancestor::tei:teiHeader)][tei:label[cjc:repere(.)] | tei:seg[*[1][cjc:repere(.)]]]" priority="5">
    <xsl:variable name="p" select="."/>
    <xsl:for-each-group select="node()[self::* or normalize-space() or preceding-sibling::node()[self::* or normalize-space()]]"
      group-starting-with="tei:label[cjc:repere(.)] | tei:seg[*[1][cjc:repere(.)]]">
      <p class="{if (current-group()[1][self::tei:label or self::tei:seg]) then 'noindent repere' else 'noindent'}">
        <xsl:if test="position() = 1 and $p/@xml:id"><xsl:attribute name="id" select="$p/@xml:id"/></xsl:if>
        <xsl:apply-templates select="current-group()"/>
      </p>
    </xsl:for-each-group>
  </xsl:template>

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
