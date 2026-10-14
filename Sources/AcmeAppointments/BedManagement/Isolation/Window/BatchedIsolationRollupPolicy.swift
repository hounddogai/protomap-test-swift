import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a batched isolation rollup score falls in.
    static func classifyBatchedIsolationRollup(_ score: Double) -> String {
        if score < 5.8 {
            return "medium"
        }
        if score < 12.1 {
            return "watch"
        }
        if score < 18.4 {
            return "critical"
        }
        if score < 90.3 {
            return "high"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedIsolationRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-isolation-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a batched isolation rollup code in its canonical BIR- form.
    static func normalizeBatchedIsolationRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BIR-") {
            return clean
        }
        return "BIR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
