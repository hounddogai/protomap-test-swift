import AcmePlatform
import Foundation

extension CareManagement {
    static func assessmentCycleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAssessmentCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("assessment-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a assessment cycle code in its canonical AC- form.
    static func normalizeAssessmentCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AC-") {
            return clean
        }
        return "AC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
