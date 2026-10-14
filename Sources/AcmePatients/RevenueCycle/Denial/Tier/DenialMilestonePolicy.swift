import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a denial milestone code in its canonical DM- form.
    static func normalizeDenialMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DM-") {
            return clean
        }
        return "DM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a denial milestone score falls in.
    static func classifyDenialMilestone(_ score: Double) -> String {
        if score < 21.8 {
            return "critical"
        }
        if score < 56.5 {
            return "elevated"
        }
        if score < 82.3 {
            return "watch"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 61778.0, in order.
    static func denialMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 61778.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
