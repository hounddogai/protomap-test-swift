import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeAssessmentAuditLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func assessmentAuditBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAssessmentAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("assessment-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a assessment audit code in its canonical AA- form.
    static func normalizeAssessmentAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AA-") {
            return clean
        }
        return "AA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
