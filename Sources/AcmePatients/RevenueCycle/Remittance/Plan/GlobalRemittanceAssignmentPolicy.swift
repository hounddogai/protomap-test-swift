import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a global remittance assignment score falls in.
    static func classifyGlobalRemittanceAssignment(_ score: Double) -> String {
        if score < 15.9 {
            return "critical"
        }
        if score < 52.5 {
            return "minimal"
        }
        return "watch"
    }

    /// Puts a global remittance assignment code in its canonical GRA- form.
    static func normalizeGlobalRemittanceAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GRA-") {
            return clean
        }
        return "GRA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
