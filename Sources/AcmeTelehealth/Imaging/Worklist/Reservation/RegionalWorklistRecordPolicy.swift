import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a regional worklist record score falls in.
    static func classifyRegionalWorklistRecord(_ score: Double) -> String {
        if score < 19.7 {
            return "ok"
        }
        if score < 69.8 {
            return "elevated"
        }
        if score < 89.9 {
            return "medium"
        }
        return "critical"
    }

    static func regionalWorklistRecordBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalWorklistRecord() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-worklist-record")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func regionalWorklistRecordWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.85
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
