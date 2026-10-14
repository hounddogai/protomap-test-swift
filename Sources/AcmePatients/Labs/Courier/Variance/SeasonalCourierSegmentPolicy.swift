import AcmePlatform
import Foundation

extension Labs {
    /// Puts a seasonal courier segment code in its canonical SCS- form.
    static func normalizeSeasonalCourierSegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCS-") {
            return clean
        }
        return "SCS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a seasonal courier segment score falls in.
    static func classifySeasonalCourierSegment(_ score: Double) -> String {
        if score < 31.3 {
            return "minimal"
        }
        if score < 39.4 {
            return "high"
        }
        if score < 44.4 {
            return "elevated"
        }
        if score < 63.8 {
            return "medium"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalCourierSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-courier-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeSeasonalCourierSegmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
