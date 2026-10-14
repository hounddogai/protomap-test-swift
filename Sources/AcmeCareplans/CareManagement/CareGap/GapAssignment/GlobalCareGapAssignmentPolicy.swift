import AcmePlatform
import Foundation

extension CareManagement {
    static func globalCareGapAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a global care gap assignment code in its canonical GCGA- form.
    static func normalizeGlobalCareGapAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GCGA-") {
            return clean
        }
        return "GCGA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalCareGapAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-care-gap-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
