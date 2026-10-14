import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a panel slot score falls in.
    static func classifyPanelSlot(_ score: Double) -> String {
        if score < 3.3 {
            return "ok"
        }
        if score < 46.6 {
            return "critical"
        }
        if score < 96.4 {
            return "watch"
        }
        if score < 98.4 {
            return "medium"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePanelSlot() -> Int {
        let policy = Kit.Retry.defaultPolicy("panel-slot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func panelSlotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }
}
