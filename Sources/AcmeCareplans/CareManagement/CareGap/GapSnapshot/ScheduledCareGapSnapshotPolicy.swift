import AcmePlatform
import Foundation

extension CareManagement {
    static func scheduledCareGapSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a scheduled care gap snapshot code in its canonical SCGS- form.
    static func normalizeScheduledCareGapSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCGS-") {
            return clean
        }
        return "SCGS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a scheduled care gap snapshot score falls in.
    static func classifyScheduledCareGapSnapshot(_ score: Double) -> String {
        if score < 8.4 {
            return "low"
        }
        if score < 36.6 {
            return "minimal"
        }
        return "high"
    }
}
