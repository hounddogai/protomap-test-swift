import AcmePlatform
import Foundation

extension ClinicalOps {
    static func weightedOrderSetSummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func weightedOrderSetSummaryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.89
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a weighted order set summary code in its canonical WOSS- form.
    static func normalizeWeightedOrderSetSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WOSS-") {
            return clean
        }
        return "WOSS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
