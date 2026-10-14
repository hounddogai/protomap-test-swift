import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a revocation profile score falls in.
    static func classifyRevocationProfile(_ score: Double) -> String {
        if score < 9.0 {
            return "medium"
        }
        if score < 74.6 {
            return "minimal"
        }
        return "ok"
    }

    static func mergeRevocationProfileLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRevocationProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("revocation-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
