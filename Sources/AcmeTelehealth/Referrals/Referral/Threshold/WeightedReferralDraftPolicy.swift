import AcmePlatform
import Foundation

extension Referrals {
    static func weightedReferralDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedReferralDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-referral-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeWeightedReferralDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a weighted referral draft code in its canonical WRD- form.
    static func normalizeWeightedReferralDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WRD-") {
            return clean
        }
        return "WRD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
