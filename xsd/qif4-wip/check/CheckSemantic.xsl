<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:t="http://qifstandards.org/xsd/qif4">

  <xsl:import href="CheckLibrary.xsl"/>

  <xsl:output method="xml" indent="yes" />

  <!-- skip text content -->
  <xsl:template match="text()" mode="Semantic" />

  <!-- FeatureNominal, the check: must be connected to a topology entity -->
  <!-- This is currently not enabled in the CheckParameters and should  -->
  <!-- not be enabled because entities numbered by the nTopo variable  -->
  <!-- are not necessarily topology entities. Also, nTopo will always   -->
  <!-- be zero in 'select="$nTopo"', so it is pointless to evaluate it. -->
  <xsl:variable
      name="FeatureNominalTopologyLink"
      select="$CheckParameters/CheckSemanticParameters
	      /Check[@name='FeatureNominalTopologyLink']/@active = 'true'"/>
  <xsl:template match="/t:QIFDocument/t:Features/t:FeatureNominals/t:*"
		mode="Semantic">
    <xsl:if test="$FeatureNominalTopologyLink">
      <xsl:variable
	  name="nTopo"
	  select="count(t:EntityInternalIds/t:Id | t:EntityExternalIds/t:Id)"/>
      <xsl:if test="not($nTopo &gt; 0)">
        <xsl:for-each select=".">
          <xsl:call-template name="error_node">
            <xsl:with-param name="report">
              FeatureNominal not connected with topology:
	      id=<xsl:value-of select="@id"/>, 
	      nTopo(<xsl:value-of select="$nTopo"/>)
            </xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:if>
    </xsl:if>
    <xsl:apply-templates mode="Semantic"/>
  </xsl:template>

  <!-- PositionCharacteristicDefinition, the check:                   -->
  <!-- if ToleranceValue = 0, then MaterialCondition must be MAXIMUM  -->
  <xsl:template
      match="/t:QIFDocument/t:Characteristics/t:CharacteristicDefinitions
	     /t:PositionCharacteristicDefinition" mode="Semantic">
    <xsl:if test="not((t:ToleranceValue != 0) or 
		      (t:MaterialCondition = 'MAXIMUM'))">
      <xsl:for-each select=".">
        <xsl:call-template name="error_node">
          <xsl:with-param name="report">
            PositionCharacteristicDefinition: 
	    id=<xsl:value-of select="@id"/>, ToleranceValue=0 and 
	    MaterialCondition(<xsl:value-of select="t:MaterialCondition"/>)
	    != 'MAXIMUM'
          </xsl:with-param>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:if>
    <xsl:apply-templates mode="Semantic"/>
  </xsl:template>

  <!-- FeatureNominal, the check:                                     -->
  <!-- The QIF id of a feature nominal may appear at most once in the -->
  <!-- FeatureNominalIds of the Parts and Assemblies of a Product     -->

  <xsl:template
      match="/t:QIFDocument/t:Features/t:FeatureNominals/t:*"
      mode="Semantic">
    <xsl:variable name="id" select="@id"/>
    <xsl:variable name="matchingIds"
		  select="/t:QIFDocument/t:Product/t:PartSet/t:Part
			  /t:FeatureNominalIds/t:Id[. = $id]
                        | /t:QIFDocument/t:Product/t:AssembySet/t:Assembly
			  /t:FeatureNominalIds/t:Id[. = $id]"/>
    <xsl:if test="(count($matchingIds) > 1)">
      <xsl:call-template name="error_node">
        <xsl:with-param name="report">
          The feature nominal id <xsl:value-of select="$id"/> is
          used in more than one Part or Assembly.
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Body, the check:                                    -->
  <!-- The QIF id of a Body may appear at most once in the -->
  <!-- BodyIds of the Parts and Assemblies of a Product    -->

  <xsl:template
      match="/t:QIFDocument/t:Product/t:TopologySet/t:BodySet/t:Body"
      mode="Semantic">
    <xsl:variable name="id" select="@id"/>
    <xsl:variable name="matchingIds"
		  select="/t:QIFDocument/t:Product/t:PartSet/t:Part
			  /t:BodyIds/t:Id[. = $id]
                        | /t:QIFDocument/t:Product/t:AssembySet/t:Assembly
			  /t:BodyIds/t:Id[. = $id]"/>
    <xsl:if test="(count($matchingIds) > 1)">
      <xsl:call-template name="error_node">
        <xsl:with-param name="report">
          The Body id <xsl:value-of select="$id"/> is
          used in more than one Part or Assembly.
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Shell, the check:                                    -->
  <!-- The QIF id of a Shell may appear at most once in the -->
  <!-- ShellIds of the Bodies of a Product    -->

  <xsl:template
      match="/t:QIFDocument/t:Product/t:TopologySet/t:ShellSet/t:Shell"
      mode="Semantic">
    <xsl:variable name="id" select="@id"/>
    <xsl:variable name="matchingIds"
		  select="/t:QIFDocument/t:Product/t:TopologySet/t:BodySet
			  /t:Body/t:ShellIds/t:Id[. = $id]"/>
    <xsl:if test="(count($matchingIds) > 1)">
      <xsl:call-template name="error_node">
        <xsl:with-param name="report">
          The Shell id <xsl:value-of select="$id"/> is
          used in more than one Body.
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Face, the check:                                    -->
  <!-- The QIF id of a Face may appear at most once in the -->
  <!-- FaceIds of the Shells of a Product and at most once -->
  <!-- in the FaceIds of the Bodies of a Product           -->

  <xsl:template
      match="/t:QIFDocument/t:Product/t:TopologySet/t:FaceSet/t:Face"
      mode="Semantic">
    <xsl:variable name="id" select="@id"/>
    <xsl:variable name="matchingIdsShell"
		  select="/t:QIFDocument/t:Product/t:TopologySet/t:ShellSet
			  /t:Shell/t:FaceIds/t:Id[. = $id]"/>
    <xsl:variable name="matchingIdsBody"
		  select="/t:QIFDocument/t:Product/t:TopologySet/t:BodySet
			  /t:Body/t:FaceIds/t:Id[. = $id]"/>
    <xsl:if test="(count($matchingIdsShell) > 1)">
      <xsl:call-template name="error_node">
        <xsl:with-param name="report">
          The Face id <xsl:value-of select="$id"/> is
          used in more than one Shell.
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="(count($matchingIdsBody) > 1)">
      <xsl:call-template name="error_node">
        <xsl:with-param name="report">
          The Face id <xsl:value-of select="$id"/> is
          used in more than one Body.
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Loop, the check:                                    -->
  <!-- The QIF id of a Loop may appear at most once in the -->
  <!-- LoopIds of the Bodies of a Product    -->

  <xsl:template
      match="/t:QIFDocument/t:Product/t:TopologySet/t:LoopSet/t:Loop"
      mode="Semantic">
    <xsl:variable name="id" select="@id"/>
    <xsl:variable name="matchingIds"
		  select="/t:QIFDocument/t:Product/t:TopologySet/t:BodySet
			  /t:Body/t:LoopIds/t:Id[. = $id]"/>
    <xsl:if test="(count($matchingIds) > 1)">
      <xsl:call-template name="error_node">
        <xsl:with-param name="report">
          The Loop id <xsl:value-of select="$id"/> is
          used in more than one Body.
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
    
  <!-- Edge, the check:                                    -->
  <!-- The QIF id of an Edge may appear at most once in the -->
  <!-- EdgeIds of the Bodies of a Product    -->

  <xsl:template
      match="/t:QIFDocument/t:Product/t:TopologySet/t:EdgeSet/t:Edge"
      mode="Semantic">
    <xsl:variable name="id" select="@id"/>
    <xsl:variable name="matchingIds"
		  select="/t:QIFDocument/t:Product/t:TopologySet/t:BodySet
			  /t:Body/t:EdgeIds/t:Id[. = $id]"/>
    <xsl:if test="(count($matchingIds) > 1)">
      <xsl:call-template name="error_node">
        <xsl:with-param name="report">
          The Edge id <xsl:value-of select="$id"/> is
          used in more than one Body.
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Vertex, the check:                                    -->
  <!-- The QIF id of a Vertex may appear at most once in the -->
  <!-- VertexIds of the Bodies of a Product                  -->

  <xsl:template
      match="/t:QIFDocument/t:Product/t:TopologySet/t:VertexSet/t:Vertex"
      mode="Semantic">
    <xsl:variable name="id" select="@id"/>
    <xsl:variable name="matchingIds"
		  select="/t:QIFDocument/t:Product/t:TopologySet/t:BodySet
			  /t:Body/t:VertexIds/t:Id[. = $id]"/>
    <xsl:if test="(count($matchingIds) > 1)">
      <xsl:call-template name="error_node">
        <xsl:with-param name="report">
          The Vertex id <xsl:value-of select="$id"/> is
          used in more than one Body.
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
    
  <!-- Point, the check:                                    -->
  <!-- The QIF id of a Point may appear at most once in the -->
  <!-- Vertices of a Product                                -->

  <xsl:template
      match="/t:QIFDocument/t:Product/t:GeometrySet/t:PointSet/t:Point"
      mode="Semantic">
    <xsl:variable name="id" select="@id"/>
    <xsl:variable name="matchingIds"
		  select="/t:QIFDocument/t:Product/t:TopologySet/t:VertexSet
			  /t:Vertex/t:Point/t:Id[. = $id]"/>
    <xsl:if test="(count($matchingIds) > 1)">
      <xsl:call-template name="error_node">
        <xsl:with-param name="report">
          The Point id <xsl:value-of select="$id"/> is
          used in more than one Vertex.
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
