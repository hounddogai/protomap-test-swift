import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a acuity plan forecast code in its canonical APF- form.
    static func normalizeAcuityPlanForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("APF-") {
            return clean
        }
        return "APF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 72416.0, in order.
    static func acuityPlanForecastBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 72416.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
