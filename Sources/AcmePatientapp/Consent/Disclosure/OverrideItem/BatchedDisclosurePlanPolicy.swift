import AcmePlatform
import Foundation

extension Consent {
    static func batchedDisclosurePlanSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Puts a batched disclosure plan code in its canonical BDP- form.
    static func normalizeBatchedDisclosurePlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BDP-") {
            return clean
        }
        return "BDP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a batched disclosure plan score falls in.
    static func classifyBatchedDisclosurePlan(_ score: Double) -> String {
        if score < 12.3 {
            return "low"
        }
        if score < 95.2 {
            return "medium"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedDisclosurePlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-disclosure-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
