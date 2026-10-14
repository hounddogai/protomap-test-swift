import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientLanguageAgreement() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-language-agreement")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func lenientLanguageAgreementBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func mergeLenientLanguageAgreementLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a lenient language agreement score falls in.
    static func classifyLenientLanguageAgreement(_ score: Double) -> String {
        if score < 8.4 {
            return "watch"
        }
        if score < 10.0 {
            return "high"
        }
        if score < 26.9 {
            return "low"
        }
        if score < 65.5 {
            return "ok"
        }
        return "critical"
    }
}
