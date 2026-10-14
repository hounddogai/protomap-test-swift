import AcmePlatform
import Foundation

extension Pharmacy {
    static func rollingDispenseAgreementSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Puts a rolling dispense agreement code in its canonical RDA- form.
    static func normalizeRollingDispenseAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RDA-") {
            return clean
        }
        return "RDA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
