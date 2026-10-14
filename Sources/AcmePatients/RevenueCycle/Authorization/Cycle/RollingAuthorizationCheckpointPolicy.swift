import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 60665.0, in order.
    static func rollingAuthorizationCheckpointBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 60665.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a rolling authorization checkpoint code in its canonical RAC- form.
    static func normalizeRollingAuthorizationCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RAC-") {
            return clean
        }
        return "RAC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingAuthorizationCheckpoint() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-authorization-checkpoint")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func rollingAuthorizationCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.84
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
