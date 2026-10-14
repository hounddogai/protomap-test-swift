import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a interaction budget score falls in.
    static func classifyInteractionBudget(_ score: Double) -> String {
        if score < 38.7 {
            return "watch"
        }
        if score < 63.0 {
            return "elevated"
        }
        return "medium"
    }

    static func interactionBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
