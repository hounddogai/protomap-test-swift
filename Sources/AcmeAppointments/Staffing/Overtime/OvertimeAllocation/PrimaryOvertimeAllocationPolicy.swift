import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a primary overtime allocation code in its canonical POA- form.
    static func normalizePrimaryOvertimeAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("POA-") {
            return clean
        }
        return "POA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 99950.0, in order.
    static func primaryOvertimeAllocationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 99950.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a primary overtime allocation score falls in.
    static func classifyPrimaryOvertimeAllocation(_ score: Double) -> String {
        if score < 41.7 {
            return "critical"
        }
        if score < 96.8 {
            return "watch"
        }
        return "ok"
    }
}
