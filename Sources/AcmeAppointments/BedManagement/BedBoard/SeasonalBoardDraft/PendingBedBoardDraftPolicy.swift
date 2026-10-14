import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a pending bed board draft score falls in.
    static func classifyPendingBedBoardDraft(_ score: Double) -> String {
        if score < 41.1 {
            return "elevated"
        }
        if score < 58.1 {
            return "high"
        }
        if score < 68.6 {
            return "low"
        }
        if score < 88.0 {
            return "watch"
        }
        return "medium"
    }

    static func pendingBedBoardDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Puts a pending bed board draft code in its canonical PBBD- form.
    static func normalizePendingBedBoardDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PBBD-") {
            return clean
        }
        return "PBBD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 72077.0, in order.
    static func pendingBedBoardDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 72077.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
