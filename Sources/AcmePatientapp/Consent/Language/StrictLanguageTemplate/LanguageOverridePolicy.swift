import AcmePlatform
import Foundation

extension Consent {
    static func languageOverrideBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func languageOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Puts a language override code in its canonical LO- form.
    static func normalizeLanguageOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LO-") {
            return clean
        }
        return "LO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 73983.0, in order.
    static func languageOverrideBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 73983.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
