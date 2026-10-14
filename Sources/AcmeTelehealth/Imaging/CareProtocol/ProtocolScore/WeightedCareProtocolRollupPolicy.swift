import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedCareProtocolRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-care-protocol-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 75368.0, in order.
    static func weightedCareProtocolRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 75368.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a weighted care protocol rollup code in its canonical WCPR- form.
    static func normalizeWeightedCareProtocolRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WCPR-") {
            return clean
        }
        return "WCPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
