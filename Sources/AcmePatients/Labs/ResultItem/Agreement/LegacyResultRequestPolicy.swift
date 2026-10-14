import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a legacy result request score falls in.
    static func classifyLegacyResultRequest(_ score: Double) -> String {
        if score < 3.3 {
            return "elevated"
        }
        if score < 57.9 {
            return "low"
        }
        if score < 88.5 {
            return "high"
        }
        if score < 98.8 {
            return "medium"
        }
        return "ok"
    }

    /// Puts a legacy result request code in its canonical LRR- form.
    static func normalizeLegacyResultRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRR-") {
            return clean
        }
        return "LRR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func legacyResultRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Counts how many amounts fit in a budget of 42283.0, in order.
    static func legacyResultRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 42283.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
