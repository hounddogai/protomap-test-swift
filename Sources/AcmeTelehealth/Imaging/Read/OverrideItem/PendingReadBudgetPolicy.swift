import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a pending read budget score falls in.
    static func classifyPendingReadBudget(_ score: Double) -> String {
        if score < 18.0 {
            return "medium"
        }
        if score < 49.6 {
            return "critical"
        }
        if score < 53.5 {
            return "watch"
        }
        return "minimal"
    }

    static func pendingReadBudgetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.37
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
