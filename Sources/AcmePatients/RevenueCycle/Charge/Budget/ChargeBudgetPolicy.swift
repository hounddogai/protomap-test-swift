import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeChargeBudget() -> Int {
        let policy = Kit.Retry.defaultPolicy("charge-budget")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a charge budget code in its canonical CB- form.
    static func normalizeChargeBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CB-") {
            return clean
        }
        return "CB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a charge budget score falls in.
    static func classifyChargeBudget(_ score: Double) -> String {
        if score < 32.4 {
            return "critical"
        }
        if score < 57.1 {
            return "minimal"
        }
        if score < 60.1 {
            return "low"
        }
        if score < 88.6 {
            return "elevated"
        }
        return "high"
    }
}
