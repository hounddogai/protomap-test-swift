import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a rolling care gap bundle code in its canonical RCGB- form.
    static func normalizeRollingCareGapBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RCGB-") {
            return clean
        }
        return "RCGB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingCareGapBundle() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-care-gap-bundle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a rolling care gap bundle score falls in.
    static func classifyRollingCareGapBundle(_ score: Double) -> String {
        if score < 41.3 {
            return "low"
        }
        if score < 86.2 {
            return "critical"
        }
        return "high"
    }
}
