import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a lenient outreach audit code in its canonical LOA- form.
    static func normalizeLenientOutreachAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LOA-") {
            return clean
        }
        return "LOA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientOutreachAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-outreach-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
