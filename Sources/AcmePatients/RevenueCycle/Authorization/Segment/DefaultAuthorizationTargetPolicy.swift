import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultAuthorizationTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-authorization-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeDefaultAuthorizationTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a default authorization target code in its canonical DAT- form.
    static func normalizeDefaultAuthorizationTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DAT-") {
            return clean
        }
        return "DAT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a default authorization target score falls in.
    static func classifyDefaultAuthorizationTarget(_ score: Double) -> String {
        if score < 40.6 {
            return "ok"
        }
        if score < 65.2 {
            return "low"
        }
        if score < 85.1 {
            return "watch"
        }
        return "high"
    }
}
