import SwiftUI
import VisionKit

struct BarcodeScannerView: UIViewControllerRepresentable {
    
    var didFindBarcode: (String) -> Void
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let viewController = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            isHighlightingEnabled: true
        )
        viewController.delegate = context.coordinator
        
        try? viewController.startScanning()
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // This is the crucial missing line that keeps the coordinator updated.
        context.coordinator.parent = self
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: BarcodeScannerView
        
        init(_ parent: BarcodeScannerView) {
            self.parent = parent
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            process(item: item, scanner: dataScanner)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard let item = addedItems.first else { return }
            process(item: item, scanner: dataScanner)
        }
        
        func process(item: RecognizedItem, scanner: DataScannerViewController) {
            
            var barcodePayload: String?
            
            switch item {
            case .barcode(let barcode):
                barcodePayload = barcode.observation.payloadStringValue
            case .text(let text):
                barcodePayload = text.transcript
            @unknown default:
                break
            }
            
            guard let payload = barcodePayload else { return }
            
            scanner.stopScanning()
            
            DispatchQueue.main.async {
                self.parent.didFindBarcode(payload)
            }
        }
    }
}
