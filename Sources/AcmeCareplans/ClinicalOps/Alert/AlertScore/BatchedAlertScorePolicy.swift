import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a batched alert score code in its canonical BAS- form.
    static func normalizeBatchedAlertScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BAS-") {
            return clean
        }
        return "BAS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func batchedAlertScoreSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedAlertScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-alert-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func batchedAlertScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
