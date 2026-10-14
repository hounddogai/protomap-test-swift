import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeLenientIsolationManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a lenient isolation manifest score falls in.
    static func classifyLenientIsolationManifest(_ score: Double) -> String {
        if score < 36.2 {
            return "minimal"
        }
        if score < 72.2 {
            return "elevated"
        }
        if score < 83.6 {
            return "ok"
        }
        if score < 85.4 {
            return "critical"
        }
        return "high"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientIsolationManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-isolation-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
