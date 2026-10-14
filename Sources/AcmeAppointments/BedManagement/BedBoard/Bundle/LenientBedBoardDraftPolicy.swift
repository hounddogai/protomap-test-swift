import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a lenient bed board draft code in its canonical LBBD- form.
    static func normalizeLenientBedBoardDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LBBD-") {
            return clean
        }
        return "LBBD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a lenient bed board draft score falls in.
    static func classifyLenientBedBoardDraft(_ score: Double) -> String {
        if score < 17.3 {
            return "critical"
        }
        if score < 53.4 {
            return "high"
        }
        if score < 53.5 {
            return "elevated"
        }
        if score < 83.8 {
            return "ok"
        }
        return "watch"
    }

    static func lenientBedBoardDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Counts how many amounts fit in a budget of 15098.0, in order.
    static func lenientBedBoardDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 15098.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
