import AcmePlatform
import Foundation

extension Consent {
    static func mergeTieredRevocationManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredRevocationManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-revocation-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a tiered revocation manifest score falls in.
    static func classifyTieredRevocationManifest(_ score: Double) -> String {
        if score < 12.5 {
            return "elevated"
        }
        if score < 81.7 {
            return "minimal"
        }
        if score < 94.8 {
            return "low"
        }
        return "medium"
    }
}
