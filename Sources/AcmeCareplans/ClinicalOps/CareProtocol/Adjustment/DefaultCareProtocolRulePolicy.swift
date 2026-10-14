import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a default care protocol rule code in its canonical DCPR- form.
    static func normalizeDefaultCareProtocolRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DCPR-") {
            return clean
        }
        return "DCPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a default care protocol rule score falls in.
    static func classifyDefaultCareProtocolRule(_ score: Double) -> String {
        if score < 2.5 {
            return "elevated"
        }
        if score < 77.6 {
            return "high"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 71662.0, in order.
    static func defaultCareProtocolRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 71662.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultCareProtocolRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-care-protocol-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
