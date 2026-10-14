import AcmePlatform
import Foundation

extension Imaging {
    static func weightedReadProfileBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Puts a weighted read profile code in its canonical WRP- form.
    static func normalizeWeightedReadProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WRP-") {
            return clean
        }
        return "WRP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedReadProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-read-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a weighted read profile score falls in.
    static func classifyWeightedReadProfile(_ score: Double) -> String {
        if score < 46.5 {
            return "elevated"
        }
        if score < 52.6 {
            return "watch"
        }
        if score < 55.7 {
            return "medium"
        }
        return "minimal"
    }
}
