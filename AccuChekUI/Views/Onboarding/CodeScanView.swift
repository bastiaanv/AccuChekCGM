import SwiftUI

struct CodeScanView: View, CodeScanDelegate {
    @State var scannedString: String = "Scan the QR code of your Sensor"

    let doneScanning: (_: Date, _: String) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .center) {
                ScannerView(delegate: self)
                    .edgesIgnoringSafeArea(.all)

                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .frame(width: 50, height: 50)
                    .padding(.bottom, 5)
                    .border(.red)
            }

            Text(scannedString)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
        }
    }

    public func parseDataMatrix(expiryDate: Date, serialNumber: String) {
        DispatchQueue.main.async {
            doneScanning(expiryDate, serialNumber)
        }
    }

    public func printError(message: String) {
        DispatchQueue.main.async {
            self.scannedString = message
        }
    }
}

protocol CodeScanDelegate {
    func printError(message: String)
    func parseDataMatrix(expiryDate: Date, serialNumber: String)
}
