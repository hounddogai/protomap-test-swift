import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a scheduled handoff quota code in its canonical SHQ- form.
    static func normalizeScheduledHandoffQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SHQ-") {
            return clean
        }
        return "SHQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 35139.0, in order.
    static func scheduledHandoffQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 35139.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a scheduled handoff quota score falls in.
    static func classifyScheduledHandoffQuota(_ score: Double) -> String {
        if score < 98.1 {
            return "minimal"
        }
        if score < 99.8 {
            return "critical"
        }
        return "low"
    }
}
