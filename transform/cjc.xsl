<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:dts="https://w3id.org/dts/api#"
  xmlns:html="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="tei dts html">

  <xsl:import href="../hteiml/xsl/tei2html.xsl"/>

  <xsl:strip-space elements="tei:app tei:lem tei:rdg tei:rdgList tei:choice tei:sic tei:corr tei:abbr tei:expan tei:orig tei:reg tei:subst"/>

  <xsl:template match="tei:body" priority="10">
    <xsl:apply-imports/>
    <xsl:call-template name="cjc-endnotes">
      <xsl:with-param name="scope" select="."/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="dts:wrapper">
    <div class="dts-content">
      <xsl:apply-templates/>
      <xsl:call-template name="cjc-endnotes">
        <xsl:with-param name="scope" select="."/>
      </xsl:call-template>
    </div>
  </xsl:template>

  <xsl:template name="cjc-endnotes">
    <xsl:param name="scope"/>
    <xsl:variable name="notes" select="$scope//tei:note[not(@place='margin')][not(ancestor::tei:app)][not(ancestor::tei:choice)]"/>
    <xsl:variable name="apps" select="$scope//tei:app"/>
    <xsl:variable name="choices" select="$scope//tei:choice"/>
      <xsl:if test="$notes">
        <aside class="footnotes footnotes-notes" role="doc-endnotes">
          <h3>Notes</h3>
          <ol class="notes-list">
            <xsl:for-each select="$notes">
              <li class="fn-note" id="fn-note-{generate-id()}">
                <a class="noteback" href="#ref-note-{generate-id()}" title="Retour au texte">&#8617;</a>
                <span class="fn-content">
                  <xsl:apply-templates mode="fn-content"/>
                </span>
              </li>
            </xsl:for-each>
          </ol>
        </aside>
      </xsl:if>
      <xsl:if test="$apps or $choices">
        <aside class="footnotes footnotes-app" role="doc-endnotes">
          <h3>Variantes et corrections</h3>
          <ol class="apps-list">
            <xsl:for-each select="$apps">
              <li class="fn-app" id="fn-app-{generate-id()}">
                <a class="noteback" href="#ref-app-{generate-id()}" title="Retour au texte">&#8617;</a>
                <span class="fn-lem">
                  <xsl:apply-templates select="tei:lem/node()" mode="fn-content"/>
                </span>
                <span class="fn-sep">]</span>
                <xsl:for-each select="tei:rdg | tei:witDetail">
                  <xsl:if test="position() &gt; 1">
                    <span class="fn-rdg-sep">;</span>
                  </xsl:if>
                  <span class="fn-rdg">
                    <xsl:apply-templates mode="fn-content"/>
                  </span>
                  <xsl:if test="@wit">
                    <span class="fn-wit">
                      <xsl:value-of select="translate(@wit, '#', '')"/>
                    </span>
                  </xsl:if>
                  <xsl:if test="@source">
                    <span class="fn-wit">
                      <xsl:value-of select="translate(@source, '#', '')"/>
                    </span>
                  </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="tei:note">
                  <span class="fn-app-note">
                    <xsl:apply-templates mode="fn-content"/>
                  </span>
                </xsl:for-each>
              </li>
            </xsl:for-each>
            <xsl:for-each select="$choices">
              <li class="fn-app fn-choice" id="fn-app-{generate-id()}">
                <a class="noteback" href="#ref-app-{generate-id()}" title="Retour au texte">&#8617;</a>
                <xsl:choose>
                  <xsl:when test="tei:corr">
                    <span class="fn-lem">
                      <xsl:apply-templates select="tei:corr[1]/node()" mode="fn-content"/>
                    </span>
                    <span class="fn-sep">]</span>
                    <span class="fn-rdg">
                      <xsl:apply-templates select="tei:sic/node()" mode="fn-content"/>
                    </span>
                    <span class="fn-wit">ms.</span>
                    <xsl:if test="tei:corr[1]/@source">
                      <span class="fn-wit">
                        <xsl:value-of select="translate(tei:corr[1]/@source, '#', '')"/>
                      </span>
                    </xsl:if>
                    <xsl:if test="tei:corr[1]/@resp">
                      <span class="fn-wit">
                        <xsl:value-of select="translate(tei:corr[1]/@resp, '#', '')"/>
                      </span>
                    </xsl:if>
                  </xsl:when>
                  <xsl:when test="tei:reg">
                    <span class="fn-lem">
                      <xsl:apply-templates select="tei:reg[1]/node()" mode="fn-content"/>
                    </span>
                    <span class="fn-sep">]</span>
                    <span class="fn-rdg">
                      <xsl:apply-templates select="tei:orig/node()" mode="fn-content"/>
                    </span>
                    <span class="fn-wit">ms.</span>
                  </xsl:when>
                  <xsl:when test="tei:expan">
                    <span class="fn-lem">
                      <xsl:apply-templates select="tei:expan[1]/node()" mode="fn-content"/>
                    </span>
                    <span class="fn-sep">]</span>
                    <span class="fn-rdg">
                      <xsl:apply-templates select="tei:abbr/node()" mode="fn-content"/>
                    </span>
                    <span class="fn-wit">ms.</span>
                  </xsl:when>
                </xsl:choose>
              </li>
            </xsl:for-each>
          </ol>
        </aside>
      </xsl:if>
  </xsl:template>

  <xsl:template match="tei:app" priority="10">
    <xsl:variable name="gid" select="generate-id()"/>
    <xsl:apply-templates select="tei:lem/node()"/>
    <a class="noteref app-ref" href="#fn-app-{$gid}" id="ref-app-{$gid}">
      <sup>
        <xsl:number count="tei:app | tei:choice" level="any" format="a"/>
      </sup>
    </a>
  </xsl:template>

  <xsl:template match="tei:choice" priority="10">
    <xsl:variable name="gid" select="generate-id()"/>
    <xsl:choose>
      <xsl:when test="tei:corr">
        <xsl:apply-templates select="tei:corr[1]/node()"/>
      </xsl:when>
      <xsl:when test="tei:reg">
        <xsl:apply-templates select="tei:reg[1]/node()"/>
      </xsl:when>
      <xsl:when test="tei:expan">
        <xsl:apply-templates select="tei:expan[1]/node()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="*[1]/node()"/>
      </xsl:otherwise>
    </xsl:choose>
    <a class="noteref app-ref" href="#fn-app-{$gid}" id="ref-app-{$gid}">
      <sup>
        <xsl:number count="tei:app | tei:choice" level="any" format="a"/>
      </sup>
    </a>
  </xsl:template>

  <xsl:template match="tei:note[not(@place='margin')][not(ancestor::tei:app)][not(ancestor::tei:choice)]" priority="10">
    <xsl:variable name="gid" select="generate-id()"/>
    <a class="noteref note-ref" href="#fn-note-{$gid}" id="ref-note-{$gid}">
      <sup>
        <xsl:number count="tei:note[not(@place='margin')][not(ancestor::tei:app)][not(ancestor::tei:choice)]" level="any"/>
      </sup>
    </a>
  </xsl:template>

  <xsl:template match="tei:app" mode="fn-content">
    <span class="inline-app">
      <xsl:apply-templates select="tei:lem/node()" mode="fn-content"/>
    </span>
  </xsl:template>

  <xsl:template match="tei:choice" mode="fn-content">
    <xsl:choose>
      <xsl:when test="tei:corr">
        <xsl:apply-templates select="tei:corr[1]/node()" mode="fn-content"/>
      </xsl:when>
      <xsl:when test="tei:reg">
        <xsl:apply-templates select="tei:reg[1]/node()" mode="fn-content"/>
      </xsl:when>
      <xsl:when test="tei:expan">
        <xsl:apply-templates select="tei:expan[1]/node()" mode="fn-content"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="*[1]/node()" mode="fn-content"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:note" mode="fn-content">
    <span class="inline-note">
      <xsl:apply-templates mode="fn-content"/>
    </span>
  </xsl:template>

  <xsl:template match="tei:handShift | tei:lacunaStart | tei:lacunaEnd" priority="20"/>

  <xsl:template match="tei:handShift | tei:lacunaStart | tei:lacunaEnd" mode="fn-content" priority="20"/>

  <!-- Description de manuscrits et apparat CJC.
       Les msItem isolés sont des blocs. Lorsqu'un msItem contient une liste
       de sous-items (cas des notices CJC), cette liste garde le tableau
       historique Locus / Incipit au lieu d'être aplatie en div successives. -->
  <!-- Groupe intermédiaire : laisser ses sous-groupes produire chacun leur
       propre tableau, plutôt que de les aplatir en lignes. -->
  <xsl:template match="tei:msItem[tei:msItem/tei:msItem]" priority="30">
    <section class="msItem">
      <xsl:apply-templates/>
    </section>
  </xsl:template>
  <!-- Dernier groupe : ses enfants sont les lignes Locus / Incipit. -->
  <xsl:template match="tei:msItem[tei:msItem and not(tei:msItem/tei:msItem)]" priority="20">
    <section class="msItem">
      <xsl:apply-templates select="node()[not(self::tei:msItem)]"/>
      <table class="msItems">
        <thead>
          <tr><th class="locus">Locus</th><th class="incipit">Incipit</th></tr>
        </thead>
        <tbody>
          <xsl:apply-templates select="tei:msItem" mode="cjc-msitem-row"/>
        </tbody>
      </table>
    </section>
  </xsl:template>
  <!-- Un msItem directement porté par msContents reste lui aussi un tableau :
       même une notice sans sous-item garde la grille historique Locus / Incipit. -->
  <xsl:template match="tei:msContents/tei:msItem[not(tei:msItem)]" priority="20">
    <table class="msItems">
      <thead>
        <tr><th class="locus">Locus</th><th class="incipit">Incipit</th></tr>
      </thead>
      <tbody>
        <xsl:apply-templates select="." mode="cjc-msitem-row"/>
      </tbody>
    </table>
  </xsl:template>
  <xsl:template match="tei:msItem" mode="cjc-msitem-row">
    <tr class="msItem">
      <td>
        <cite class="title"><xsl:apply-templates select="tei:title[@type='sub'][1] | tei:title[not(@type='sub')][not(preceding-sibling::tei:title[@type='sub'])][1]"/></cite>
        <br/>
        <span class="locus"><xsl:apply-templates select="tei:locus"/></span>
      </td>
      <td>
        <xsl:apply-templates select="node()[not(self::tei:locus or self::tei:title[@type='sub'])]"/>
      </td>
    </tr>
  </xsl:template>
  <!-- msItem hors msContents : bloc descriptif ordinaire. -->
  <xsl:template match="tei:msItem"><div class="msItem"><xsl:apply-templates/></div></xsl:template>
  <xsl:template match="tei:summary"><div class="summary"><xsl:apply-templates/></div></xsl:template>
  <xsl:template match="tei:msName"><span class="msName"><xsl:apply-templates/></span></xsl:template>
  <xsl:template match="tei:lang"><span class="lang" lang="{@xml:lang}"><xsl:apply-templates/></span></xsl:template>
  <xsl:template match="tei:incipit | tei:explicit"><div class="{local-name()}"><xsl:apply-templates/></div></xsl:template>
  <xsl:template match="tei:rdgGrp"><span class="rdgGrp"><xsl:apply-templates/></span></xsl:template>
  <xsl:template match="tei:material"><span class="material"><xsl:apply-templates/></span></xsl:template>
  <xsl:template match="tei:decoDesc"><section class="decoDesc"><xsl:apply-templates/></section></xsl:template>
  <xsl:template match="tei:decoNote"><div class="decoNote"><xsl:apply-templates/></div></xsl:template>

  <xsl:template match="*" mode="fn-content">
    <xsl:apply-templates select="."/>
  </xsl:template>

  <xsl:template match="text()" mode="fn-content">
    <xsl:value-of select="."/>
  </xsl:template>

</xsl:transform>
