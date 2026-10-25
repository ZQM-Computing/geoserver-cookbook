# GeoServer Cookbook

<!-- ZQM-START -->
<!-- markdownlint-disable MD033 -->
<p align="center">
  <strong>ZQM Computing — Geospatial Engineering & Scientific Computing</strong><br>
  <a href="https://github.com/ZQM-Computing">ZQM Computing</a>
</p>
<!-- markdownlint-enable MD033 -->
<!-- ZQM-END -->

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

A **GeoServer cookbook** for publishing, styling, federating, and securing OGC services with GeoServer and PostGIS. Patterns are drawn from the ZQM fleet’s running GeoServer installs (3.0.2 on Node-1, 2.28.6 on Node-3 and Node-4) and its verified federation paths. It is intended for GIS engineers and geospatial platform builders; validate each pattern against your own data, software versions, and operating environment before adopting it.

## Repository role and status

**Status:** Active, public — seeding. Pattern passes land in follow-up work from fleet-verified setups; the tables below list what is planned, not what is already written.

**What this repository is:** GeoServer patterns — publishing PostGIS layers, SLD styling, workspace/datastore setup, OGC service configuration, and multi-node federation.

**What it contributes:** Part of the ZQM Computing geospatial portfolio. The umbrella index for the series is [geospatial-cookbooks](https://github.com/ZQM-Computing/geospatial-cookbooks).

**Standing:** This repository is maintained independently. Automated checks cover only the paths and environments configured in its workflows; they do not establish production readiness or operational certification.

## Who this is for

Geospatial developers and platform engineers who publish vector and raster data as WMS, WFS, and WMTS services, and who run more than one GeoServer that must share layers.

## Prerequisites

- GeoServer 3.0.2 (or 2.28.x — note version-specific behavior where it differs)
- PostGIS-backed Postgres (see [postgis-cookbook](https://github.com/ZQM-Computing/postgis-cookbook))
- Java 21 runtime for GeoServer 3.x
- Bash

## Patterns (planned)

| # | Example | What it will demonstrate |
|---|---------|--------------------------|
| 01 | `01-publish-postgis` | Publishing a PostGIS table as WMS/WFS layers, workspace and datastore setup |
| 02 | `02-sld-styling` | SLD styles for points, lines, and polygons, with scale-dependent rules |
| 03 | `03-federation-virtual-service` | Virtual-service federation: one node serving another node’s layers (verified Node-1 ← Node-3) |
| 04 | `04-federation-layer-group` | Layer-group federation path, byte-identical against the virtual-service path |
| 05 | `05-importer-extension` | GeoServer Importer extension workflows for bulk ingest |
| 06 | `06-wps-extension` | GeoServer WPS extension setup and a first process |
| 07 | `07-security-basics` | Admin credential handling, service-level access rules, and what to leave locked down |

## Repository layout

```text
geoserver-cookbook/
├── examples/          # pattern passes, landing in follow-up work
├── README.md
└── LICENSE
```

## Roadmap

- First pattern pass: publishing + styling (01, 02)
- Second pass: federation (03, 04) with the fleet’s verified configurations
- Security pass (07) once the fleet’s GeoServer admin handling is settled

## Contributing

A contributing guide lands with the first pattern pass. Report security issues to <zqmcomputing@gmail.com> — please do not open a public issue for those.

## More from this series

- [postgis-cookbook](https://github.com/ZQM-Computing/postgis-cookbook) — PostGIS SQL examples: spatial indexing, joins & KNN, SRID management, vector tiles, data quality, partitioning
- [stac-cookbook](https://github.com/ZQM-Computing/stac-cookbook) — STAC catalog creation, item validation, search API, bulk ops
- [cog-cookbook](https://github.com/ZQM-Computing/cog-cookbook) — Cloud Optimized GeoTIFF creation, validation, TiTiler serving, xarray integration
