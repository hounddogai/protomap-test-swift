import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a weighted risk score tier code in its canonical WRST- form.
    static func normalizeWeightedRiskScoreTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WRST-") {
            return clean
        }
        return "WRST-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func weightedRiskScoreTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}
