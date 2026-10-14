import AcmePlatform
import Foundation

extension Labs {
    static func regionalAccessionScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 76427.0, in order.
    static func regionalAccessionScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 76427.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func regionalAccessionScheduleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.86
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a regional accession schedule code in its canonical RAS- form.
    static func normalizeRegionalAccessionScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RAS-") {
            return clean
        }
        return "RAS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
