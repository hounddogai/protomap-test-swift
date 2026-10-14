import AcmePlatform
import Foundation

extension ClinicalOps {
    static func seasonalOrderSetReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.84
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func seasonalOrderSetReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a seasonal order set review code in its canonical SOSR- form.
    static func normalizeSeasonalOrderSetReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SOSR-") {
            return clean
        }
        return "SOSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
