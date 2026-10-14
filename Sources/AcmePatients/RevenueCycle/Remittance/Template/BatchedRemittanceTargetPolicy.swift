import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedRemittanceTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-remittance-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func batchedRemittanceTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Puts a batched remittance target code in its canonical BRT- form.
    static func normalizeBatchedRemittanceTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BRT-") {
            return clean
        }
        return "BRT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
