//
//  MapView.swift
//  SwiftUIMapView
//
//  Created by Sören Gade on 14.01.20.
//  Copyright © 2020 Sören Gade. All rights reserved.
//
import SwiftUI
import MapKit
import Combine
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/**
 Displays a map. The contents of the map are provided by the Apple Maps service.
 
 See the [official documentation](https://developer.apple.com/documentation/mapkit/mkmapview) for more information on the possibilities provided by the underlying service.
 
 - Author: Sören Gade
 - Copyright: 2020—2022 Sören Gade
 */
@available(iOS, introduced: 13.0)
public struct MapView {
    
    // MARK: Properties
    /**
     The map type that is displayed.
     */
    var mapType: MKMapType = .standard
    
    /**
     The region that is displayed.
     
    Note: The region might not be used as-is, as it might need to be fitted to the view's bounds. See [regionThatFits(_:)](https://developer.apple.com/documentation/mapkit/mkmapview/1452371-regionthatfits).
     */
    @Binding var region: MKCoordinateRegion?

    /**
     Determines whether the map can be zoomed.
    */
    let isZoomEnabled: Bool

    /**
     Determines whether the map can be scrolled.
    */
    let isScrollEnabled: Bool
    
    /**
     Determines whether the current user location is displayed.
     
     This requires the `NSLocationWhenInUseUsageDescription` key in the Info.plist to be set. In addition, you need to call [`CLLocationManager.requestWhenInUseAuthorization()`](https://developer.apple.com/documentation/corelocation/cllocationmanager/1620562-requestwheninuseauthorization) to request for permission.
     */
    let showsUserLocation: Bool
    
    /**
     Sets the map's user tracking mode.
     */
    let userTrackingMode: MKUserTrackingMode
    
    /**
     Annotations that are displayed on the map.
     
     See the `selectedAnnotation` binding for more information about user selection of annotations.
     
     - SeeAlso: selectedAnnotation
     */
  var annotations: [MKAnnotation] = []
  
  var overlays: [MKOverlay] = []
    
    /**
     The currently selected annotations.
     
     When the user selects annotations on the map the value of this binding changes.
     Likewise, setting the value of this binding to a value selects the given annotations.
     */
    @Binding var selectedAnnotations: [MKAnnotation]

    // MARK: Initializer
    /**
     Creates a new MapView.
     
     - Parameters:
        - region: The region to display.
        - showsUserLocation: Whether to display the user's current location.
        - userTrackingMode: The user tracking mode.
        - annotations: A list of `MapAnnotation`s that should be displayed on the map.
        - selectedAnnotation: A binding to the currently selected annotation, or `nil`.
     */
    public init(region: Binding<MKCoordinateRegion?> = .constant(nil),
                isZoomEnabled: Bool = true,
                isScrollEnabled: Bool = true,
                showsUserLocation: Bool = true,
                userTrackingMode: MKUserTrackingMode = .none,
                selectedAnnotations: Binding<[MKAnnotation]> = .constant([])) {
        self._region = region
        self.isZoomEnabled = isZoomEnabled
        self.isScrollEnabled = isScrollEnabled
        self.showsUserLocation = showsUserLocation
        self.userTrackingMode = userTrackingMode
        self._selectedAnnotations = selectedAnnotations
    }

    // MARK: - UIViewRepresentable
    public func makeCoordinator() -> MapView.Coordinator {
        return Coordinator(for: self)
    }
    
    public func mapType(_ mapType: MKMapType) -> MapView {
        var mapView = self
        mapView.mapType = mapType
        return mapView
    }
  
  public func overlays(_ overlays: [MKOverlay]) -> MapView {
    var mapView = self
    mapView.overlays = overlays
    return mapView
  }
  
  public func annotations(_ annotations: [MKAnnotation]) -> MapView {
    var mapView = self
    mapView.annotations = annotations
    return mapView
  }
    
    /**
     Updates the annotation property of the `mapView`.
     Calculates the difference between the current and new states and only executes changes on those diff sets.
     
     - Parameter mapView: The `MKMapView` to configure.
     */
    private func updateAnnotations(in mapView: MKMapView) {
        let currentAnnotations = mapView.mapViewAnnotations
        // remove old annotations
        let obsoleteAnnotations = currentAnnotations.filter { mapAnnotation in
            !self.annotations.contains { $0.isEqual(mapAnnotation) }
        }
        mapView.removeAnnotations(obsoleteAnnotations)
        
        // add new annotations
        let newAnnotations = self.annotations.filter { mapViewAnnotation in
            !currentAnnotations.contains { $0.isEqual(mapViewAnnotation) }
        }
        mapView.addAnnotations(newAnnotations)
    }
    
    /**
     Updates the selection annotations of the `mapView`.
     Calculates the difference between the current and new selection states and only executes changes on those diff sets.
     
     - Parameter mapView: The `MKMapView` to configure.
     */
    private func updateSelectedAnnotation(in mapView: MKMapView) {
        // deselect annotations that are not currently selected
        let oldSelections = mapView.selectedMapViewAnnotations.filter { oldSelection in
            !self.selectedAnnotations.contains {
                oldSelection.isEqual($0)
            }
        }
        for annotation in oldSelections {
            mapView.deselectAnnotation(annotation, animated: false)
        }
        
        // select all new annotations
        let newSelections = self.selectedAnnotations.filter { selection in
            !mapView.selectedMapViewAnnotations.contains {
                selection.isEqual($0)
            }
        }
        for annotation in newSelections {
            mapView.selectAnnotation(annotation, animated: true)
        }
    }
    
    // MARK: - Interaction and delegate implementation
    public class Coordinator: NSObject, MKMapViewDelegate {
        
        /**
         Reference to the SwiftUI `MapView`.
        */
        private let context: MapView
        
        init(for context: MapView) {
            self.context = context
            super.init()
        }
      
      public func mapView(
        _ mapView: MKMapView,
        rendererFor overlay: MKOverlay
      ) -> MKOverlayRenderer {
        if overlay is MKCircle {
          let renderer = MKCircleRenderer(overlay: overlay)
          renderer.fillColor = .blue.withAlphaComponent(0.5)
          renderer.strokeColor = .blue
          renderer.lineWidth = 1
          return renderer
        } else if overlay is MKPolyline {
          let renderer = MKPolylineRenderer(overlay: overlay)
          renderer.lineJoin = .round
          renderer.fillColor = .systemBlue
          renderer.strokeColor = .systemBlue
          renderer.lineWidth = 4
          return renderer
        }
        
        return MKOverlayRenderer()
      }
        
        // MARK: MKMapViewDelegate
        public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let mapAnnotation = view.annotation as? MapViewAnnotation else {
                return
            }
            
            DispatchQueue.main.async {
                self.context.selectedAnnotations.append(mapAnnotation)
            }
        }
        
        public func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            guard let mapAnnotation = view.annotation as? MapViewAnnotation else {
                return
            }
            
            guard let index = self.context.selectedAnnotations.firstIndex(where: { $0.isEqual(mapAnnotation) }) else {
                return
            }
            
            DispatchQueue.main.async {
                self.context.selectedAnnotations.remove(at: index)
            }
        }
        
        public func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            DispatchQueue.main.async {
                self.context.region = mapView.region
            }
        }
        
    }
}

#if os(iOS)
extension MapView: UIViewRepresentable {
  public func makeUIView(context: UIViewRepresentableContext<MapView>) -> MKMapView {
    // create view
    let mapView = MKMapView()
    mapView.delegate = context.coordinator
    // register custom annotation view classes
    mapView.register(MapAnnotationView.self,
                     forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
//    mapView.register(MapAnnotationClusterView.self,
//                     forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
    
    // configure initial view state
    self.configureView(mapView, context: context)
    
    return mapView
  }
  
  public func updateUIView(_ mapView: MKMapView, context: UIViewRepresentableContext<MapView>) {
    // configure view update
    self.configureView(mapView, context: context)
  }
  
  // MARK: - Configuring view state
  /**
   Configures the `mapView`'s state according to the current view state.
   */
  private func configureView(_ mapView: MKMapView, context: UIViewRepresentableContext<MapView>) {
    // basic map configuration
    mapView.mapType = self.mapType
    if let mapRegion = self.region {
      let region = mapView.regionThatFits(mapRegion)
      
      if region.center != mapView.region.center || region.span != mapView.region.span {
        mapView.setRegion(region, animated: true)
      }
    }
    mapView.isZoomEnabled = self.isZoomEnabled
    mapView.isScrollEnabled = self.isScrollEnabled
    mapView.showsUserLocation = self.showsUserLocation
    mapView.userTrackingMode = self.userTrackingMode
    
    // annotation configuration
    self.updateAnnotations(in: mapView)
    self.updateSelectedAnnotation(in: mapView)
    
    mapView.addOverlays(self.overlays)
  }
}
#elseif os(macOS)
extension MapView: NSViewRepresentable {
  public func makeNSView(context: NSViewRepresentableContext<MapView>) -> MKMapView {
    // create view
    let mapView = MKMapView()
    mapView.delegate = context.coordinator
    // register custom annotation view classes
    mapView.register(MapAnnotationView.self,
                     forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
//    mapView.register(MapAnnotationClusterView.self,
//                     forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
    
    // configure initial view state
    self.configureView(mapView, context: context)
    
    return mapView
  }
  
  public func updateNSView(_ mapView: MKMapView, context: NSViewRepresentableContext<MapView>) {
    // configure view update
    self.configureView(mapView, context: context)
  }
  
  // MARK: - Configuring view state
  /**
   Configures the `mapView`'s state according to the current view state.
   */
  private func configureView(_ mapView: MKMapView, context: NSViewRepresentableContext<MapView>) {
    // basic map configuration
    mapView.mapType = self.mapType
    if let mapRegion = self.region {
      let region = mapView.regionThatFits(mapRegion)
      
      if region.center != mapView.region.center || region.span != mapView.region.span {
        mapView.setRegion(region, animated: true)
      }
    }
    mapView.isZoomEnabled = self.isZoomEnabled
    mapView.isScrollEnabled = self.isScrollEnabled
    mapView.showsUserLocation = self.showsUserLocation
    mapView.userTrackingMode = self.userTrackingMode
    
    // annotation configuration
    self.updateAnnotations(in: mapView)
    self.updateSelectedAnnotation(in: mapView)
    
    mapView.addOverlays(self.overlays)
  }
}
#endif



// MARK: - Previews

#if DEBUG
struct MapView_Previews: PreviewProvider {

    static var previews: some View {
        MapView()
          .mapType(.satellite)
    }

}
#endif
