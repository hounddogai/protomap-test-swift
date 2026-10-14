import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedInventoryAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-inventory-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 37276.0, in order.
    static func weightedInventoryAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 37276.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a weighted inventory assignment code in its canonical WIA- form.
    static func normalizeWeightedInventoryAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WIA-") {
            return clean
        }
        return "WIA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeWeightedInventoryAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
