import ASN1
import Foundation

extension ASN1Time {
    func toDate() -> Date? {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMddHHmmss" + (df.timeZone.secondsFromGMT() == 0 ? "'Z'" : "ZZZ")
        
        guard let date = String(bytes: self.value, encoding: .utf8) else {
            return nil
        }
        
        return df.date(from: date)
    }
}
