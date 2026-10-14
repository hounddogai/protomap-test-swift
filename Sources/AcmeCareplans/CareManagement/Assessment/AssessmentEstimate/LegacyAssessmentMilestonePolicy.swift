import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a legacy assessment milestone code in its canonical LAM- form.
    static func normalizeLegacyAssessmentMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LAM-") {
            return clean
        }
        return "LAM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeLegacyAssessmentMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a legacy assessment milestone score falls in.
    static func classifyLegacyAssessmentMilestone(_ score: Double) -> String {
        if score < 1.5 {
            return "high"
        }
        if score < 67.0 {
            return "critical"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyAssessmentMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-assessment-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
