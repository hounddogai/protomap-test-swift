import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledCensusBudget() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-census-budget")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a scheduled census budget code in its canonical SCB- form.
    static func normalizeScheduledCensusBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCB-") {
            return clean
        }
        return "SCB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeScheduledCensusBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 76758.0, in order.
    static func scheduledCensusBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 76758.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
