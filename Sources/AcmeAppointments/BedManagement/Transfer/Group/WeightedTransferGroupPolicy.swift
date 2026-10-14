import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 82198.0, in order.
    static func weightedTransferGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 82198.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedTransferGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-transfer-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a weighted transfer group code in its canonical WTG- form.
    static func normalizeWeightedTransferGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WTG-") {
            return clean
        }
        return "WTG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func weightedTransferGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
