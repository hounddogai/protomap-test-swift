import AcmePlatform
import Foundation

extension Staffing {
    static func primaryAcuityPlanSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func primaryAcuityPlanSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.83
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a primary acuity plan snapshot code in its canonical PAPS- form.
    static func normalizePrimaryAcuityPlanSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PAPS-") {
            return clean
        }
        return "PAPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
