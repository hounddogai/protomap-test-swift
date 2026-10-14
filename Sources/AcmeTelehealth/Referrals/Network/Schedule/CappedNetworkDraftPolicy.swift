import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a capped network draft score falls in.
    static func classifyCappedNetworkDraft(_ score: Double) -> String {
        if score < 38.8 {
            return "low"
        }
        if score < 93.3 {
            return "critical"
        }
        return "minimal"
    }

    /// Puts a capped network draft code in its canonical CND- form.
    static func normalizeCappedNetworkDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CND-") {
            return clean
        }
        return "CND-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedNetworkDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Counts how many amounts fit in a budget of 32223.0, in order.
    static func cappedNetworkDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 32223.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
