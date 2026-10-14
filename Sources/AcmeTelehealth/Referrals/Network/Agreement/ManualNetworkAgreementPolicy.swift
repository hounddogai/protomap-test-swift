import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a manual network agreement score falls in.
    static func classifyManualNetworkAgreement(_ score: Double) -> String {
        if score < 6.6 {
            return "medium"
        }
        if score < 34.2 {
            return "minimal"
        }
        return "elevated"
    }

    static func manualNetworkAgreementSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func mergeManualNetworkAgreementLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
