import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeIsolationGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("isolation-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 33724.0, in order.
    static func isolationGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 33724.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeIsolationGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a isolation group code in its canonical IG- form.
    static func normalizeIsolationGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IG-") {
            return clean
        }
        return "IG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
