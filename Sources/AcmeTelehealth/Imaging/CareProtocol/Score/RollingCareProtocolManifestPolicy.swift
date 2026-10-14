import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a rolling care protocol manifest score falls in.
    static func classifyRollingCareProtocolManifest(_ score: Double) -> String {
        if score < 6.0 {
            return "low"
        }
        if score < 31.4 {
            return "watch"
        }
        if score < 48.9 {
            return "elevated"
        }
        return "ok"
    }

    static func rollingCareProtocolManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Puts a rolling care protocol manifest code in its canonical RCPM- form.
    static func normalizeRollingCareProtocolManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RCPM-") {
            return clean
        }
        return "RCPM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingCareProtocolManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-care-protocol-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
