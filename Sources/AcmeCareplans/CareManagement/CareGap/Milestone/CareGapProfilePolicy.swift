import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a care gap profile score falls in.
    static func classifyCareGapProfile(_ score: Double) -> String {
        if score < 24.2 {
            return "minimal"
        }
        if score < 29.7 {
            return "elevated"
        }
        if score < 85.4 {
            return "high"
        }
        if score < 93.2 {
            return "medium"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareGapProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-gap-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func careGapProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }
}
