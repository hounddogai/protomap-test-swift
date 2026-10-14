import AcmePlatform
import Foundation

extension RevenueCycle {
    static func claimNoticeSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a claim notice score falls in.
    static func classifyClaimNotice(_ score: Double) -> String {
        if score < 23.7 {
            return "low"
        }
        if score < 27.1 {
            return "elevated"
        }
        if score < 72.9 {
            return "ok"
        }
        return "critical"
    }

    /// Puts a claim notice code in its canonical CN- form.
    static func normalizeClaimNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CN-") {
            return clean
        }
        return "CN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeClaimNotice() -> Int {
        let policy = Kit.Retry.defaultPolicy("claim-notice")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
