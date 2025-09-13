import SwiftUI
import PhotosUI
import MapKit
import Photos
import UIKit
import ImageIO

struct TaskDetailView: View {
    @Binding var task: HuntTask
    @State private var showCamera = false
    @State private var selectedItem: PhotosPickerItem?
    
    // iOS 16 map state
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    @StateObject private var locationMgr = LocationManager()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: task.isCompleted ? "checkmark.seal.fill" : "seal")
                        .foregroundStyle(task.isCompleted ? .green : .secondary)
                    Text(task.title).font(.title.bold())
                    Spacer()
                }
                
                Text(task.details).foregroundStyle(.secondary)
                
                if let data = task.imageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.quaternary, lineWidth: 1))
                } else {
                    // iOS 16 fallback for ContentUnavailableView
                    placeholderCard(
                        title: "No photo yet",
                        systemImage: "photo",
                        message: "Attach a photo from your library or camera."
                    )
                }
                
                // Map (iOS 16 way)
                if let coord = task.coordinate {
                    Map(coordinateRegion: $region, annotationItems: [coord]) { c in
                        MapAnnotation(coordinate: c) {
                            ZStack {
                                Circle().fill(Color.blue.opacity(0.9)).frame(width: 26, height: 26)
                                Image(systemName: "camera.fill").foregroundColor(.white)
                            }
                        }
                    }
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .onAppear {
                        region = MKCoordinateRegion(
                            center: coord,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    }
                } else {
                    placeholderCard(
                        title: "No location metadata",
                        systemImage: "mappin.and.ellipse",
                        message: "Pick a photo that has location data, or use the camera to tag your current location."
                    )
                }
                
                VStack(spacing: 12) {
                    PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                        Label("Attach from Photo Library", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .onChange(of: selectedItem) { newValue in
                        if let item = newValue { handlePickerItem(item) }
                    }
                    
                    Button {
                        showCamera = true
                    } label: {
                        Label("Open Camera (Stretch)", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showCamera) {
            CameraView { image in
                guard let data = image.jpegData(compressionQuality: 0.9) else { return }
                task.imageData = data
                if let loc = locationMgr.location?.coordinate {
                    task.latitude = loc.latitude
                    task.longitude = loc.longitude
                }
                task.isCompleted = true
            }
            .ignoresSafeArea()
        }
        .task { await locationMgr.request() }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // keep region reasonable if we already have a coordinate
            if let coord = task.coordinate {
                region.center = coord
            }
        }
    }
    
    // Simple iOS 16 “ContentUnavailableView” substitute
    @ViewBuilder
    private func placeholderCard(title: String, systemImage: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func extractGPS(from data: Data) -> CLLocationCoordinate2D? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any],
              let gps = props[kCGImagePropertyGPSDictionary] as? [CFString: Any],
              let lat = gps[kCGImagePropertyGPSLatitude] as? Double,
              let lon = gps[kCGImagePropertyGPSLongitude] as? Double
        else { return nil }
        
        var latitude = lat
        var longitude = lon
        if let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String, latRef.uppercased() == "S" { latitude = -latitude }
        if let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String, lonRef.uppercased() == "W" { longitude = -longitude }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // MARK: - PHPicker Handling (with EXIF GPS via PHAsset)
    private func handlePickerItem(_ item: PhotosPickerItem) {
        Task {
            var pickedData: Data?
            var pickedCoord: CLLocationCoordinate2D?
            
            // Load image bytes
            if let data = try? await item.loadTransferable(type: Data.self) {
                pickedData = data
                // Try EXIF GPS
                pickedCoord = extractGPS(from: data)
            }
            
            // Apply on main actor
            await MainActor.run {
                if let d = pickedData { task.imageData = d }
                
                if let c = pickedCoord {
                    task.latitude = c.latitude
                    task.longitude = c.longitude
                    region = MKCoordinateRegion(center: c,
                                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                } else if let loc = locationMgr.location?.coordinate {
                    // fallback: tag with current location if photo has no GPS
                    task.latitude = loc.latitude
                    task.longitude = loc.longitude
                    region = MKCoordinateRegion(center: loc,
                                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                }
                
                if task.imageData != nil { task.isCompleted = true }
            }
        }
    }
}
extension CLLocationCoordinate2D: Identifiable {
    public var id: String { "\(latitude),\(longitude)" }
}
