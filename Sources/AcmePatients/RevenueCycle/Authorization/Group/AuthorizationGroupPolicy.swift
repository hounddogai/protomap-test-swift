import AcmePlatform
import Foundation

extension RevenueCycle {
    static func mergeAuthorizationGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a authorization group code in its canonical AG- form.
    static func normalizeAuthorizationGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AG-") {
            return clean
        }
        return "AG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAuthorizationGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("authorization-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 26312.0, in order.
    static func authorizationGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 26312.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
