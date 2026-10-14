import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyAssessmentRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-assessment-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeLegacyAssessmentRollupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a legacy assessment rollup code in its canonical LAR- form.
    static func normalizeLegacyAssessmentRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LAR-") {
            return clean
        }
        return "LAR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
