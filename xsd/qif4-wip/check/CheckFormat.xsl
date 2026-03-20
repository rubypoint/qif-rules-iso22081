<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:t="http://qifstandards.org/xsd/qif4">
  
  <xsl:import href="CheckLibrary.xsl"/>
  
  <xsl:output method="xml" indent="yes" />

  <!-- skip text content -->
  <xsl:template match="text()" mode="Format" />

  <!-- idMax -->
  <xsl:template match="//t:*[@id &gt; /t:QIFDocument/@idMax]" mode="Format">
    <xsl:call-template name="error_node">
      <xsl:with-param name="report">
        The id of element is greater than idMax.
        id(<xsl:value-of select="@id"/>) greater than
        idMax(<xsl:value-of select="/t:QIFDocument/@idMax"/>).
      </xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates mode="Format"/>
  </xsl:template>

  <!-- Links with external documents -->
  <!-- Warning: some XSLT 1.0 processors (e.g. the one in XMLSpy) signal -->
  <!-- an error if the document function does not find what it is        -->
  <!-- looking for and no output file is produced. Other XSLT processors -->
  <!-- (e.g. xsltproc) return an empty node list that can be tested,     -->
  <!-- and will produce an output file if the document function fails.   -->

  <xsl:template
    match="t:ExternalReferences/t:ExternalQIFReferences/t:ExternalQIFDocument"
    mode="Format">
    <xsl:variable name="id" select="@id"/>
    <xsl:variable name="UUID" select="t:UUID"/>
    <xsl:variable name="URI" select="t:URI"/>
    <xsl:choose>
      <xsl:when test="document($URI)">
        <xsl:variable name="docExt" select="document($URI)/t:QIFDocument"/>
        <xsl:variable name="QIFUUID" select="$docExt/t:QIFUUID"/>
        <xsl:choose>
          <xsl:when test="not($UUID = $QIFUUID)">
            <xsl:call-template name="error_node">
              <xsl:with-param name="report">
                The external document has a different UUID.
                URI = <xsl:value-of select="$URI"/>,
                UUID(<xsl:value-of select="$UUID"/>)
                != QIFUUID(<xsl:value-of select="$QIFUUID"/>).
              </xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:for-each select="//t:*[@xId][. = $id]">
              <xsl:variable name="xId" select="@xId"/>
              <xsl:if test="not(count($docExt//t:*[@id = $xId]) = 1)">
                <xsl:call-template name="error_node">
                  <xsl:with-param name="report">
                    The external entity with this id was not found.
                    URI = <xsl:value-of select="$URI"/>,
                    idDoc(<xsl:value-of select="$id"/>),
                    xId(<xsl:value-of select="$xId"/>).
                  </xsl:with-param>
                </xsl:call-template>
              </xsl:if>
            </xsl:for-each>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="error_node">
          <xsl:with-param name="report">
            The external document was not found
            URI = <xsl:value-of select="$URI"/>.
          </xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates mode="Format"/>
  </xsl:template>

<!--

2D/3D NURBS curves, the checks:
1. The actual number of control points = count for the control points
2. The number of control points = the number of knots - the curve order
3. If weights are given, count for weights = count for control points
4. If weights are given, actual number of weights = count for weights

-->

  <xsl:template
    match="/t:QIFDocument/t:Product/t:GeometrySet/t:Curve12Set/t:Nurbs12
           /t:Nurbs12Core
         | /t:QIFDocument/t:Product/t:GeometrySet/t:Curve13Set/t:Nurbs13
           /t:Nurbs13Core"
                mode="Format">
    <xsl:variable name="nCP">
      <xsl:if test="t:ControlPoints/t:CPs">
        <xsl:value-of select="t:ControlPoints/t:CPs/@count"/>
      </xsl:if>
      <xsl:if test="t:ControlPoints/t:CPsBinary">
        <xsl:value-of select="t:ControlPoints/t:CPsBinary/@count"/>
      </xsl:if>
    </xsl:variable>
    <xsl:if test="not($nCP = t:Knots/@count - t:Order)">
      <xsl:for-each select=".">
        <xsl:call-template name="error_node">
          <xsl:with-param name="report">
            Nurbs12Core/Nurbs13Core: id=<xsl:value-of select="../@id"/>,
            nCP(<xsl:value-of select="$nCP"/>)
            != nKt(<xsl:value-of select="t:Knots/@count"/>) - 
            order(<xsl:value-of select="t:Order"/>)
          </xsl:with-param>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:if>
    
    <xsl:apply-templates mode="Format"/>
  </xsl:template>

<!-- NURBS surface, the check:
   the number of control points = ('nKtU' - 'ordU')*('nKtV' - 'ordV') -->

  <xsl:template
    match="/t:QIFDocument/t:Product/t:GeometrySet/t:SurfaceSet/t:Nurbs23
           /t:Nurbs23Core"
    mode="Format">
    <xsl:variable name="nCP">
      <xsl:if test="t:ControlPoints/t:CPs">
        <xsl:value-of select="t:ControlPoints/t:CPs/@count"/>
      </xsl:if>
      <xsl:if test="t:ControlPoints/t:CPsBinary">
        <xsl:value-of select="t:ControlPoints/t:CPsBinary/@count"/>
      </xsl:if>
    </xsl:variable>
    <xsl:if test="not($nCP = (t:KnotsU/@count - t:OrderU) *
                             (t:KnotsV/@count - t:OrderV))">
      <xsl:for-each select=".">
        <xsl:call-template name="error_node">
          <xsl:with-param name="report">
            Nurbs23Core: id=<xsl:value-of select="../@id"/>,
            nCP(<xsl:value-of select="$nCP"/>) !=
            (nKtU(<xsl:value-of select="t:KnotsU/@count"/>) -
            ordU(<xsl:value-of select="t:OrderU"/>)) *
            (nKtV(<xsl:value-of select="t:KnotsV/@count"/>) -
            ordV(<xsl:value-of select="t:OrderV"/>))
          </xsl:with-param>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:if>
    <xsl:apply-templates mode="Format"/>
  </xsl:template>
  
  <!-- Array of elements, the check: number of elements must be equal to
       a value specified in the attribute 'n' -->

  <xsl:template match="//t:*[@n]" mode="Format">
    <xsl:choose>
      <xsl:when test="(local-name()='BestFit'
                         and local-name(..)='Constructed'
                         and (contains(local-name(../..), 'FeatureNominal')
                              or contains(local-name(../..), 'CheckDetails'))
                      or
                      (local-name()='CenterOfGravity'
                      and local-name(..)='Constructed')
                      or
                      (local-name()='UserDefined'
                      and local-name(..)='Constructed'))
		      ">
        <xsl:if test="not(@n = count(t:*[local-name()='BaseFeature']))">
          <xsl:call-template name="error_node">
            <xsl:with-param name="report">
              The number of BaseFeature elements doesn't correspond to the
              specified "n" attribute: n(<xsl:value-of select="@n"/>) != 
              nElem(<xsl:value-of
              select="count(t:*[local-name()='BaseFeature'])"/>)
            </xsl:with-param>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
      <xsl:when test="local-name()='BestFit'
                 and local-name(..)='AlignmentOperations'">
        <xsl:if test="not(@n = count(t:*[local-name()='BaseFeature']))">
          <xsl:call-template name="error_node">
            <xsl:with-param name="report">
              The number of BaseFeature elements doesn't correspond to the
              specified "n" attribute: n(<xsl:value-of select="@n"/>) != 
              nElem(<xsl:value-of
              select="count(t:*[local-name()='BaseFeature'])"/>)
            </xsl:with-param>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
      <xsl:when test="local-name()='MeasurementOffset'
                 and local-name(..)='AlignmentOperations'">
        <xsl:if test="not(@n = count(t:*[local-name()='Origin']))">
          <xsl:call-template name="error_node">
            <xsl:with-param name="report">
              The number of Origin elements doesn't correspond to the
              specified "n" attribute: n(<xsl:value-of select="@n"/>) != 
              nElem(<xsl:value-of
              select="count(t:*[local-name()='Origin'])"/>)
            </xsl:with-param>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
      <xsl:when test="local-name()='CompoundDatum'">
        <xsl:if test="not(@n = count(t:*[local-name()='Datum']))">
          <xsl:call-template name="error_node">
            <xsl:with-param name="report">
              The number of Datum elements doesn't correspond to the
              specified "n" attribute: n(<xsl:value-of select="@n"/>) != 
              nElem(<xsl:value-of
              select="count(t:*[local-name()='Datum'])"/>)
            </xsl:with-param>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
      <xsl:when test="local-name()='NominalPointSet'">
        <xsl:if test="not(@n = count(t:*[local-name()='MeasurePoint']))">
          <xsl:call-template name="error_node">
            <xsl:with-param name="report">
              The number of MeasurePoint elements doesn't correspond to the
              specified "n" attribute: n(<xsl:value-of select="@n"/>) != 
              nElem(<xsl:value-of
              select="count(t:*[local-name()='MeasurePoint'])"/>)
            </xsl:with-param>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
      <xsl:when test="local-name()='AlignmentOperations'">
	<xsl:variable name="nOps"
		      select="count(t:*[local-name()='PrimaryAlignment'
		      or local-name()='SecondaryAlignment'
		      or local-name()='MeasurementOffset'
		      or local-name()='NominalOffset'
		      or local-name()='NominalRotation'
		      or local-name()='DatumPrecedence'
		      or local-name()='BestFit'
		      or local-name()='Machine'])"/>
        <xsl:if test="not(@n = $nOps)">
          <xsl:for-each select=".">
            <xsl:call-template name="error_node">
              <xsl:with-param name="report">
                The number of alignment operation elements doesn't correspond to
                the specified "n" attribute: n(<xsl:value-of select="@n"/>) != 
                nElem(<xsl:value-of select="$nOps"/>)
              </xsl:with-param>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise> 
        <xsl:if test="not(@n = count(t:*))">
          <xsl:for-each select=".">
            <xsl:call-template name="error_node">
              <xsl:with-param name="report">
                The number of array elements doesn't correspond to the
                specified "n" attribute: n(<xsl:value-of select="@n"/>) != 
                nElem(<xsl:value-of select="count(t:*)"/>)
              </xsl:with-param>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates mode="Format"/>
  </xsl:template>

<!--

template for the square of the length of a 3D vector represented as an
xs:list of three numerical values.

-->

  <xsl:template name="lengthSquare3D">
    <xsl:param name="vec3D"/>
    <xsl:variable name="norm">
      <xsl:value-of select="normalize-space($vec3D)"/>
    </xsl:variable>
    <xsl:variable name="first">
      <xsl:value-of select='substring-before($norm, " ")'/>
    </xsl:variable>
    <xsl:variable name="rest">
      <xsl:value-of select='substring-after($norm, " ")'/>
    </xsl:variable>
    <xsl:variable name="second">
      <xsl:value-of select='substring-before($rest, " ")'/>
    </xsl:variable>
    <xsl:variable name="third">
      <xsl:value-of select='substring-after($rest, " ")'/>
    </xsl:variable>
    <xsl:variable name="x">
      <xsl:value-of select="number($first)"/>
    </xsl:variable>
    <xsl:variable name="y">
      <xsl:value-of select="number($second)"/>
    </xsl:variable>
    <xsl:variable name="z">
      <xsl:value-of select="number($third)"/>
    </xsl:variable>
    <xsl:value-of select="($x*$x) + ($y*$y) + ($z*$z)"/>
  </xsl:template>

<!--

Unit vector, the check: the sum of the squares of the components must
not be less than MinLength squared and must not be greater than MaxLength
squared. MinLength and MaxLength are parameters from CheckParameters.xml.

This is checking only 3D unit vectors. 

See the file unitVectors.txt for an analysis of where all elements are
found whose type is a 3D unit vector type; there are four 3D unit vector
types.
-->

 <xsl:template
     match="//t:AnalysisVector
          | //t:AxisDirection
          | //t:AxisVector
          | //t:DatumTargetTranslationDirection
          | //t:DepthVector
          | //t:DirMeridianPrime
          | //t:DirNorthPole
          | //t:LengthDirection
          | //t:LengthVector
          | //t:NominalDirection
          | //t:Normal
          | //t:NormalSpecial
          | //t:OriginDirection
          | //t:PrimaryAxis
          | //t:RectangularUnitAreaOrientation
          | //t:RotationAxis
          | //t:SecondaryAxis
          | //t:Vector
          | //t:WidthDirection
          | //t:XDirection
          | //t:YDirection
          | //t:ZDirection
          | //t:ZoneDirection
          | //t:ZoneOrientationVector
          | /t:QIFDocument/t:Features/t:FeatureNominals/t:*/t:AdjacentNormal 
          | /t:QIFDocument/t:Features/t:FeatureNominals/t:*/t:Direction
          | /t:QIFDocument/t:Features/t:FeatureNominals/t:*/t:DraftVector
          | /t:QIFDocument/t:Features/t:FeatureNominals/t:*/t:FeatureDirection
          | /t:QIFDocument/t:Features/t:FeatureNominals/t:*/t:LineDirection
          | /t:QIFDocument/t:Features/t:FeatureNominals/t:*/t:PlaneNormal
          | /t:QIFDocument/t:Features/t:FeatureNominals/t:*/t:StartDirection
          | /t:QIFDocument/t:Features/t:FeatureNominals/t:*/t:Axis/t:Direction
          | /t:QIFDocument/t:Features/t:FeatureNominals/t:*/t:Sweep/t:DirBeg
          | /t:QIFDocument/t:FeatureZones/t:FeatureZoneAreaCylindrical
            /t:Cylinder/t:Axis
          | /t:QIFDocument/t:Product/t:GeometrySet/t:Curve13Set
            /t:ArcCircular13/t:ArcCircular13Core/t:DirBeg
          | /t:QIFDocument/t:Product/t:GeometrySet/t:Curve13Set
            /t:ArcConic13/t:ArcConic13Core/t:DirBeg
          | /t:QIFDocument/t:Product/t:VisualizationSet/t:PMIDisplaySet
            /t:PMIDisplay/t:Plane/t:Direction
          | /t:QIFDocument/t:Product/t:ViewSet/t:AnnotationViewSet
            /t:AnnotationView/t:Direction
          | /t:QIFDocument/t:Product/t:ViewSet/t:ExplodedViewSet
            /t:ExplodedView/t:MoveGroups/t:MoveGroup/t:Translate/t:Direction
          | /t:QIFDocument/t:Product/t:ViewSet/t:ExplodedViewSet
            /t:ExplodedView/t:MoveGroups/t:MoveGroup/t:Rotate/t:Axis
          | /t:QIFDocument/t:Product/t:ZoneSectionSet/t:ZoneSection
            /t:SectionPlanes/t:SectionPlane/t:Plane/t:Direction
          | /t:QIFDocument/t:MeasurementsResults/t:MeasurementResultsSet
            /t:MeasurementResults/t:MeasuredFeatures/t:*
            /t:SweepFull/t:DirBeg
          | /t:QIFDocument/t:MeasurementsResults/t:MeasurementResultsSet
            /t:MeasurementResults/t:MeasuredFeatures/t:*
            /t:SweepMeasurementRange/t:DirBeg
          | /t:QIFDocument/t:MeasurementsResults/t:MeasurementResultsSet/
             t:MeasurementResults/t:MeasuredFeatures/t:*/t:Axis/t:Direction"
     mode="Format">
    <xsl:variable
      name="minLength"
      select="$CheckParameters/CheckFormatParameters
             /Check[@name='unitVectorLength']/Parameter[@name='MinLength']"/>
    <xsl:variable
      name="maxLength"
      select="$CheckParameters/CheckFormatParameters
             /Check[@name='unitVectorLength']/Parameter[@name='MaxLength']"/>
    <xsl:variable name="minSquare" select="$minLength*$minLength"/>
    <xsl:variable name="maxSquare" select="$maxLength*$maxLength"/>
    <xsl:variable name="lengthSquare">
      <xsl:call-template name="lengthSquare3D">
        <xsl:with-param name="vec3D" select="." />
      </xsl:call-template>
    </xsl:variable>
    <xsl:if test="$lengthSquare &gt; $maxSquare">
      <xsl:call-template name="error_node">
        <xsl:with-param name="report">
          Unit vector too long: length of (<xsl:value-of select="."/>
          greater than <xsl:value-of select="$maxLength"/>)
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="$lengthSquare &lt; $minSquare">
      <xsl:call-template name="error_node">
        <xsl:with-param name="report">
          Unit vector too short: length of (<xsl:value-of select="."/>
          less than <xsl:value-of select="$minLength"/>)
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
    <xsl:apply-templates mode="Format"/>
  </xsl:template>

<!--

template for the length (number of entries) of an xs:list.
This returns 1 plus the number of spaces in the normalized list. 
That number is found by subtracting [the number of characters in the
normalized list with the spaces removed] from [the number of characters
in the normalized list with the spaces included].

-->

  <xsl:template name="simpleListLength">
    <xsl:param name="lizt"/>
    <xsl:variable name="norm">
      <xsl:value-of select="normalize-space($lizt)"/>
    </xsl:variable>
    <xsl:value-of select="1 + string-length($norm) -
                          string-length(translate($norm, ' ', ''))"/>
  </xsl:template>

  <!-- generic count checker -->

  <xsl:template name = "countChecker">
    <xsl:param name="givenCount"/>
    <xsl:param name="liszt"/>
    <xsl:param name="elementName"/>
    <xsl:variable name="actualCount">
      <xsl:call-template name="simpleListLength">
        <xsl:with-param name="lizt" select="$liszt"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:if test = "$givenCount != $actualCount">
      <xsl:call-template name="error_node">
        <xsl:with-param name="report">
          The count attribute of the <xsl:value-of select="$elementName"/>
	  element differs from the actual number of values.
          (<xsl:value-of select="$givenCount"/> !=
           <xsl:value-of select="$actualCount"/>)
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Check the value of 'count' used in a UserEnumType -->
  <xsl:template
      match = "/t:QIFDocument/t:Characteristics/t:UserCriticalityLevels
               /t:Selections"
      mode="Format">
    <xsl:call-template name="countChecker">
      <xsl:with-param name="givenCount" select="./@count"/>
      <xsl:with-param name="liszt" select="."/>
      <xsl:with-param name="elementName">Selections</xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates mode="Format"/>
  </xsl:template>
  
  <!-- Check the value of 'count' used in a SeriesDoubleWithUnitType -->
  <xsl:template
      match = "/t:QIFDocument/t:Features/t:FeatureNominals
               /t:UserDefinedFeatureNominal/t:DefiningPropertyNominals
               /t:DefiningPropertyNominal/t:DoubleValuedSeriesNominal"
      mode="Format">
    <xsl:call-template name="countChecker">
      <xsl:with-param name="givenCount" select="./@count"/>
      <xsl:with-param name="liszt" select="."/>
      <xsl:with-param name="elementName">DoubleValuedSeriesNominal
      </xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates mode="Format"/>
  </xsl:template>

  <!-- Check the value of 'count' used in a SeriesTokenType -->
  <xsl:template
      match = "/t:QIFDocument/t:Features/t:FeatureNominals
               /t:UserDefinedFeatureNominal/t:DefiningPropertyNominals
               /t:DefiningPropertyNominal/t:StringValuedSeriesNominal"
      mode="Format">
    <xsl:call-template name="countChecker">
      <xsl:with-param name="givenCount" select="./@count"/>
      <xsl:with-param name="liszt" select="."/>
      <xsl:with-param name="elementName">StringValuedSeriesNominal
      </xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates mode="Format"/>
  </xsl:template>
    
  <!-- Check the value of 'count' used in a SeriesIntegerWithUnitType -->
  <xsl:template
      match = "/t:QIFDocument/t:Features/t:FeatureNominals
               /t:UserDefinedFeatureNominal/t:DefiningPropertyNominals
               /t:DefiningPropertyNominal/t:IntegerValuedSeriesNominal"
      mode="Format">
    <xsl:call-template name="countChecker">
      <xsl:with-param name="givenCount" select="./@count"/>
      <xsl:with-param name="liszt" select="."/>
      <xsl:with-param name="elementName">IntegerValuedSeriesNominal
      </xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates mode="Format"/>
  </xsl:template>

  <!-- Check the value of 'count' used in TimeValues results -->
  <xsl:template
      match = "/t:QIFDocument/t:Results/t:MeasurementResultsSet
               /t:MeasurementResults/t:MeasuredFeatures
               /t:UserDefinedFeatureMeasurement/t:MeasuredSeries
	       /t:MeasuredTimeSeries/t:TimeValues"
      mode="Format">
    <xsl:call-template name="countChecker">
      <xsl:with-param name="givenCount" select="./@count"/>
      <xsl:with-param name="liszt" select="."/>
      <xsl:with-param name="elementName">TimeValues</xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates mode="Format"/>
  </xsl:template>

  <!-- Check the value of 'count' used in IntSeries results -->
  <xsl:template
      match = "/t:QIFDocument/t:Results/t:MeasurementResultsSet
               /t:MeasurementResults/t:MeasuredFeatures
               /t:UserDefinedFeatureMeasurement/t:MeasuredSeries
	       /t:MeasuredTimeSeries/t:MeasuredPropertiesValues
	       /t:MeasuredPropertySeries/t:IntSeries"
      mode="Format">
    <xsl:call-template name="countChecker">
      <xsl:with-param name="givenCount" select="./@count"/>
      <xsl:with-param name="liszt" select="."/>
      <xsl:with-param name="elementName">IntSeries</xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates mode="Format"/>
  </xsl:template>

  <!-- Check the value of 'count' used in DoubleSeries results -->
  <xsl:template
      match = "/t:QIFDocument/t:Results/t:MeasurementResultsSet
               /t:MeasurementResults/t:MeasuredFeatures
               /t:UserDefinedFeatureMeasurement/t:MeasuredSeries
	       /t:MeasuredTimeSeries/t:MeasuredPropertiesValues
	       /t:MeasuredPropertySeries/t:DoubleSeries"
      mode="Format">
    <xsl:call-template name="countChecker">
      <xsl:with-param name="givenCount" select="./@count"/>
      <xsl:with-param name="liszt" select="."/>
      <xsl:with-param name="elementName">DoubleSeries</xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates mode="Format"/>
  </xsl:template>

  <!-- Check the value of 'count' used in TokenSeries results -->
  <xsl:template
      match = "/t:QIFDocument/t:Results/t:MeasurementResultsSet
               /t:MeasurementResults/t:MeasuredFeatures
               /t:UserDefinedFeatureMeasurement/t:MeasuredSeries
	       /t:MeasuredTimeSeries/t:MeasuredPropertiesValues
	       /t:MeasuredPropertySeries/t:TokenSeries"
      mode="Format">
    <xsl:call-template name="countChecker">
      <xsl:with-param name="givenCount" select="./@count"/>
      <xsl:with-param name="liszt" select="."/>
      <xsl:with-param name="elementName">TokenSeries</xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates mode="Format"/>
  </xsl:template>

 <!-- Check the value of 'count' used in ControlledRealValues results -->
  <xsl:template
      match = "/t:QIFDocument/t:Results/t:MeasurementResultsSet
               /t:MeasurementResults/t:MeasuredFeatures
               /t:UserDefinedFeatureMeasurement/t:MeasuredSeries
	       /t:MeasuredValueSeries/t:ControlledRealValues"
      mode="Format">
    <xsl:call-template name="countChecker">
      <xsl:with-param name="givenCount" select="./@count"/>
      <xsl:with-param name="liszt" select="."/>
      <xsl:with-param name="elementName">ControlledRealValues
      </xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates mode="Format"/>
  </xsl:template>

  <!-- Check the value of 'count' used in ControlledIntegerValues results -->
  <xsl:template
      match = "/t:QIFDocument/t:Results/t:MeasurementResultsSet
               /t:MeasurementResults/t:MeasuredFeatures
               /t:UserDefinedFeatureMeasurement/t:MeasuredSeries
	       /t:MeasuredValueSeries/t:ControlledIntegerValues"
      mode="Format">
    <xsl:call-template name="countChecker">
      <xsl:with-param name="givenCount" select="./@count"/>
      <xsl:with-param name="liszt" select="."/>
      <xsl:with-param name="elementName">ControlledIntegerValues
      </xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates mode="Format"/>
  </xsl:template>

  <!-- Check the value of 'count' used in ControlledStringValues results -->
  <xsl:template
      match = "/t:QIFDocument/t:Results/t:MeasurementResultsSet
               /t:MeasurementResults/t:MeasuredFeatures
               /t:UserDefinedFeatureMeasurement/t:MeasuredSeries
	       /t:MeasuredValueSeries/t:ControlledStringValues"
      mode="Format">
    <xsl:call-template name="countChecker">
      <xsl:with-param name="givenCount" select="./@count"/>
      <xsl:with-param name="liszt" select="."/>
      <xsl:with-param name="elementName">ControlledStringValues
      </xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates mode="Format"/>
  </xsl:template>

  <!-- Check the value of 'count' used in FunctionDiscreteType -->
  <xsl:template
      match = "/t:QIFDocument/t:MeasurementResources/t:MeasurementDevices
               /t:ComputedTomographyMachine/t:ActivePixelNumber"
      mode="Format">
    <xsl:call-template name="checkFunctionDiscreteType">
      <xsl:with-param name="func" select="."/>
    </xsl:call-template>
  </xsl:template>

  <!-- Check the value of 'count' used in FunctionDiscreteType in
       CartesianCMMFPSPerformance  -->
  <xsl:template
      match = "/t:QIFDocument/t:MeasurementResources/t:MeasurementDevices
	       /t:CartesianCMM/t:Performances/t:CartesianCMMFPSPerformance"
      mode="Format">
    <xsl:for-each select="*">
      <xsl:if test = "contains(local-name(), 'XLinearity')
		      or contains(local-name(), 'YLinearity')
		      or contains(local-name(), 'ZLinearity')
		      or contains(local-name(), 'XAxisRoll')
		      or contains(local-name(), 'XAxisPitch')
		      or contains(local-name(), 'XAxisYaw')
		      or contains(local-name(), 'YAxisRoll')
		      or contains(local-name(), 'YAxisPitch')
		      or contains(local-name(), 'YAxisYaw')
		      or contains(local-name(), 'ZAxisRoll')
		      or contains(local-name(), 'ZAxisPitch')
		      or contains(local-name(), 'ZAxisYaw')
		      or contains(local-name(), 'XAxisStraightnessY')
		      or contains(local-name(), 'XAxisStraightnessZ')
		      or contains(local-name(), 'YAxisStraightnessX')
		      or contains(local-name(), 'YAxisStraightnessZ')
		      or contains(local-name(), 'ZAxisStraightnessX')
		      or contains(local-name(), 'ZAxisStraightnessY')">
	<xsl:call-template name="checkFunctionDiscreteType">
	  <xsl:with-param name="func" select="."/>
	</xsl:call-template>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="checkFunctionDiscreteType">
    <xsl:param name="func"/>
    <xsl:variable name="givenCount" select="$func/@count"/>
    <xsl:variable name="domainCount">
      <xsl:call-template name="simpleListLength">
        <xsl:with-param name="lizt" select="$func/t:DomainValues"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="rangeCount">
      <xsl:call-template name="simpleListLength">
        <xsl:with-param name="lizt" select="$func/t:RangeValues"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:if test = "$givenCount != $domainCount">
      <xsl:call-template name="error_node">
        <xsl:with-param name="report">
          The count attribute of a FunctionDiscreteType differs from the
	  actual number of DomainValues.
          (<xsl:value-of select="$givenCount"/> !=
           <xsl:value-of select="$domainCount"/>)
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test = "$givenCount != $rangeCount">
      <xsl:call-template name="error_node">
        <xsl:with-param name="report">
          The count attribute of a FunctionDiscreteType differs from the
	  actual number of RangeValues.
          (<xsl:value-of select="$givenCount"/> !=
           <xsl:value-of select="$rangeCount"/>)
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  
<!-- Check the various values of 'count' used in a measured point set -->
<!-- against each other or against an actual count -->
<!-- Might add checking more actual counts (or string-length for -->
<!-- base64binary) against the 'count' values -->

  <xsl:template
      match = "/t:QIFDocument/t:Results/t:MeasurementResultsSet
               /t:MeasurementResults/t:MeasuredPointSets/t:MeasuredPointSet"
      mode="Format">
    <xsl:variable name="countMain" select="./@count"/>
    <xsl:choose>
      <xsl:when test="./t:PointsChoice/t:Points">
        <xsl:variable name="pointsLength">
          <xsl:call-template name="simpleListLength">
            <xsl:with-param name="lizt" select="./t:PointsChoice/t:Points"/>
          </xsl:call-template>
        </xsl:variable>              
        <xsl:if test = "./t:PointsChoice/t:Points/@count != $countMain">
          <xsl:call-template name="error_node">
            <xsl:with-param name="report">
              In the MeasuredPointSet with id <xsl:value-of select="./@id"/>
              the count attribute of the Points element differs from the
              count attribute of the MeasuredPointSet.
              (<xsl:value-of select="./t:PointsChoice/t:Points/@count"/> !=
              <xsl:value-of select="$countMain"/>)
            </xsl:with-param>
          </xsl:call-template>
        </xsl:if>
        <xsl:if test = "$pointsLength != 3 * ./t:PointsChoice/t:Points/@count">
          <xsl:call-template name="error_node">
            <xsl:with-param name="report">
              In the MeasuredPointSet with id <xsl:value-of select="./@id"/>
              three times the count attribute of the Points element differs
              from the actual number of items in the Points list.
              (<xsl:value-of select="3 * ./t:PointsChoice/t:Points/@count"/>
              != <xsl:value-of select="$pointsLength"/>)
            </xsl:with-param>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test = "./t:PointsChoice/t:PointsBinary/@count
                        != (3 * $countMain)">
          <xsl:call-template name="error_node">
            <xsl:with-param name="report">
              In the MeasuredPointSet with id <xsl:value-of select="./@id"/>
              the count attribute of the PointsBinary element differs from
              three times the count attribute of the MeasuredPointSet.
              (<xsl:value-of select="./t:PointsChoice/t:PointsBinary/@count"/>
              != 3 * <xsl:value-of select="$countMain"/>)
            </xsl:with-param>
          </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="./t:NormalsChoice">
      <xsl:choose>
        <xsl:when test="./t:NormalsChoice/t:Normals">
          <xsl:if
              test = "./t:NormalsChoice/t:Normals/@count != $countMain">
            <xsl:call-template name="error_node">
              <xsl:with-param name="report">
                In the MeasuredPointSet with id <xsl:value-of select="./@id"/>
                the count attribute of the Normals element differs from the
                count attribute of the MeasuredPointSet.
                (<xsl:value-of select="./t:NormalsChoice/t:Normals/@count"/> !=
                <xsl:value-of select="$countMain"/>)
              </xsl:with-param>
            </xsl:call-template>
          </xsl:if>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test = "./t:NormalsChoice/t:NormalsBinary/@count !=
                          (3 * $countMain)">
            <xsl:call-template name="error_node">
              <xsl:with-param name="report">
                In the MeasuredPointSet with id <xsl:value-of select="./@id"/>
                the count attribute of the NormalsBinary element differs from
                three times the count attribute of the MeasuredPointSet.
                (<xsl:value-of
                select="./t:NormalsChoice/t:NormalsBinary/@count"/>
                != 3 * <xsl:value-of select="$countMain"/>)
              </xsl:with-param>
            </xsl:call-template>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="(./t:CompensationChoice) and
                  (not(./t:CompensationChoice/t:Compensated))">
      <xsl:choose>
        <xsl:when test="./t:CompensationChoice/t:Compensations">
          <xsl:variable name="compensationsLength">
            <xsl:call-template name="simpleListLength">
              <xsl:with-param name="lizt"
                              select="./t:CompensationChoice/t:Compensations"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:if test = "$compensationsLength != $countMain">
            <xsl:call-template name="error_node">
              <xsl:with-param name="report">
                In the MeasuredPointSet with id <xsl:value-of select="./@id"/>
                the number of entries in the Compensations element differs
                from the count attribute of the MeasuredPointSet.
                (<xsl:value-of select="$compensationsLength"/> !=
                <xsl:value-of select="$countMain"/>)
              </xsl:with-param>
            </xsl:call-template>
          </xsl:if>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test = "./t:CompensationChoice/t:CompensationsBinary/@count !=
                          $countMain">
            <xsl:call-template name="error_node">
              <xsl:with-param name="report">
                In the MeasuredPointSet with id <xsl:value-of select="./@id"/>
                the count attribute of the CompensationsBinary element differs
                from the count attribute of the MeasuredPointSet.
                (<xsl:value-of
                select="./t:CompensationChoice/t:CompensationsBinary/@count"/>
                != <xsl:value-of select="$countMain"/>)
              </xsl:with-param>
            </xsl:call-template>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="(./t:ProbeRadiusChoice) and
                  (not(./t:ProbeRadiusChoice/t:ProbeRadius))">
      <xsl:choose>
        <xsl:when test="./t:ProbeRadiusChoice/t:ProbeRadii">
          <xsl:variable name="radiiLength">
            <xsl:call-template name="simpleListLength">
              <xsl:with-param name="lizt"
                              select="./t:ProbeRadiusChoice/t:ProbeRadii"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:if test = "$radiiLength != $countMain">
            <xsl:call-template name="error_node">
              <xsl:with-param name="report">
                In the MeasuredPointSet with id <xsl:value-of select="./@id"/>
                the number of entries in the ProbeRadii element differs from
                the count attribute of the MeasuredPointSet.
                (<xsl:value-of select="$radiiLength"/> !=
                <xsl:value-of select="$countMain"/>)
              </xsl:with-param>
            </xsl:call-template>
          </xsl:if>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test = "./t:ProbeRadiusChoice/t:ProbeRadiiBinary/@count !=
                          $countMain">
            <xsl:call-template name="error_node">
              <xsl:with-param name="report">
                In the MeasuredPointSet with id <xsl:value-of select="./@id"/>
                the count attribute of the ProbeRadiiBinary element differs
                from the count attribute of the MeasuredPointSet.
                (<xsl:value-of
                select="./t:ProbeRadiusChoice/t:ProbeRadiiBinary/@count"/>
                != <xsl:value-of select="$countMain"/>)
              </xsl:with-param>
            </xsl:call-template>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="(./t:TipIdChoice) and
                  (not(./t:TipIdChoice/t:Id))">
      <xsl:choose>
        <xsl:when test="./t:TipIdChoice/t:Ids">
          <xsl:variable name="tipIdsLength">
            <xsl:call-template name="simpleListLength">
              <xsl:with-param name="lizt" select="./t:TipIdChoice/t:Ids"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:if
              test = "$tipIdsLength != $countMain">
            <xsl:call-template name="error_node">
              <xsl:with-param name="report">
                In the MeasuredPointSet with id <xsl:value-of select="./@id"/>
                the number of entries in the Ids element for tips differs from
                the count attribute of the MeasuredPointSet.
                (<xsl:value-of select="$tipIdsLength"/> !=
                <xsl:value-of select="$countMain"/>)
              </xsl:with-param>
            </xsl:call-template>
          </xsl:if>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test = "./t:TipIdChoice/t:IdsBinary/@count !=
                          $countMain">
            <xsl:call-template name="error_node">
              <xsl:with-param name="report">
                In the MeasuredPointSet with id <xsl:value-of select="./@id"/>
                the count attribute of the IdsBinary element for tips differs
                from the count attribute of the MeasuredPointSet.
                (<xsl:value-of
                select="./t:TipIdChoice/t:IdsBinary/@count"/>
                != <xsl:value-of select="$countMain"/>)
              </xsl:with-param>
            </xsl:call-template>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="(./t:SensorIdChoice) and
                  (not(./t:SensorIdChoice/t:Id))">
      <xsl:choose>
        <xsl:when test="./t:SensorIdChoice/t:Ids">
          <xsl:variable name="sensorIdsLength">
            <xsl:call-template name="simpleListLength">
              <xsl:with-param name="lizt" select="./t:SensorIdChoice/t:Ids"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:if
              test = "$sensorIdsLength != $countMain">
            <xsl:call-template name="error_node">
              <xsl:with-param name="report">
                In the MeasuredPointSet with id <xsl:value-of select="./@id"/>
                the number of entries in the Ids element for sensors differs
                from the count attribute of the MeasuredPointSet.
                (<xsl:value-of select="$sensorIdsLength"/> !=
                <xsl:value-of select="$countMain"/>)
              </xsl:with-param>
            </xsl:call-template>
          </xsl:if>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test = "./t:SensorIdChoice/t:IdsBinary/@count !=
                          $countMain">
            <xsl:call-template name="error_node">
              <xsl:with-param name="report">
                In the MeasuredPointSet with id <xsl:value-of select="./@id"/>
                the count attribute of the IdsBinary element for sensors differs
                from the count attribute of the MeasuredPointSet.
                (<xsl:value-of
                select="./t:SensorIdChoice/t:IdsBinary/@count"/>
                != <xsl:value-of select="$countMain"/>)
              </xsl:with-param>
            </xsl:call-template>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="./t:QualitiesChoice">
      <xsl:choose>
        <xsl:when test="./t:QualitiesChoice/t:ListDouble">
          <xsl:variable name="qualitiesLength">
            <xsl:call-template name="simpleListLength">
              <xsl:with-param name="lizt"
                              select="./t:QualitiesChoice/t:ListDouble"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:if
              test = "$qualitiesLength != $countMain">
            <xsl:call-template name="error_node">
              <xsl:with-param name="report">
                In the MeasuredPointSet with id <xsl:value-of select="./@id"/>
                the number of entries in the ListDouble element for qualities
                differs from the count attribute of the MeasuredPointSet.
                (<xsl:value-of select="$qualitiesLength"/> !=
                <xsl:value-of select="$countMain"/>)
              </xsl:with-param>
            </xsl:call-template>
          </xsl:if>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test = "./t:QualitiesChoice/t:DoublesBinary/@count !=
                          $countMain">
            <xsl:call-template name="error_node">
              <xsl:with-param name="report">
                In the MeasuredPointSet with id <xsl:value-of select="./@id"/>
                the count attribute of the DoublesBinary element for qualities
                differs from the count attribute of the MeasuredPointSet.
                (<xsl:value-of
                select="./t:QualitiesChoice/t:DoublesBinary/@count"/>
                != <xsl:value-of select="$countMain"/>)
              </xsl:with-param>
            </xsl:call-template>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="./t:DeviationsChoice">
      <xsl:choose>
        <xsl:when test="./t:DeviationsChoice/t:ListDouble">
          <xsl:variable name="deviationsLength">
            <xsl:call-template name="simpleListLength">
              <xsl:with-param name="lizt"
                              select="./t:DeviationsChoice/t:ListDouble"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:if
              test = "$deviationsLength != $countMain">
            <xsl:call-template name="error_node">
              <xsl:with-param name="report">
                In the MeasuredPointSet with id <xsl:value-of select="./@id"/>
                the number of entries in the ListDouble element for deviations
                differs from the count attribute of the MeasuredPointSet.
                (<xsl:value-of select="$deviationsLength"/> !=
                <xsl:value-of select="$countMain"/>)
              </xsl:with-param>
            </xsl:call-template>
          </xsl:if>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test = "./t:DeviationsChoice/t:DoublesBinary/@count !=
                          $countMain">
            <xsl:call-template name="error_node">
              <xsl:with-param name="report">
                In the MeasuredPointSet with id <xsl:value-of select="./@id"/>
                the count attribute of the DoublesBinary element for deviations
                differs from the count attribute of the MeasuredPointSet.
                (<xsl:value-of
                select="./t:DeviationsChoice/t:DoublesBinary/@count"/>
                != <xsl:value-of select="$countMain"/>)
              </xsl:with-param>
            </xsl:call-template>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="./t:MeasurePointNominalIdsChoice">
      <xsl:choose>
        <xsl:when test="./t:MeasurePointNominalIdsChoice/t:Ids">
          <xsl:if
              test="(./t:MeasurePointNominalIdsChoice/t:Ids/@asmPathXId) and
                    (not(./t:MeasurePointNominalIdsChoice/t:Ids/@asmPathId))">
            <xsl:call-template name="error_node">
              <xsl:with-param name="report">
                In the MeasurePointNominalIdsChoice of the MeasuredPointSet
                with id <xsl:value-of select="./@id"/> the asmPathXId
                has been used without the asmPathId.
              </xsl:with-param>
            </xsl:call-template>
          </xsl:if>
          <xsl:choose>
            <xsl:when test="./t:MeasurePointNominalIdsChoice/t:Ids/t:Ids">
              <xsl:variable name="nominalIdsLength">
                <xsl:call-template name="simpleListLength">
                  <xsl:with-param name="lizt"
                    select="./t:MeasurePointNominalIdsChoice/t:Ids/t:Ids"/>
                </xsl:call-template>
              </xsl:variable>
              <xsl:if test="$nominalIdsLength != $countMain">
                <xsl:call-template name="error_node">
                  <xsl:with-param name="report">
                    In the MeasuredPointSet with id
                    <xsl:value-of select="./@id"/>
                    the number of entries in the Ids/Ids of the
                    MeasurePointNominalIdsChoice element differs from the
                    count attribute of the MeasuredPointSet.
                    (<xsl:value-of select= "$nominalIdsLength"/> !=
                    <xsl:value-of select="$countMain"/>)
                  </xsl:with-param>
                </xsl:call-template>
              </xsl:if>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="xIdsLength">
                <xsl:call-template name="simpleListLength">
                  <xsl:with-param name="lizt"
                    select="./t:MeasurePointNominalIdsChoice/t:Ids/t:XIds"/>
                </xsl:call-template>
              </xsl:variable>
              <xsl:if test="$xIdsLength != $countMain">
                <xsl:call-template name="error_node">
                  <xsl:with-param name="report">
                    In the MeasuredPointSet with id
                    <xsl:value-of select="./@id"/>
                    the number of entries in the Ids/XIds of the
                    MeasurePointNominalIdsChoice element differs from the
                    count attribute of the MeasuredPointSet.
                    (<xsl:value-of select="$xIdsLength"/> !=
                    <xsl:value-of select="$countMain"/>)
                  </xsl:with-param>
                </xsl:call-template>
              </xsl:if>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if
              test="(./t:MeasurePointNominalIdsChoice/t:IdsBinary/@asmPathXId)
                    and
                (not(./t:MeasurePointNominalIdsChoice/t:IdsBinary/@asmPathId))">
            <xsl:call-template name="error_node">
              <xsl:with-param name="report">
                In the MeasurePointNominalIdsChoice of the MeasuredPointSet
                with id <xsl:value-of select="./@id"/> the asmPathXId
                has been used without the asmPathId.
              </xsl:with-param>
            </xsl:call-template>
          </xsl:if>
          <xsl:choose>
            <xsl:when test="./t:MeasurePointNominalIdsChoice/t:IdsBinary/t:Ids">
              <xsl:if
                test="./t:MeasurePointNominalIdsChoice/t:IdsBinary/t:Ids/@count
                      != $countMain">
                <xsl:call-template name="error_node">
                  <xsl:with-param name="report">
                    In the MeasuredPointSet with id
                    <xsl:value-of select="./@id"/>
                    the count attribute of the IdsBinary/Ids of the
                    MeasurePointNominalIdsChoice element differs from the
                    count attribute of the MeasuredPointSet.
                    (<xsl:value-of
                    select="./t:MeasurePointNominalIdsChoice/t:IdsBinary
                    /t:Ids/@count"/> != <xsl:value-of select="$countMain"/>)
                  </xsl:with-param>
                </xsl:call-template>
              </xsl:if>
            </xsl:when>
            <xsl:otherwise>
              <xsl:if
                test="./t:MeasurePointNominalIdsChoice/t:IdsBinary/t:XIds/@count
                      != $countMain">
                <xsl:call-template name="error_node">
                  <xsl:with-param name="report">
                    In the MeasuredPointSet with id
                    <xsl:value-of select="./@id"/>
                    the count attribute of the IdsBinary/XIds of the
                    MeasurePointNominalIdsChoice element differs from the
                    count attribute of the MeasuredPointSet.
                    (<xsl:value-of
                    select= "./t:MeasurePointNominalIdsChoice
                    /t:IdsBinary/t:XIds/@count"/> !=
                    <xsl:value-of select="$countMain"/>)
                  </xsl:with-param>
                </xsl:call-template>
              </xsl:if>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="./t:ColorsChoice">
      <xsl:choose>
        <xsl:when test="./t:ColorsChoice/t:Ints">
          <xsl:variable name="intsLength">
            <xsl:call-template name="simpleListLength">
              <xsl:with-param name="lizt" select="./t:ColorsChoice/t:Ints"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:if test = "$intsLength != 3 * $countMain">
            <xsl:call-template name="error_node">
              <xsl:with-param name="report">
                In the MeasuredPointSet with id <xsl:value-of select="./@id"/>
                the number of entries in the Ints element for colors
                differs from three times the count attribute of the
                MeasuredPointSet.
                (<xsl:value-of select="$intsLength"/> !=
                <xsl:value-of select="3 * $countMain"/>)
              </xsl:with-param>
            </xsl:call-template>
          </xsl:if>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test = "./t:ColorsChoice/t:IntsBinary/@count !=
                          $countMain">
            <xsl:call-template name="error_node">
              <xsl:with-param name="report">
                In the MeasuredPointSet with id <xsl:value-of select="./@id"/>
                the count attribute of the IntsBinary element for colors
                differs from the count attribute of the MeasuredPointSet.
                (<xsl:value-of
                select="./t:ColorsChoice/t:IntsBinary/@count"/>
                != <xsl:value-of select="$countMain"/>)
              </xsl:with-param>
            </xsl:call-template>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="(./t:TimeStampChoice) and
                  (not(./t:TimeStampChoice/t:TimeStamp)) and
                  (count(./t:TimeStampChoice/t:TimeStamps) != $countMain)">
      <xsl:call-template name="error_node">
        <xsl:with-param name="report">
          In the MeasuredPointSet with id <xsl:value-of select="./@id"/>
          the number of entries in the TimeStamps element
          differs from the count attribute of the MeasuredPointSet.
          (<xsl:value-of
          select="count(./t:TimeStampChoice/t:TimeStamps)"/> !=
          <xsl:value-of select="$countMain"/>)
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
    <xsl:apply-templates mode="Format"/>
  </xsl:template>


</xsl:stylesheet>
