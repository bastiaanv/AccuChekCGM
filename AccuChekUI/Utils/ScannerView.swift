import AVFoundation
import SwiftUI
import Vision

struct ScannerView: UIViewControllerRepresentable {
    var delegate: CodeScanDelegate
    let captureSession = AVCaptureSession()

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()

        guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession.canAddInput(videoInput)
        else {
            return viewController
        }

        captureSession.addInput(videoInput)

        let videoOutput = AVCaptureVideoDataOutput()

        if captureSession.canAddOutput(videoOutput) {
            videoOutput.setSampleBufferDelegate(context.coordinator, queue: DispatchQueue(label: "videoQueue"))
            captureSession.addOutput(videoOutput)
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = viewController.view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(previewLayer)

        DispatchQueue.main.async {
            captureSession.startRunning()
        }

        return viewController
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: ScannerView
        private let logger = AccuChekLogger(category: "CodeScanner")
        private var requests = [VNRequest]()

        private let dataFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyMMdd"
            return formatter
        }()

        init(_ parent: ScannerView) {
            self.parent = parent
            super.init()

            let barcodeRequest = VNDetectBarcodesRequest(completionHandler: handleBarcodes)
            barcodeRequest.symbologies = [.dataMatrix]
            requests = [barcodeRequest]
        }

        func captureOutput(_: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from _: AVCaptureConnection) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            do {
                try imageRequestHandler.perform(requests)
            } catch {
                print("Failed to perform barcode detection: \(error)")
            }
        }

        private func handleBarcodes(request: VNRequest, error: Error?) {
            if let error = error {
                print("Barcode detection error: \(error)")
                return
            }

            guard let results = request.results as? [VNBarcodeObservation] else {
                print("empty results")
                return
            }
            for barcode in results {
                if let payload = barcode.payloadStringValue {
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                    handleCode(payload)
                }
            }
        }

        private func handleCode(_ value: String) {
            logger.info("Got data: \(value)")
            let data = GS1Parser.parse(value)
            guard let expiry = data.first(where: { $0.ai == "17" }),
                  let serialNumber = data.first(where: { $0.ai == "21" })
            else {
                parent.delegate.printError(message: "Incorrect data matrix scanned. Try another one please")
                logger.error("Failed to get expiry date: \(data.map { $0.ai + "-" + $0.value }.joined(separator: ","))")
                return
            }

            // Format: YYMMDD
            guard let date = dataFormatter.date(from: expiry.value) else {
                parent.delegate.printError(message: "Failed to parse date")
                logger.error("Failed to parse date")
                return
            }

            logger.info("Scan completed! expiry: \(date), serial: \(serialNumber.value)")
            parent.delegate.parseDataMatrix(expiryDate: date, serialNumber: serialNumber.value)
            parent.captureSession.stopRunning()
        }
    }
}
