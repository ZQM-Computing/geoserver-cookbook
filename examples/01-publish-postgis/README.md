# Publish a PostGIS table through the GeoServer REST API

This pattern creates a missing GeoServer workspace, PostGIS datastore, and feature type. It uses synthetic or explicitly approved data supplied by the operator; it does not create the database table or modify source data.

## Requirements

- Python 3.11+ (standard library only)
- A reachable GeoServer instance with REST API access
- A PostGIS database reachable from the GeoServer server, not merely from the machine running this script
- A database user limited to the schema and tables that should be published
- A GeoServer account with permission to create workspaces, stores, and layers

## Configure

Set these environment variables in your shell or secret manager. Do not commit credentials to the repository.

| Variable | Required | Meaning |
|---|---|---|
| `GEOSERVER_URL` | Yes | Base URL, e.g. `http://localhost:8080/geoserver` |
| `GEOSERVER_USER` / `GEOSERVER_PASSWORD` | Yes | REST API credentials |
| `GEOSERVER_WORKSPACE` | Yes | Workspace to create or reuse |
| `GEOSERVER_STORE` | Yes | PostGIS datastore to create or reuse |
| `POSTGIS_HOST` | Yes | Host as resolved from the GeoServer host/container |
| `POSTGIS_DATABASE` | Yes | Database name |
| `POSTGIS_USER` / `POSTGIS_PASSWORD` | Yes | Least-privilege database credentials |
| `POSTGIS_TABLE` | Yes | Existing table name to publish |
| `POSTGIS_PORT` | No | Defaults to `5432` |
| `POSTGIS_SCHEMA` | No | Defaults to `public` |
| `POSTGIS_NATIVE_CRS` | No | Defaults to `EPSG:4326`; set to the table's actual CRS |

Run from the repository root:

```bash
python examples/01-publish-postgis/publish.py
```

The script only issues GET and POST requests. It creates resources only when the REST API reports them missing; it does not delete, overwrite, or update existing resources. A concurrent creation race or a non-404 API error fails rather than silently changing existing configuration. Re-running against an already-created resource reports it as existing.

## Validation and limitations

The automated tests validate XML escaping, connection-parameter serialization, explicit CRS configuration, and required-setting guards. They do **not** establish that a real GeoServer/PostGIS deployment accepts the configuration or that the published layer is correctly secured.

After running, verify the layer's native CRS, extent, attributes, intended service endpoints, and access rules in your own environment. Avoid publishing sensitive tables. The publisher requires HTTPS for non-loopback GeoServer endpoints; plain HTTP is accepted only for localhost/loopback development and the disposable CI service. Keep REST credentials out of URLs, query strings, fragments, logs, and shell history. This client-side check does not configure server TLS or validate certificates beyond the Python HTTPS stack.
