import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 74853.0, in order.
    static func roundingGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 74853.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func roundingGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRoundingGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("rounding-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a rounding group code in its canonical RG- form.
    static func normalizeRoundingGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RG-") {
            return clean
        }
        return "RG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
