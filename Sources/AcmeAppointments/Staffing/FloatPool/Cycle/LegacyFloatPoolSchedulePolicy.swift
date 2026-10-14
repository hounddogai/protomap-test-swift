import AcmePlatform
import Foundation

extension Staffing {
    static func legacyFloatPoolScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Counts how many amounts fit in a budget of 19019.0, in order.
    static func legacyFloatPoolScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 19019.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a legacy float pool schedule code in its canonical LFPS- form.
    static func normalizeLegacyFloatPoolScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LFPS-") {
            return clean
        }
        return "LFPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func legacyFloatPoolScheduleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.55
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
