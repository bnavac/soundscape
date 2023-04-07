flowchart TD

%%App context
    a[AppContext] --> b[EstimatedLocationDetail]
    b <--> c[SpatialDataCache]
    b --> d[SpatialDataContext]
    b --> f[SpatialDataManager]

%%OSM

g[OSMServiceManager]
h[OSMServiceProtocol]
i{ServiceModel}
j[DebuggingSettingsContext]
k[Realm Database]
l[Kubernetes Pods]
i --> g
h -->g
j --> i
l <--> i

    A[Route Parameters] -->|has| B(RouteWayPoint Parameters)
    B --> C(Marker Parameters)
    C --> D(Location Parameters)
    D --> E(Coordinate Paramters)
    D --> E2(Entity Parameters)
    E--> F(Latitude/Longitude)


