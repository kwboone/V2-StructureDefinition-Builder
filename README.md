# V2-StructureDefinition-Builder
This is an XSLT Transform that will convert HL7 V2 Schema files into FHIR DSTU 2 StructureDefinition resources.

To run this, it needs to live in the same folder as your schema, and you need to pass in the name of the message you want to convert as a parameter.

java -classpath {classpath for Saxon jar}  net.sf.saxon.Transform -xsl:toStructureDefinition.xsl -it:start message=ORU_R01

The output will be a FHIR DSTU2 StructureDefinition resource.
