import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a default proxy rule score falls in.
    static func classifyDefaultProxyRule(_ score: Double) -> String {
        if score < 52.2 {
            return "high"
        }
        if score < 74.0 {
            return "watch"
        }
        if score < 95.8 {
            return "ok"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 69617.0, in order.
    static func defaultProxyRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 69617.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func defaultProxyRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a default proxy rule code in its canonical DPR- form.
    static func normalizeDefaultProxyRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DPR-") {
            return clean
        }
        return "DPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
