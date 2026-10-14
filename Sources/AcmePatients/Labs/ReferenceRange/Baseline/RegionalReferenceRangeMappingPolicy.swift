import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 10605.0, in order.
    static func regionalReferenceRangeMappingBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 10605.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func regionalReferenceRangeMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a regional reference range mapping code in its canonical RRRM- form.
    static func normalizeRegionalReferenceRangeMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRRM-") {
            return clean
        }
        return "RRRM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a regional reference range mapping score falls in.
    static func classifyRegionalReferenceRangeMapping(_ score: Double) -> String {
        if score < 32.3 {
            return "high"
        }
        if score < 56.6 {
            return "medium"
        }
        return "minimal"
    }
}
