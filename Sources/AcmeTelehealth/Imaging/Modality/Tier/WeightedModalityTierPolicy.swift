import AcmePlatform
import Foundation

extension Imaging {
    static func weightedModalityTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    static func weightedModalityTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a weighted modality tier code in its canonical WMT- form.
    static func normalizeWeightedModalityTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WMT-") {
            return clean
        }
        return "WMT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
