import AcmePlatform
import Foundation

extension CareManagement {
    static func primaryAssessmentAuditBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a primary assessment audit code in its canonical PAA- form.
    static func normalizePrimaryAssessmentAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PAA-") {
            return clean
        }
        return "PAA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryAssessmentAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-assessment-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
