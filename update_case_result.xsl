<?xml version="1.0" encoding="UTF-8"?>
<!-- 
SPDX-FileCopyrightText: Tumelo Dlodlo (https://www.linkedin.com/in/tumelo-dlodlo/)
SPDX-License-Identifier: GPL-3.0-or-later 
-->
<xsl:stylesheet	version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:strip-space elements="*"/>

	
	<xsl:template match="//table//tr" select=".">
		<xsl:param name="case_id" select=""/>
		<xsl:param name="case_result" select=""/>
		<xsl:param name="case_tester" select=""/>

		<!--  get column id where the case result will be updated  -->
		<xsl:variable name="column_id">
			<xsl:if test="$case_id != ''">
				<xsl:for-each select="//table//tr[td[1]='case id']//td">
					<xsl:if test=". = $case_id">
						<xsl:value-of select="position()"/>
					</xsl:if>
				</xsl:for-each>
			</xsl:if>
		</xsl:variable>
		
		<!-- set case result or case tester rows -->
		<xsl:choose>
			
			<!-- if the column_id is set 
				then update the case result in that column -->
			<xsl:when test=".//td[1] = 'result'">
				<tr>
					<xsl:for-each select=".//td">
						<td>
							<xsl:copy-of select="./@*" />
							<xsl:choose>
								<xsl:when test="$column_id != '' and position() = $column_id">
									<xsl:value-of select="$case_result"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="."/>
								</xsl:otherwise>
							</xsl:choose>
						</td>
					</xsl:for-each>
				</tr>
			</xsl:when>

			<!-- if the column_id is set 
				then update the case tester in that column -->
			<xsl:when test=".//td[1] = 'tester'">
				<tr>
					<xsl:for-each select=".//td">
						<td>
							<xsl:copy-of select="./@*" />
							<xsl:choose>
								<xsl:when test="$column_id != '' and position() = $column_id">
									<xsl:value-of select="$case_tester"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="."/>
								</xsl:otherwise>
							</xsl:choose>
						</td>
					</xsl:for-each>
				</tr>
			</xsl:when>
	
			<!-- keep other rows as original -->
			<xsl:otherwise>
				<xsl:copy>
					<xsl:apply-templates select="@*|node()"/>
				</xsl:copy>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!--  identity template  -->
	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>


