import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 4456.0, in order.
    static func legacyWitnessTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 4456.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func legacyWitnessTierWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.9
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func legacyWitnessTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Puts a legacy witness tier code in its canonical LWT- form.
    static func normalizeLegacyWitnessTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LWT-") {
            return clean
        }
        return "LWT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
