import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a weighted referral variance code in its canonical WRV- form.
    static func normalizeWeightedReferralVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WRV-") {
            return clean
        }
        return "WRV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeWeightedReferralVarianceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func weightedReferralVarianceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedReferralVariance() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-referral-variance")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
