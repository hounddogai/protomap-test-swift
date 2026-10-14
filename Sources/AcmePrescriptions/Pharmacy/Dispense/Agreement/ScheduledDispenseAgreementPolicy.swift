import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a scheduled dispense agreement score falls in.
    static func classifyScheduledDispenseAgreement(_ score: Double) -> String {
        if score < 22.6 {
            return "minimal"
        }
        if score < 48.8 {
            return "medium"
        }
        if score < 67.5 {
            return "critical"
        }
        return "high"
    }

    static func scheduledDispenseAgreementWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.15
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledDispenseAgreement() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-dispense-agreement")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
