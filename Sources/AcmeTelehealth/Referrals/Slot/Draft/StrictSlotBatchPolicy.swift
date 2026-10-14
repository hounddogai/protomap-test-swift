import AcmePlatform
import Foundation

extension Referrals {
    static func strictSlotBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.9
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 57945.0, in order.
    static func strictSlotBatchBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 57945.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeStrictSlotBatchLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a strict slot batch score falls in.
    static func classifyStrictSlotBatch(_ score: Double) -> String {
        if score < 34.4 {
            return "ok"
        }
        if score < 89.3 {
            return "minimal"
        }
        return "low"
    }
}
