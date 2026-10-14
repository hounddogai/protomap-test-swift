import AcmePlatform
import Foundation

extension Consent {
    static func mergeLegacyLanguageTemplateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyLanguageTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-language-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a legacy language template score falls in.
    static func classifyLegacyLanguageTemplate(_ score: Double) -> String {
        if score < 35.4 {
            return "high"
        }
        if score < 55.3 {
            return "critical"
        }
        if score < 76.5 {
            return "watch"
        }
        if score < 90.4 {
            return "low"
        }
        return "minimal"
    }

    static func legacyLanguageTemplateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
