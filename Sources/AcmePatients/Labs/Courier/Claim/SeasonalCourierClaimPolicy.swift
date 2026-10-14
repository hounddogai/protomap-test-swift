import AcmePlatform
import Foundation

extension Labs {
    /// Puts a seasonal courier claim code in its canonical SCC- form.
    static func normalizeSeasonalCourierClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCC-") {
            return clean
        }
        return "SCC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a seasonal courier claim score falls in.
    static func classifySeasonalCourierClaim(_ score: Double) -> String {
        if score < 23.0 {
            return "elevated"
        }
        if score < 33.2 {
            return "watch"
        }
        if score < 38.3 {
            return "high"
        }
        if score < 46.5 {
            return "ok"
        }
        return "minimal"
    }

    static func seasonalCourierClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalCourierClaim() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-courier-claim")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
