import AcmePlatform
import Foundation

extension Staffing {
    static func skillMixBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.47
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a skill mix batch score falls in.
    static func classifySkillMixBatch(_ score: Double) -> String {
        if score < 52.8 {
            return "ok"
        }
        if score < 83.4 {
            return "medium"
        }
        return "critical"
    }

    static func mergeSkillMixBatchLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 40845.0, in order.
    static func skillMixBatchBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 40845.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
