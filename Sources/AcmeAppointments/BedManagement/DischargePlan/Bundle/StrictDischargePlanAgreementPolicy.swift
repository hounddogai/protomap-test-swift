import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeStrictDischargePlanAgreementLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictDischargePlanAgreement() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-discharge-plan-agreement")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 4433.0, in order.
    static func strictDischargePlanAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 4433.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a strict discharge plan agreement code in its canonical SDPA- form.
    static func normalizeStrictDischargePlanAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SDPA-") {
            return clean
        }
        return "SDPA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
