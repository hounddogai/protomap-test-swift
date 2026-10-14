import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAssessmentScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("assessment-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a assessment score code in its canonical AS- form.
    static func normalizeAssessmentScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AS-") {
            return clean
        }
        return "AS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
