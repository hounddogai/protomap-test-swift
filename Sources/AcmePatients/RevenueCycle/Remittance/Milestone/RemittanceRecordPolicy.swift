import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRemittanceRecord() -> Int {
        let policy = Kit.Retry.defaultPolicy("remittance-record")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func remittanceRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a remittance record score falls in.
    static func classifyRemittanceRecord(_ score: Double) -> String {
        if score < 11.0 {
            return "medium"
        }
        if score < 11.1 {
            return "elevated"
        }
        if score < 69.5 {
            return "high"
        }
        if score < 74.3 {
            return "minimal"
        }
        return "ok"
    }
}
