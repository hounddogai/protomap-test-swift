import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a capped follow up checkpoint score falls in.
    static func classifyCappedFollowUpCheckpoint(_ score: Double) -> String {
        if score < 13.7 {
            return "critical"
        }
        if score < 20.3 {
            return "ok"
        }
        if score < 47.5 {
            return "watch"
        }
        return "low"
    }

    static func cappedFollowUpCheckpointBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Puts a capped follow up checkpoint code in its canonical CFUC- form.
    static func normalizeCappedFollowUpCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CFUC-") {
            return clean
        }
        return "CFUC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 15581.0, in order.
    static func cappedFollowUpCheckpointBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 15581.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
