import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a lenient formulary audit code in its canonical LFA- form.
    static func normalizeLenientFormularyAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LFA-") {
            return clean
        }
        return "LFA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientFormularyAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-formulary-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func lenientFormularyAuditSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }
}
