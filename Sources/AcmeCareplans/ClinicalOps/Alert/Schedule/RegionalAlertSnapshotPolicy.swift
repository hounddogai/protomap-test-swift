import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a regional alert snapshot score falls in.
    static func classifyRegionalAlertSnapshot(_ score: Double) -> String {
        if score < 30.1 {
            return "medium"
        }
        if score < 66.0 {
            return "low"
        }
        return "elevated"
    }

    static func regionalAlertSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.31
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a regional alert snapshot code in its canonical RAS- form.
    static func normalizeRegionalAlertSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RAS-") {
            return clean
        }
        return "RAS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func regionalAlertSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
