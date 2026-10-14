import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a assessment claim code in its canonical AC- form.
    static func normalizeAssessmentClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AC-") {
            return clean
        }
        return "AC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func assessmentClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAssessmentClaim() -> Int {
        let policy = Kit.Retry.defaultPolicy("assessment-claim")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
