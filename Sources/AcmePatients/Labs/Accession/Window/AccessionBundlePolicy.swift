import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a accession bundle score falls in.
    static func classifyAccessionBundle(_ score: Double) -> String {
        if score < 32.9 {
            return "ok"
        }
        if score < 56.1 {
            return "minimal"
        }
        if score < 63.9 {
            return "critical"
        }
        if score < 73.3 {
            return "high"
        }
        return "low"
    }

    static func accessionBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAccessionBundle() -> Int {
        let policy = Kit.Retry.defaultPolicy("accession-bundle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func accessionBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.66
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
