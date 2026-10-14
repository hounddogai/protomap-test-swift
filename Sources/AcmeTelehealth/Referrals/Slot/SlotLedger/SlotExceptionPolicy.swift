import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a slot exception score falls in.
    static func classifySlotException(_ score: Double) -> String {
        if score < 21.3 {
            return "ok"
        }
        if score < 52.7 {
            return "medium"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 99044.0, in order.
    static func slotExceptionBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 99044.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a slot exception code in its canonical SE- form.
    static func normalizeSlotExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SE-") {
            return clean
        }
        return "SE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func slotExceptionWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.27
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
