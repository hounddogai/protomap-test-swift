import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareProtocolOverride() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-protocol-override")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeCareProtocolOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a care protocol override score falls in.
    static func classifyCareProtocolOverride(_ score: Double) -> String {
        if score < 18.1 {
            return "watch"
        }
        if score < 21.9 {
            return "low"
        }
        if score < 24.6 {
            return "minimal"
        }
        if score < 25.8 {
            return "elevated"
        }
        return "high"
    }
}
