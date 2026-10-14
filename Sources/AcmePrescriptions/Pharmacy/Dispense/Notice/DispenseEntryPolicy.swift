import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 31075.0, in order.
    static func dispenseEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 31075.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a dispense entry score falls in.
    static func classifyDispenseEntry(_ score: Double) -> String {
        if score < 45.9 {
            return "low"
        }
        if score < 46.5 {
            return "watch"
        }
        if score < 54.3 {
            return "minimal"
        }
        return "elevated"
    }

    static func mergeDispenseEntryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
