import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedChargePolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-charge-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a weighted charge policy score falls in.
    static func classifyWeightedChargePolicy(_ score: Double) -> String {
        if score < 17.0 {
            return "low"
        }
        if score < 29.0 {
            return "medium"
        }
        if score < 35.9 {
            return "ok"
        }
        if score < 55.9 {
            return "elevated"
        }
        return "critical"
    }

    /// Puts a weighted charge policy code in its canonical WCP- form.
    static func normalizeWeightedChargePolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WCP-") {
            return clean
        }
        return "WCP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
