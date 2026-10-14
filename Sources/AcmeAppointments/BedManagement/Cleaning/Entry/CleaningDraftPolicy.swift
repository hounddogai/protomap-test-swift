import AcmePlatform
import Foundation

extension BedManagement {
    static func cleaningDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func cleaningDraftWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.59
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a cleaning draft score falls in.
    static func classifyCleaningDraft(_ score: Double) -> String {
        if score < 19.8 {
            return "medium"
        }
        if score < 38.0 {
            return "critical"
        }
        return "ok"
    }
}
