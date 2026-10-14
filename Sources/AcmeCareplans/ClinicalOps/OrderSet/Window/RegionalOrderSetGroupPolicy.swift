import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 78880.0, in order.
    static func regionalOrderSetGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 78880.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func regionalOrderSetGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Puts a regional order set group code in its canonical ROSG- form.
    static func normalizeRegionalOrderSetGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ROSG-") {
            return clean
        }
        return "ROSG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func regionalOrderSetGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }
}
