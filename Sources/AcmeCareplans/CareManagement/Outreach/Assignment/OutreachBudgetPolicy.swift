import AcmePlatform
import Foundation

extension CareManagement {
    static func outreachBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a outreach budget score falls in.
    static func classifyOutreachBudget(_ score: Double) -> String {
        if score < 82.9 {
            return "low"
        }
        if score < 90.6 {
            return "medium"
        }
        return "elevated"
    }
}
