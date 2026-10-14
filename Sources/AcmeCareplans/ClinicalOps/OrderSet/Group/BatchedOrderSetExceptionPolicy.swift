import AcmePlatform
import Foundation

extension ClinicalOps {
    static func batchedOrderSetExceptionSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Puts a batched order set exception code in its canonical BOSE- form.
    static func normalizeBatchedOrderSetExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BOSE-") {
            return clean
        }
        return "BOSE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedOrderSetException() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-order-set-exception")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeBatchedOrderSetExceptionLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
