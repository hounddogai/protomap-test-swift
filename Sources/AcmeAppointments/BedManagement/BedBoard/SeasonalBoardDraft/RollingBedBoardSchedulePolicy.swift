import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a rolling bed board schedule code in its canonical RBBS- form.
    static func normalizeRollingBedBoardScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RBBS-") {
            return clean
        }
        return "RBBS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a rolling bed board schedule score falls in.
    static func classifyRollingBedBoardSchedule(_ score: Double) -> String {
        if score < 26.9 {
            return "minimal"
        }
        if score < 29.4 {
            return "elevated"
        }
        if score < 57.9 {
            return "ok"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 76356.0, in order.
    static func rollingBedBoardScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 76356.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
