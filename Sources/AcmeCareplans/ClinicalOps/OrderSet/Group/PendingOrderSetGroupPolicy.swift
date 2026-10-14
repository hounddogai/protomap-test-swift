import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a pending order set group code in its canonical POSG- form.
    static func normalizePendingOrderSetGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("POSG-") {
            return clean
        }
        return "POSG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 10564.0, in order.
    static func pendingOrderSetGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 10564.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func pendingOrderSetGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a pending order set group score falls in.
    static func classifyPendingOrderSetGroup(_ score: Double) -> String {
        if score < 49.1 {
            return "ok"
        }
        if score < 57.2 {
            return "watch"
        }
        if score < 59.7 {
            return "medium"
        }
        return "low"
    }
}
