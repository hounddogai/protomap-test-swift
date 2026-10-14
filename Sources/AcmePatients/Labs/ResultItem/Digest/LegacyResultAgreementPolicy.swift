import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 15778.0, in order.
    static func legacyResultAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 15778.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyResultAgreement() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-result-agreement")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeLegacyResultAgreementLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a legacy result agreement score falls in.
    static func classifyLegacyResultAgreement(_ score: Double) -> String {
        if score < 32.6 {
            return "minimal"
        }
        if score < 56.4 {
            return "high"
        }
        return "medium"
    }
}
