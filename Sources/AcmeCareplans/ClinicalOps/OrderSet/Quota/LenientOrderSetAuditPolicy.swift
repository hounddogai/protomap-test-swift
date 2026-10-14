import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientOrderSetAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-order-set-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a lenient order set audit code in its canonical LOSA- form.
    static func normalizeLenientOrderSetAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LOSA-") {
            return clean
        }
        return "LOSA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
