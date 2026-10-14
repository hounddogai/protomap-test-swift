import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeShiftDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("shift-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a shift draft score falls in.
    static func classifyShiftDraft(_ score: Double) -> String {
        if score < 38.4 {
            return "watch"
        }
        if score < 43.1 {
            return "low"
        }
        if score < 51.8 {
            return "medium"
        }
        return "elevated"
    }

    static func shiftDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
