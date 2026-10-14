import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedTransferBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-transfer-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a capped transfer baseline score falls in.
    static func classifyCappedTransferBaseline(_ score: Double) -> String {
        if score < 29.6 {
            return "watch"
        }
        if score < 31.9 {
            return "ok"
        }
        if score < 63.4 {
            return "critical"
        }
        return "minimal"
    }

    static func cappedTransferBaselineSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }
}
