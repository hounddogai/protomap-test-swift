import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a interaction profile score falls in.
    static func classifyInteractionProfile(_ score: Double) -> String {
        if score < 4.7 {
            return "minimal"
        }
        if score < 70.6 {
            return "elevated"
        }
        if score < 84.8 {
            return "ok"
        }
        return "medium"
    }

    /// Puts a interaction profile code in its canonical IP- form.
    static func normalizeInteractionProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IP-") {
            return clean
        }
        return "IP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 36613.0, in order.
    static func interactionProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 36613.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func interactionProfileBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
