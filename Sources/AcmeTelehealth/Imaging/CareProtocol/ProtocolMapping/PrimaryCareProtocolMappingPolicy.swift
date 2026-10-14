import AcmePlatform
import Foundation

extension Imaging {
    static func primaryCareProtocolMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryCareProtocolMapping() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-care-protocol-mapping")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a primary care protocol mapping score falls in.
    static func classifyPrimaryCareProtocolMapping(_ score: Double) -> String {
        if score < 7.9 {
            return "high"
        }
        if score < 26.7 {
            return "ok"
        }
        if score < 52.3 {
            return "low"
        }
        return "critical"
    }

    static func primaryCareProtocolMappingSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
