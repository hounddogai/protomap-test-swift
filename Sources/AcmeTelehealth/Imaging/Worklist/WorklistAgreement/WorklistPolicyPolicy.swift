import AcmePlatform
import Foundation

extension Imaging {
    static func worklistPolicyWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.28
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWorklistPolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("worklist-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a worklist policy score falls in.
    static func classifyWorklistPolicy(_ score: Double) -> String {
        if score < 67.8 {
            return "elevated"
        }
        if score < 69.4 {
            return "medium"
        }
        return "watch"
    }
}
