import AcmePlatform
import Foundation

extension RevenueCycle {
    static func authorizationCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.46
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a authorization cycle score falls in.
    static func classifyAuthorizationCycle(_ score: Double) -> String {
        if score < 3.3 {
            return "watch"
        }
        if score < 12.0 {
            return "high"
        }
        if score < 20.2 {
            return "minimal"
        }
        if score < 67.0 {
            return "ok"
        }
        return "medium"
    }

    /// Puts a authorization cycle code in its canonical AC- form.
    static func normalizeAuthorizationCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AC-") {
            return clean
        }
        return "AC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAuthorizationCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("authorization-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
