<?xml version="1.0" encoding="UTF-8"?>
<!-- Page de titre des ressources du CJC (route /api/dts/cover), feuille autonome sur le modèle des
     autres corpus (CID, chroniques latines). La route ne passe que le teiHeader.
     Éditions : titre, auteurs du texte (« Anonyme (trad.) », « Justinien Ier »), éditeurs
     scientifiques (principal), édition électronique (respStmt), manuscrits et édition imprimée de
     référence (sourceDesc), soutien (funder, sponsor), date.
     Notices : titre, sous-titre (title type="sub"), auteur de la notice, soutien, date. -->
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="tei xs">

  <xsl:output encoding="UTF-8" indent="no" method="xml" omit-xml-declaration="yes"/>

  <xsl:variable name="th-ts" select="(//tei:fileDesc/tei:titleStmt)[1]"/>
  <xsl:variable name="th-sd" select="(//tei:fileDesc/tei:sourceDesc)[1]"/>
  <xsl:variable name="th-notice" select="exists($th-ts/tei:title[@type = 'sub'])"/>
  <xsl:variable name="th-date" select="replace(normalize-space((//tei:fileDesc/tei:publicationStmt/tei:date)[1]), '^\D*(\d{4}).*$', '$1')"/>

  <xsl:template match="/">
    <html xmlns="http://www.w3.org/1999/xhtml" lang="fr">
      <div id="aside">to delete</div>
      <div id="center">
        <div id="main">
          <div id="article"><xsl:apply-templates select="$th-ts"/></div>
        </div>
      </div>
    </html>
  </xsl:template>

  <xsl:template match="tei:titleStmt">
    <div class="titlestmt">
      <h1 class="head"><xsl:apply-templates select="(tei:title[not(@type)], tei:title)[1]" mode="th"/></h1>
      <xsl:for-each select="tei:title[@type = 'sub']">
        <p class="subtitle"><xsl:apply-templates mode="th"/></p>
      </xsl:for-each>
      <xsl:choose>
        <xsl:when test="$th-notice">
          <xsl:call-template name="th-ligne">
            <xsl:with-param name="label">Notice de </xsl:with-param>
            <xsl:with-param name="noms" select="tei:author ! normalize-space(.)"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="tei:author[normalize-space()]">
          <p class="subtitle"><xsl:value-of select="string-join(tei:author ! normalize-space(.), ', ')"/></p>
        </xsl:when>
      </xsl:choose>
      <xsl:call-template name="th-ligne">
        <xsl:with-param name="label">Édité par </xsl:with-param>
        <xsl:with-param name="noms" select="(tei:principal, tei:editor) ! normalize-space(.)"/>
      </xsl:call-template>
      <xsl:if test="tei:respStmt[normalize-space(tei:name) != '']">
        <p class="editors">
          <span class="editors-label">Édition électronique : </span>
          <xsl:for-each select="tei:respStmt[normalize-space(tei:name) != '']">
            <span class="editor"><xsl:value-of select="normalize-space(tei:name)"/></span>
            <xsl:if test="normalize-space(tei:resp) != ''">
              <span class="resp"> (<xsl:value-of select="normalize-space(tei:resp)"/>)</span>
            </xsl:if>
            <xsl:choose>
              <xsl:when test="position() = last() - 1"> et </xsl:when>
              <xsl:when test="position() &lt; last()">, </xsl:when>
            </xsl:choose>
          </xsl:for-each>
        </p>
      </xsl:if>
      <!-- Manuscrits de l'édition (sigle = msIdentifier/@xml:id), liens vers la reproduction (Gallica) ou la notice du dépôt. -->
      <xsl:variable name="mss" select="$th-sd//tei:msDesc[tei:msIdentifier] | $th-sd/tei:listWit/tei:witness[normalize-space()]"/>
      <xsl:if test="$mss">
        <p class="source">
          <span class="editors-label"><xsl:value-of select="if (count($mss) > 1) then 'Manuscrits' else 'Manuscrit'"/> : </span>
          <xsl:for-each select="$mss">
            <xsl:variable name="mi" select="tei:msIdentifier"/>
            <span class="ms">
              <xsl:choose>
                <xsl:when test="self::tei:witness"><xsl:value-of select="normalize-space(.)"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="string-join(($mi/tei:settlement, $mi/tei:repository, $mi/tei:idno)[normalize-space()] ! normalize-space(.), ', ')"/></xsl:otherwise>
              </xsl:choose>
              <xsl:if test="$mi/@xml:id"> (<i><xsl:value-of select="$mi/@xml:id"/></i>)</xsl:if>
            </span>
            <xsl:variable name="liens" select="tokenize(normalize-space(@source | @facs), ' ')"/>
            <xsl:variable name="gallica" select="$liens[contains(., 'gallica.bnf.fr')][1]"/>
            <xsl:if test="$gallica">
              <xsl:text> </xsl:text>
              <a class="catalogue" href="{$gallica}">[Gallica]</a>
            </xsl:if>
            <xsl:if test="position() &lt; last()"> ; </xsl:if>
          </xsl:for-each>
        </p>
      </xsl:if>
      <xsl:for-each select="$th-sd/tei:bibl">
        <p class="source">
          <span class="editors-label"><xsl:value-of select="if ($th-notice) then 'Œuvre' else 'Édition imprimée'"/> : </span>
          <xsl:apply-templates select="." mode="th-bibl"/>
          <xsl:variable name="lien" select="tokenize(normalize-space(@source), ' ')[1]"/>
          <xsl:if test="$lien">
            <xsl:text> </xsl:text>
            <a class="catalogue" href="{$lien}">[<xsl:value-of select="if (contains($lien, 'gallica')) then 'Gallica' else if (contains($lien, 'catalogue.bnf.fr')) then 'catalogue de la BnF' else 'en ligne'"/>]</a>
          </xsl:if>
        </p>
      </xsl:for-each>
      <xsl:call-template name="th-ligne">
        <xsl:with-param name="label">Avec le soutien de </xsl:with-param>
        <xsl:with-param name="noms" select="(tei:funder, tei:sponsor) ! normalize-space(.)"/>
      </xsl:call-template>
      <xsl:if test="$th-date != ''">
        <span class="date"><xsl:value-of select="$th-date"/></span>
      </xsl:if>
    </div>
  </xsl:template>

  <!-- Titres : italique du TEI gardé (« Codex, Justinianus I. »). -->
  <xsl:template match="tei:hi[@rend = 'i']" mode="th"><i><xsl:apply-templates mode="th"/></i></xsl:template>
  <xsl:template match="text()" mode="th"><xsl:value-of select="replace(., '\s+', ' ')"/></xsl:template>

  <!-- Référence imprimée : titre en italique, le reste en texte, blancs normalisés. -->
  <xsl:template match="tei:bibl" mode="th-bibl"><xsl:apply-templates mode="th-bibl"/></xsl:template>
  <xsl:template match="tei:title" mode="th-bibl"><i><xsl:apply-templates mode="th-bibl"/></i></xsl:template>
  <xsl:template match="text()" mode="th-bibl"><xsl:value-of select="replace(., '\s+', ' ')"/></xsl:template>

  <xsl:template name="th-ligne">
    <xsl:param name="label"/>
    <xsl:param name="noms"/>
    <xsl:if test="exists($noms[. != ''])">
      <p class="editors">
        <span class="editors-label"><xsl:value-of select="$label"/></span>
        <xsl:for-each select="$noms[. != '']">
          <span class="editor"><xsl:value-of select="."/></span>
          <xsl:choose>
            <xsl:when test="position() = last() - 1"> et </xsl:when>
            <xsl:when test="position() &lt; last()">, </xsl:when>
          </xsl:choose>
        </xsl:for-each>
      </p>
    </xsl:if>
  </xsl:template>

</xsl:transform>
