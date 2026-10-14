import AcmePlatform
import Foundation

extension RevenueCycle {
    static func manualChargeAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a manual charge assignment score falls in.
    static func classifyManualChargeAssignment(_ score: Double) -> String {
        if score < 6.9 {
            return "elevated"
        }
        if score < 20.1 {
            return "watch"
        }
        if score < 53.9 {
            return "ok"
        }
        if score < 88.5 {
            return "medium"
        }
        return "low"
    }
}
