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
