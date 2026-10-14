import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a strict assessment bundle score falls in.
    static func classifyStrictAssessmentBundle(_ score: Double) -> String {
        if score < 30.5 {
            return "medium"
        }
        if score < 62.6 {
            return "critical"
        }
        if score < 63.3 {
            return "watch"
        }
        if score < 69.7 {
            return "elevated"
        }
        return "high"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictAssessmentBundle() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-assessment-bundle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func strictAssessmentBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a strict assessment bundle code in its canonical SAB- form.
    static func normalizeStrictAssessmentBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SAB-") {
            return clean
        }
        return "SAB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
