import AcmePlatform
import Foundation

extension RevenueCycle {
    static func mergeWeightedAuthorizationEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func weightedAuthorizationEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedAuthorizationEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-authorization-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a weighted authorization estimate code in its canonical WAE- form.
    static func normalizeWeightedAuthorizationEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WAE-") {
            return clean
        }
        return "WAE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
