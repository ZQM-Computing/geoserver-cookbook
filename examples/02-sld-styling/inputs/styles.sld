<?xml version="1.0" encoding="UTF-8"?>
<!-- 02-sld-styling input: real SLD with point, line, and polygon styles
     plus scale-dependent rules. Synthetic attribute names only.
     NOTE (design-only): GeoServer registers each NamedLayer below as
     its own style on upload; verify the registered names on first run
     and record any version-driven difference rather than editing
     silently. -->
<StyledLayerDescriptor version="1.0.0"
    xmlns="http://www.opengis.net/sld"
    xmlns:ogc="http://www.opengis.net/ogc"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.0.0/StyledLayerDescriptor.xsd">
  <!-- Point style: small markers at small scales, larger + labelled at large scales -->
  <NamedLayer>
    <Name>synthetic_points</Name>
    <UserStyle>
      <Title>Synthetic points</Title>
      <FeatureTypeStyle>
        <Rule>
          <Name>small-scale</Name>
          <MaxScaleDenominator>50000</MaxScaleDenominator>
          <PointSymbolizer>
            <Graphic>
              <Mark><WellKnownName>circle</WellKnownName>
                <Fill><CssParameter name="fill">#1f77b4</CssParameter></Fill>
              </Mark>
              <Size>6</Size>
            </Graphic>
          </PointSymbolizer>
        </Rule>
        <Rule>
          <Name>large-scale</Name>
          <MinScaleDenominator>50000</MinScaleDenominator>
          <PointSymbolizer>
            <Graphic>
              <Mark><WellKnownName>circle</WellKnownName>
                <Fill><CssParameter name="fill">#d62728</CssParameter></Fill>
              </Mark>
              <Size>12</Size>
            </Graphic>
          </PointSymbolizer>
          <TextSymbolizer>
            <Label><ogc:PropertyName>name</ogc:PropertyName></Label>
            <Font><CssParameter name="font-size">11</CssParameter></Font>
          </TextSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
  <!-- Line style: thin at small scales, thicker at large scales -->
  <NamedLayer>
    <Name>synthetic_lines</Name>
    <UserStyle>
      <Title>Synthetic lines</Title>
      <FeatureTypeStyle>
        <Rule>
          <Name>small-scale</Name>
          <MaxScaleDenominator>25000</MaxScaleDenominator>
          <LineSymbolizer>
            <Stroke><CssParameter name="stroke">#2ca02c</CssParameter>
              <CssParameter name="stroke-width">1</CssParameter></Stroke>
          </LineSymbolizer>
        </Rule>
        <Rule>
          <Name>large-scale</Name>
          <MinScaleDenominator>25000</MinScaleDenominator>
          <LineSymbolizer>
            <Stroke><CssParameter name="stroke">#2ca02c</CssParameter>
              <CssParameter name="stroke-width">3</CssParameter></Stroke>
          </LineSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
  <!-- Polygon style: outline dropped at very small scales -->
  <NamedLayer>
    <Name>synthetic_polygons</Name>
    <UserStyle>
      <Title>Synthetic polygons</Title>
      <FeatureTypeStyle>
        <Rule>
          <Name>small-scale</Name>
          <MaxScaleDenominator>100000</MaxScaleDenominator>
          <PolygonSymbolizer>
            <Fill><CssParameter name="fill">#ff7f0e</CssParameter>
              <CssParameter name="fill-opacity">0.5</CssParameter></Fill>
          </PolygonSymbolizer>
        </Rule>
        <Rule>
          <Name>large-scale</Name>
          <MinScaleDenominator>100000</MinScaleDenominator>
          <PolygonSymbolizer>
            <Fill><CssParameter name="fill">#ff7f0e</CssParameter>
              <CssParameter name="fill-opacity">0.5</CssParameter></Fill>
            <Stroke><CssParameter name="stroke">#7f3f00</CssParameter>
              <CssParameter name="stroke-width">1.5</CssParameter></Stroke>
          </PolygonSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
