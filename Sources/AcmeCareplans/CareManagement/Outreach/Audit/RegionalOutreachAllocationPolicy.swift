import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a regional outreach allocation code in its canonical ROA- form.
    static func normalizeRegionalOutreachAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ROA-") {
            return clean
        }
        return "ROA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a regional outreach allocation score falls in.
    static func classifyRegionalOutreachAllocation(_ score: Double) -> String {
        if score < 25.1 {
            return "critical"
        }
        if score < 99.8 {
            return "medium"
        }
        return "elevated"
    }
}
