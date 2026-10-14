import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a worklist record score falls in.
    static func classifyWorklistRecord(_ score: Double) -> String {
        if score < 3.1 {
            return "medium"
        }
        if score < 21.6 {
            return "low"
        }
        if score < 40.9 {
            return "elevated"
        }
        return "watch"
    }

    static func worklistRecordWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.72
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWorklistRecord() -> Int {
        let policy = Kit.Retry.defaultPolicy("worklist-record")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
