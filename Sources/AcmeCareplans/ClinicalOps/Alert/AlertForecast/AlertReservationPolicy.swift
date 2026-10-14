import AcmePlatform
import Foundation

extension ClinicalOps {
    static func alertReservationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.38
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAlertReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("alert-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func alertReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a alert reservation score falls in.
    static func classifyAlertReservation(_ score: Double) -> String {
        if score < 13.6 {
            return "watch"
        }
        if score < 41.1 {
            return "high"
        }
        if score < 53.0 {
            return "low"
        }
        if score < 80.3 {
            return "critical"
        }
        return "medium"
    }
}
