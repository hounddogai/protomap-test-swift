import AcmePlatform
import Foundation

extension Referrals {
    static func mergeRegionalFollowUpRuleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a regional follow up rule code in its canonical RFUR- form.
    static func normalizeRegionalFollowUpRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RFUR-") {
            return clean
        }
        return "RFUR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalFollowUpRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-follow-up-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 9529.0, in order.
    static func regionalFollowUpRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 9529.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
