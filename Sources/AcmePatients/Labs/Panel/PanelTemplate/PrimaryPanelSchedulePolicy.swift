import AcmePlatform
import Foundation

extension Labs {
    /// Puts a primary panel schedule code in its canonical PPS- form.
    static func normalizePrimaryPanelScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PPS-") {
            return clean
        }
        return "PPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func primaryPanelScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a primary panel schedule score falls in.
    static func classifyPrimaryPanelSchedule(_ score: Double) -> String {
        if score < 1.4 {
            return "medium"
        }
        if score < 20.5 {
            return "minimal"
        }
        if score < 89.2 {
            return "low"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 36649.0, in order.
    static func primaryPanelScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 36649.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
