import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a strict closure segment score falls in.
    static func classifyStrictClosureSegment(_ score: Double) -> String {
        if score < 4.1 {
            return "critical"
        }
        if score < 18.9 {
            return "watch"
        }
        if score < 24.9 {
            return "minimal"
        }
        if score < 29.7 {
            return "medium"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictClosureSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-closure-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a strict closure segment code in its canonical SCS- form.
    static func normalizeStrictClosureSegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCS-") {
            return clean
        }
        return "SCS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
