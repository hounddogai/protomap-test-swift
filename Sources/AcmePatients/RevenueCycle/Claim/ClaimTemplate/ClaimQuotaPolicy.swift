import AcmePlatform
import Foundation

extension RevenueCycle {
    static func mergeClaimQuotaLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeClaimQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("claim-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a claim quota code in its canonical CQ- form.
    static func normalizeClaimQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CQ-") {
            return clean
        }
        return "CQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 8469.0, in order.
    static func claimQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 8469.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
