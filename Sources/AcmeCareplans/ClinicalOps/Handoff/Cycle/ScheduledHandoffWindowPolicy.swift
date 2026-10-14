import AcmePlatform
import Foundation

extension ClinicalOps {
    static func scheduledHandoffWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.12
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 60934.0, in order.
    static func scheduledHandoffWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 60934.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a scheduled handoff window score falls in.
    static func classifyScheduledHandoffWindow(_ score: Double) -> String {
        if score < 5.8 {
            return "ok"
        }
        if score < 45.5 {
            return "minimal"
        }
        if score < 55.4 {
            return "critical"
        }
        if score < 84.0 {
            return "high"
        }
        return "medium"
    }

    /// Puts a scheduled handoff window code in its canonical SHW- form.
    static func normalizeScheduledHandoffWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SHW-") {
            return clean
        }
        return "SHW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
