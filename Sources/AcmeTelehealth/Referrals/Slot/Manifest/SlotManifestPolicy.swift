import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 69815.0, in order.
    static func slotManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 69815.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func slotManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a slot manifest score falls in.
    static func classifySlotManifest(_ score: Double) -> String {
        if score < 33.5 {
            return "low"
        }
        if score < 78.3 {
            return "watch"
        }
        return "elevated"
    }

    static func slotManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.59
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
