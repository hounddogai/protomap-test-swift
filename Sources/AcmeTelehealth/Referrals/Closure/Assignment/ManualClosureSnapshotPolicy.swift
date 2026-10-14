import AcmePlatform
import Foundation

extension Referrals {
    static func manualClosureSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.09
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func manualClosureSnapshotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Names the band a manual closure snapshot score falls in.
    static func classifyManualClosureSnapshot(_ score: Double) -> String {
        if score < 85.0 {
            return "critical"
        }
        if score < 90.2 {
            return "ok"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 15586.0, in order.
    static func manualClosureSnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 15586.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
