import AcmePlatform
import Foundation

extension Pharmacy {
    static func legacyDispenseBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Puts a legacy dispense batch code in its canonical LDB- form.
    static func normalizeLegacyDispenseBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LDB-") {
            return clean
        }
        return "LDB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
