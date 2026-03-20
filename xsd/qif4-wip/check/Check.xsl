<?xml version="1.0" encoding="utf-8"?>

<!-- This requires the calling XSLT application to pass a value for the -->
<!-- inputURI variable. Different applications use different methods of -->
<!-- doing that. An xsltproc call is shown on the next line             -->
<!-- xsltproc -o result - -stringparam inputURI xyz.qif Check.xsl xyz.qif -->
<!-- There should be no space in - - above. Comment syntax requires it  -->
<!-- XMLSpy requires an entry in XSL Parameters of XSL/XQuery           -->
<!-- "../data/xyz.qif" works when the Check.xsl file is called from     -->
<!-- XSL Transformation in XSL/XQuery                                   -->

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:t="http://qifstandards.org/xsd/qif4">

  <xsl:import href="CheckFormat.xsl"/>
  <xsl:import href="CheckQuality.xsl"/>
  <xsl:import href="CheckSemantic.xsl"/>
  <xsl:import href="CheckDocuments.xsl"/>

  <xsl:output method="xml" indent="yes" />
  <xsl:param name="inputURI"/>
  <!-- skip text content -->
  <xsl:template match="text()"/>

  <xsl:template match="/t:QIFDocument">
    <xsl:element name="CheckReport">
      <xsl:call-template name="processing_document">
        <xsl:with-param name="level" select="0"/>
	<xsl:with-param name="uri" select="$inputURI"/>
      </xsl:call-template>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>
