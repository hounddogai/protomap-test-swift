import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 98418.0, in order.
    static func manualCareProtocolSlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 98418.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a manual care protocol slot score falls in.
    static func classifyManualCareProtocolSlot(_ score: Double) -> String {
        if score < 2.1 {
            return "minimal"
        }
        if score < 63.1 {
            return "high"
        }
        return "watch"
    }

    /// Puts a manual care protocol slot code in its canonical MCPS- form.
    static func normalizeManualCareProtocolSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MCPS-") {
            return clean
        }
        return "MCPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func manualCareProtocolSlotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }
}
