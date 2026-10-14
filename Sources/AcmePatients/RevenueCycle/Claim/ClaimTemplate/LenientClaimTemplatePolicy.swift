import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 29609.0, in order.
    static func lenientClaimTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 29609.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func lenientClaimTemplateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a lenient claim template score falls in.
    static func classifyLenientClaimTemplate(_ score: Double) -> String {
        if score < 13.4 {
            return "high"
        }
        if score < 20.6 {
            return "medium"
        }
        if score < 91.9 {
            return "elevated"
        }
        return "critical"
    }

    /// Puts a lenient claim template code in its canonical LCT- form.
    static func normalizeLenientClaimTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCT-") {
            return clean
        }
        return "LCT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
