import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a priority allocation score falls in.
    static func classifyPriorityAllocation(_ score: Double) -> String {
        if score < 17.2 {
            return "elevated"
        }
        if score < 50.5 {
            return "low"
        }
        if score < 50.7 {
            return "critical"
        }
        if score < 61.4 {
            return "minimal"
        }
        return "high"
    }

    static func priorityAllocationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 91656.0, in order.
    static func priorityAllocationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 91656.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a priority allocation code in its canonical PA- form.
    static func normalizePriorityAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PA-") {
            return clean
        }
        return "PA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
