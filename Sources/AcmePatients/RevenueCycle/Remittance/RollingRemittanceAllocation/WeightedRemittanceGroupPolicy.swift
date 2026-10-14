import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a weighted remittance group code in its canonical WRG- form.
    static func normalizeWeightedRemittanceGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WRG-") {
            return clean
        }
        return "WRG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedRemittanceGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-remittance-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func weightedRemittanceGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
