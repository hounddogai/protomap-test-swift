import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedReadPlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-read-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a batched read plan code in its canonical BRP- form.
    static func normalizeBatchedReadPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BRP-") {
            return clean
        }
        return "BRP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func batchedReadPlanSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
