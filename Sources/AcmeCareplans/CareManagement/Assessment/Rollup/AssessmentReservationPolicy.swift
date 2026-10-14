import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAssessmentReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("assessment-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func assessmentReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a assessment reservation score falls in.
    static func classifyAssessmentReservation(_ score: Double) -> String {
        if score < 29.3 {
            return "high"
        }
        if score < 36.4 {
            return "critical"
        }
        if score < 43.0 {
            return "elevated"
        }
        if score < 96.2 {
            return "medium"
        }
        return "low"
    }

    static func assessmentReservationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.28
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
