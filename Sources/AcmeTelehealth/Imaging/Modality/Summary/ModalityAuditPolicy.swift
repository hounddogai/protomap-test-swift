import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a modality audit code in its canonical MA- form.
    static func normalizeModalityAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MA-") {
            return clean
        }
        return "MA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func modalityAuditSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeModalityAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("modality-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
