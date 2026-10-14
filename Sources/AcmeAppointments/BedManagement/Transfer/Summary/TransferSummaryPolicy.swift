import AcmePlatform
import Foundation

extension BedManagement {
    static func transferSummaryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.76
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTransferSummary() -> Int {
        let policy = Kit.Retry.defaultPolicy("transfer-summary")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a transfer summary score falls in.
    static func classifyTransferSummary(_ score: Double) -> String {
        if score < 58.3 {
            return "medium"
        }
        if score < 60.3 {
            return "high"
        }
        if score < 89.8 {
            return "low"
        }
        return "ok"
    }
}
