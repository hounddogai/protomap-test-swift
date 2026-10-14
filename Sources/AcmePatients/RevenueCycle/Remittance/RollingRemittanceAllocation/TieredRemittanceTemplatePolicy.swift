import AcmePlatform
import Foundation

extension RevenueCycle {
    static func tieredRemittanceTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a tiered remittance template score falls in.
    static func classifyTieredRemittanceTemplate(_ score: Double) -> String {
        if score < 8.8 {
            return "watch"
        }
        if score < 73.2 {
            return "high"
        }
        if score < 93.8 {
            return "low"
        }
        return "ok"
    }

    static func tieredRemittanceTemplateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.74
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredRemittanceTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-remittance-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
