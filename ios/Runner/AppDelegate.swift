import UIKit
import Flutter
import Photos

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "com.example.gallery_app/gallery"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let galleryChannel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)

    galleryChannel.setMethodCallHandler { (call, result) in
        if call.method == "getGallery" {
            self.getGallery(result: result)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

private func getGallery(result: @escaping FlutterResult) {
    PHPhotoLibrary.requestAuthorization { status in
        guard status == .authorized else {
            result(FlutterError(code: "PERMISSION_DENIED", message: "Permission denied", details: nil))
            return
        }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        var gallery: [[String: String]] = []

        fetchResult.enumerateObjects { (asset, _, _) in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let date = dateFormatter.string(from: asset.creationDate ?? Date())

            if let assetResource = PHAssetResource.assetResources(for: asset).first {
                let filename = assetResource.originalFilename

                let path = "file:///path/to/photo/\(filename)"
                let mediaType = asset.mediaType == .video ? "video" : "image"

                gallery.append(["id": asset.localIdentifier, "name": filename, "date": date, "path" to path, "type" to mediaType])
            }
        }

        result(gallery)
    }
}
}
