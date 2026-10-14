import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a weighted follow up assignment score falls in.
    static func classifyWeightedFollowUpAssignment(_ score: Double) -> String {
        if score < 59.4 {
            return "low"
        }
        if score < 60.6 {
            return "watch"
        }
        if score < 72.6 {
            return "ok"
        }
        if score < 78.1 {
            return "medium"
        }
        return "elevated"
    }

    /// Puts a weighted follow up assignment code in its canonical WFUA- form.
    static func normalizeWeightedFollowUpAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WFUA-") {
            return clean
        }
        return "WFUA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
