<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:f="http://hl7.org/fhir"
    xmlns:v2="urn:hl7-org:v2xml" xmlns="http://hl7.org/fhir" exclude-result-prefixes="xs f v2"
    version="2.0">
    <xsl:output indent="yes"/>
    <xsl:param name="message" select="'ADT_A01'"/>
    <xsl:variable name="msg" select="document(concat($message, '.xsd'))"/>
    <xsl:variable name="segments" select="document('segments.xsd')"/>
    <xsl:variable name="fields" select="document('fields.xsd')"/>
    <xsl:variable name="datatypes" select="document('datatypes.xsd')"/>
    <xsl:variable name="parts" select="$msg | $segments | $fields | $datatypes"/>

    <xsl:template name="start">
        <xsl:apply-templates select="$msg"/>
    </xsl:template>
    
    <xsl:template match="/">
        <StructureDefinition>
            <extension url="http://hl7.org/fhir/StructureDefinition/elementdefinition-namespace">
                <valueUri value="{/xs:schema/@targetNamespace}"/>
            </extension>
            <url value="http://hl7.org/fhir/v2/StructureDefinition/{$message}"/>
            <xsl:variable name="versionText" select="normalize-space(/comment()[contains(., 'Version')])"/>
            <!-- version	String of the form #[.#+]+ in a comment containing the text version -->
            <xsl:variable name="versionNumber"
                select="replace($versionText, '^.* ([0-9]+(\.[0-9]+)+).*$', '$1')"/>
            <version value="{$versionNumber}"/>
            <!-- Value of complexType/annotation/appInfo/LongName for CONTENT definition of Field -->
            <name value="{$versionText}"/>
            <display value="{$versionText}"/>
            <status value="active"/>
            <experimental value="false"/>
            <xsl:variable name="copyrightText" select="normalize-space(/comment()[contains(., 'Copyright')])"/>
            <xsl:variable name="publisherName"
                select="substring-before(substring-after($copyrightText, ', '),'.')"/>
            <xsl:variable name="publishedText" select="normalize-space(/comment()[contains(., 'generated on')])"/>
            <xsl:variable name="publishedDate"
                select="substring-before(substring-after($publishedText, 'generated on '), ' ')"/>
            <publisher value="{$publisherName}"/>
            <date
                value="{substring($publishedDate, 7, 4)}{substring($publishedDate, 4, 2)}{substring($publishedDate, 1, 2)}"/>
            <description value="{$versionText}"/>
            <copyright value="{$copyrightText}"/>
            <code>
                <system value="http://hl7.org/fhir/v2/0076"/>
                <code value="{$message}"/>
            </code>
            <fhirVersion value="1.0.2"/>
            <kind value="logical"/>
            <abstract value="false"/>
            <constrainedType value="{$message}"/>
            <baseDefinition value="http://hl7.org/fhir/StructureDefinition/Element"/>
            <snapshot>
                <element id="{$message}">
                    <path value="{$message}"/>
                    <min value="1"/>
                    <max value="1"/>
                    <base>
                        <path value="{$message}"/>
                        <min value="1"/>
                        <max value="1"/>
                    </base>
                </element>
                <xsl:apply-templates
                    select="$msg//xs:complexType[@name = $msg//xs:element[@name = $message]/@type]">
                    <xsl:with-param name="path" select="$message"/>
                    <xsl:with-param name="depth" select="2"/>
                </xsl:apply-templates>
            </snapshot>
        </StructureDefinition>
    </xsl:template>

    <xsl:template match="xs:complexType">
        <xsl:param name="path"/>
        <xsl:param name="depth"/>
        <xsl:if test="xs:complexContent/xs:extension">
            <!-- Handle this
            <xsd:complexContent>
                <xsd:extension base="HD">
                    <xsd:attributeGroup ref="MSH.6.ATTRIBUTES"/>
                </xsd:extension>
            </xsd:complexContent>
            -->
            <xsl:variable name='base' select='xs:complexContent/xs:extension/@base'/>
            <xsl:comment>got here: <xsl:value-of select="$base"/></xsl:comment>
            <xsl:apply-templates select="$parts//xs:complexType[@name=$base]">
                <xsl:with-param name="path" select="$path"/>
                <xsl:with-param name="depth" select="$depth"/>
            </xsl:apply-templates>
        </xsl:if>
        <xsl:for-each select="xs:sequence/xs:element">
            <xsl:variable name="ref" select="@ref"/>
            <xsl:variable name="element"
                select="($msg | $parts)//xs:element[@name = $ref]"/>
            <xsl:variable name="name" select="translate($element/@name,'.','-')"/>
            <xsl:variable name="min" select="if (@minOccurs) then (@minOccurs) else ('1')"/>
            <xsl:variable name="max" select="if (@maxOccurs='unbounded') then ('*') else if (@maxOccurs) then @maxOccurs else 1"/>
            <xsl:variable name="type" select="$parts//(xs:simpleType|xs:complexType)[@name = $parts//xs:element[@name = current()/@ref]/@type]"/>
            <xsl:variable name="base" select="$type/(xs:complexContent|xs:simpleContent)/xs:extension/@base"/>
            <element id="{$path}.{$name}">
                <path value="{$path}.{$name}"/>
                <label value="{$name}"/>
                <!-- handle this:
                    <xsd:annotation>
                        <xsd:documentation xml:lang="en">Triage Code</xsd:documentation>
                -->
                <xsl:if test="$type/xs:annotation/xs:documentation[@xml:lang='en']">
                    <short value="{normalize-space($type/xs:annotation/xs:documentation[@xml:lang='en'])}"/>    
                </xsl:if>
                
                <min value="{$min}"/>
                <max value="{$max}"/>
                <base>
                    <path value="{$path}.{$name}"/>
                    <min value="{$min}"/>
                    <max value="{$max}"/>
                </base>
                <type>
                    <code value="http://hl7.org/fhir/v2/StructureDefinition/{if ($type/xs:simpleContent) then ($base) else ($name)}"/>
                </type>
                <!-- Get the maximum length of the string 
                <xsd:complexType name="HD.3.CONTENT">
                     ...
                    <xsd:simpleContent>
                        <xsd:extension base="ID">
                            <xsd:attributeGroup ref="HD.3.ATTRIBUTES"/>
                        </xsd:extension>
                    </xsd:simpleContent>
                </xsd:complexType>
                <xsd:attributeGroup name="HD.3.ATTRIBUTES">
                        ...
                    <xsd:attribute name="minLength" type="xsd:integer" fixed="1"/>
                        ...
                </xsd:attributeGroup>
                -->
                <xsl:variable name="atts" select="$parts//xs:attributeGroup[@name = $type/xs:simpleContent/xs:extension/xs:attributeGroup/@ref]"/>
                <xsl:if test="$atts/xs:attribute[@name='maxLength']">
                    <maxLength value="{$atts/xs:attribute[@name='maxLength']/@fixed}"/>
                </xsl:if>
                <mustSupport value="{if(string($min) &gt; '0') then ('true') else ('false')}"/>
                <!-- Handle binding to tables
                    <xsd:attributeGroup name="MSH.15.ATTRIBUTES">
                            ...
                        <xsd:attribute name="Table" type="xsd:string" fixed="HL70155"/>
                            ...
                    </xsd:attributeGroup>
                    -->
                <xsl:if test="$atts/xs:attribute[@name='Table']">
                    <xsl:variable name="tableNumber" select="substring-after($atts/xs:attribute[@name='Table']/@fixed,'HL7')"/>
                    <binding>
                        <strength value="extensible"/>
                        <valueSetReference>
                            <reference value="http://hl7.org/fhir/ValueSet/v2-{$tableNumber}"/>
                        </valueSetReference>
                    </binding>
                </xsl:if>
            </element>
            <xsl:apply-templates select="$type">
                <xsl:with-param name="path" select="concat($path,'.',$name)"/>
                <xsl:with-param name="depth" select="$depth + 1"/>
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
