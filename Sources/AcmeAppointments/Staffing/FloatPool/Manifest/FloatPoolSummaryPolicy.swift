import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a float pool summary code in its canonical FPS- form.
    static func normalizeFloatPoolSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FPS-") {
            return clean
        }
        return "FPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func floatPoolSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a float pool summary score falls in.
    static func classifyFloatPoolSummary(_ score: Double) -> String {
        if score < 1.7 {
            return "minimal"
        }
        if score < 30.0 {
            return "watch"
        }
        if score < 70.9 {
            return "medium"
        }
        if score < 81.1 {
            return "low"
        }
        return "high"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFloatPoolSummary() -> Int {
        let policy = Kit.Retry.defaultPolicy("float-pool-summary")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
