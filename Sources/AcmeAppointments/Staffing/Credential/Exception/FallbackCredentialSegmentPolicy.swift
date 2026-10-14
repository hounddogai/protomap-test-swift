import AcmePlatform
import Foundation

extension Staffing {
    static func mergeFallbackCredentialSegmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackCredentialSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-credential-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a fallback credential segment score falls in.
    static func classifyFallbackCredentialSegment(_ score: Double) -> String {
        if score < 26.8 {
            return "watch"
        }
        if score < 86.6 {
            return "minimal"
        }
        return "elevated"
    }
}
