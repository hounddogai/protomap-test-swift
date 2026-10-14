import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a regional outreach checkpoint code in its canonical ROC- form.
    static func normalizeRegionalOutreachCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ROC-") {
            return clean
        }
        return "ROC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func regionalOutreachCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.36
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func regionalOutreachCheckpointBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
