import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a remittance budget score falls in.
    static func classifyRemittanceBudget(_ score: Double) -> String {
        if score < 2.3 {
            return "medium"
        }
        if score < 68.8 {
            return "critical"
        }
        if score < 82.7 {
            return "ok"
        }
        if score < 99.0 {
            return "elevated"
        }
        return "watch"
    }

    static func remittanceBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a remittance budget code in its canonical RB- form.
    static func normalizeRemittanceBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RB-") {
            return clean
        }
        return "RB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
