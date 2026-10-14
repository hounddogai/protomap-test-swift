import AcmePlatform
import Foundation

extension Imaging {
    static func manualModalitySummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func manualModalitySummaryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.48
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a manual modality summary code in its canonical MMS- form.
    static func normalizeManualModalitySummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MMS-") {
            return clean
        }
        return "MMS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
