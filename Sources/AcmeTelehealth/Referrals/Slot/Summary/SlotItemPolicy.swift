import AcmePlatform
import Foundation

extension Referrals {
    static func slotItemSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSlotItem() -> Int {
        let policy = Kit.Retry.defaultPolicy("slot-item")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a slot item score falls in.
    static func classifySlotItem(_ score: Double) -> String {
        if score < 35.8 {
            return "ok"
        }
        if score < 67.4 {
            return "low"
        }
        return "minimal"
    }
}
