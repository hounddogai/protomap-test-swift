import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a global cleaning plan score falls in.
    static func classifyGlobalCleaningPlan(_ score: Double) -> String {
        if score < 41.7 {
            return "ok"
        }
        if score < 75.9 {
            return "minimal"
        }
        return "elevated"
    }

    /// Puts a global cleaning plan code in its canonical GCP- form.
    static func normalizeGlobalCleaningPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GCP-") {
            return clean
        }
        return "GCP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func globalCleaningPlanBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
