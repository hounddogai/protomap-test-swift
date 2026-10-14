import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a manual consent form estimate score falls in.
    static func classifyManualConsentFormEstimate(_ score: Double) -> String {
        if score < 51.7 {
            return "medium"
        }
        if score < 52.3 {
            return "ok"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualConsentFormEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-consent-form-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeManualConsentFormEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func manualConsentFormEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
