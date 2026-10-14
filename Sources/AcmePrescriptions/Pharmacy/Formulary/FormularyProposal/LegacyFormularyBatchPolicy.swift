import AcmePlatform
import Foundation

extension Pharmacy {
    static func legacyFormularyBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    static func legacyFormularyBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.14
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a legacy formulary batch score falls in.
    static func classifyLegacyFormularyBatch(_ score: Double) -> String {
        if score < 54.4 {
            return "medium"
        }
        if score < 71.3 {
            return "elevated"
        }
        return "high"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyFormularyBatch() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-formulary-batch")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
