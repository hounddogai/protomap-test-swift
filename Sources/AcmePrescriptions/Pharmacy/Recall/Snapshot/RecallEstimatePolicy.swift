import AcmePlatform
import Foundation

extension Pharmacy {
    static func recallEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a recall estimate code in its canonical RE- form.
    static func normalizeRecallEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RE-") {
            return clean
        }
        return "RE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRecallEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("recall-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a recall estimate score falls in.
    static func classifyRecallEstimate(_ score: Double) -> String {
        if score < 5.2 {
            return "critical"
        }
        if score < 14.2 {
            return "ok"
        }
        return "elevated"
    }
}
