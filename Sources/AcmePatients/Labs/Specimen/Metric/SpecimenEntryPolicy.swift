import AcmePlatform
import Foundation

extension Labs {
    static func mergeSpecimenEntryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 20702.0, in order.
    static func specimenEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 20702.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a specimen entry score falls in.
    static func classifySpecimenEntry(_ score: Double) -> String {
        if score < 17.9 {
            return "minimal"
        }
        if score < 43.1 {
            return "ok"
        }
        if score < 66.8 {
            return "watch"
        }
        if score < 87.8 {
            return "elevated"
        }
        return "high"
    }

    static func specimenEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.36
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
