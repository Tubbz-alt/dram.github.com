<xsl:stylesheet version="1.0"
                extension-element-prefixes="date"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:date="http://exslt.org/dates-and-times"
                xmlns="http://www.w3.org/1999/xhtml">
  <xsl:template match="posts">
    <article>
      <section id="posts">
        <h1>Blog Posts</h1>
        <ul class="article-list"><xsl:apply-templates/></ul>
        <p id="more"><a href="/blog/archive.html">more...</a></p>
      </section>

      <section id="projects">
        <h1>Projects</h1>
        <ul class="article-list">
          <li>...</li>
        </ul>
      </section>
    </article>
  </xsl:template>

  <xsl:template match="post">
    <li>
      <span>
        <xsl:variable name="date" select="creation-date"/>
        <xsl:variable name="year" select="date:year($date)"/>
        <xsl:variable name="month" select="date:month-abbreviation($date)"/>
        <xsl:variable name="day" select="date:day-in-month($date)"/>
        <xsl:value-of select="concat(format-number($day, '00'), ' ', $month, ' ', $year)"/>
      </span>
      &#187;
      <a>
        <xsl:attribute name="href">
          <xsl:value-of select="uri"/>
        </xsl:attribute>
        <xsl:value-of select="title"/>
      </a>
    </li>
  </xsl:template>
</xsl:stylesheet>
