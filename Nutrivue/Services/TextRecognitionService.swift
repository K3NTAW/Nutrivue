import Foundation
import Vision
import UIKit

class TextRecognitionService {
    func recognizeText(from images: [UIImage], completion: @escaping (String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var combined = ""
            for image in images {
                guard let cg = self.makeCGImage(from: image) else { continue }
                let request = VNRecognizeTextRequest { request, _ in
                    for observation in request.results as? [VNRecognizedTextObservation] ?? [] {
                        if let top = observation.topCandidates(1).first {
                            combined.append(top.string)
                            combined.append("\n")
                        }
                    }
                }
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                let handler = VNImageRequestHandler(cgImage: cg, options: [:])
                try? handler.perform([request])
            }
            DispatchQueue.main.async { completion(combined) }
        }
    }
    
    private func makeCGImage(from image: UIImage) -> CGImage? {
        if let cg = image.cgImage { return cg }
        if let ci = image.ciImage {
            let context = CIContext(options: nil)
            return context.createCGImage(ci, from: ci.extent)
        }
        let size = image.size
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let rendered = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        return rendered.cgImage
    }
}


