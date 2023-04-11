-%% ------
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
    p[The PostGIS Database]
    v[Linux Machine]
    i --> g
    h -->g
    j --> i
    l <--> i
    subgraph .
    p --> v
    end
l --> p

%% ------

    A[Route Parameters] -->|has| B(RouteWayPoint Parameters)
    B --> C(Marker Parameters)
    C --> D(Location Parameters)
    D --> E(Coordinate Paramters)
    D --> E2(Entity Parameters)
    E--> F(Latitude/Longitude)


flowchart TD
    %%View life cycle
    Appearing --- |viewDidAppear|Appeared  --- |viewWillDisappear|Disappearing
    Disappearing --> |viewWillAppear|Appearing
    Appearing --> |viewWillDisappear|Disappearing
    Appearing ---|viewWillAppear| Disappeared  ---|viewDidDisappear| Disappearing


%%MapView Delegate
classDiagram
    WaypointDetail<|-- LocationDetail
    MKMapViewDelegate <|-- WaypointDetail
    MKMapViewDelegate <|-- RouteDetail
    MKMapViewDelegate <|-- TourDetail
    RouteDetail <|-- LocationDetail
    TourDetail <|-- LocationDetail

   
    
    class MKMapViewDelegate{
        +mapView()
    }

    class RouteDetail{
        +String id
        +String name
        +String Description
        +LocationDetail waypoints
        +guidance()
        +setRouteProperties()
    }

    class TourDetail{
        
        +String name
        +String Description
        +LocationDetail waypoints
        +LocationDetail pois
        +Listeners
        +guidance()
        +setRouteProperties()
    }

    class LocationDetail{
        + CLLocation
        + Address
        + Annotation


        +displayAddress()
        +displayAnnotation()

    }
    class WaypointDetail{
      +isActive()
      +String DisplayName
    }
