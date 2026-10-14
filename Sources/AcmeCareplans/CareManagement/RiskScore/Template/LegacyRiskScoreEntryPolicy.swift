import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a legacy risk score entry code in its canonical LRSE- form.
    static func normalizeLegacyRiskScoreEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRSE-") {
            return clean
        }
        return "LRSE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyRiskScoreEntry() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-risk-score-entry")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
