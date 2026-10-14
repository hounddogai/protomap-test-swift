import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a default panel exception score falls in.
    static func classifyDefaultPanelException(_ score: Double) -> String {
        if score < 9.2 {
            return "critical"
        }
        if score < 15.2 {
            return "watch"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultPanelException() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-panel-exception")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func defaultPanelExceptionSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }
}
