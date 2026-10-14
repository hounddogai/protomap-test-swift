import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a manual courier estimate score falls in.
    static func classifyManualCourierEstimate(_ score: Double) -> String {
        if score < 12.7 {
            return "elevated"
        }
        if score < 34.8 {
            return "high"
        }
        if score < 96.7 {
            return "watch"
        }
        return "medium"
    }

    static func manualCourierEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualCourierEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-courier-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
