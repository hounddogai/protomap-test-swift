import AcmePlatform
import Foundation

extension Pharmacy {
    static func lenientInventoryDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientInventoryDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-inventory-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func lenientInventoryDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a lenient inventory digest score falls in.
    static func classifyLenientInventoryDigest(_ score: Double) -> String {
        if score < 10.4 {
            return "low"
        }
        if score < 46.4 {
            return "ok"
        }
        return "minimal"
    }
}
