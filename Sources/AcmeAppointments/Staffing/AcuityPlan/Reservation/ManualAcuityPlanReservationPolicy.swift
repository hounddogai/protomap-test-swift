import AcmePlatform
import Foundation

extension Staffing {
    static func manualAcuityPlanReservationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.58
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeManualAcuityPlanReservationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a manual acuity plan reservation score falls in.
    static func classifyManualAcuityPlanReservation(_ score: Double) -> String {
        if score < 19.1 {
            return "medium"
        }
        if score < 74.5 {
            return "critical"
        }
        if score < 76.4 {
            return "high"
        }
        return "ok"
    }

    static func manualAcuityPlanReservationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
