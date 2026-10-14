import AcmePlatform
import Foundation

extension Imaging {
    static func seasonalPriorityMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.17
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func seasonalPriorityMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a seasonal priority metric code in its canonical SPM- form.
    static func normalizeSeasonalPriorityMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SPM-") {
            return clean
        }
        return "SPM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
