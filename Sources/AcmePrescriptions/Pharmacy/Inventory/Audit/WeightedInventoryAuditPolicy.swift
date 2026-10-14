import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedInventoryAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-inventory-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 3379.0, in order.
    static func weightedInventoryAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 3379.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func weightedInventoryAuditSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Puts a weighted inventory audit code in its canonical WIA- form.
    static func normalizeWeightedInventoryAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WIA-") {
            return clean
        }
        return "WIA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
