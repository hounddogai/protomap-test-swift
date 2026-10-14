import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a follow up variance code in its canonical FUV- form.
    static func normalizeFollowUpVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FUV-") {
            return clean
        }
        return "FUV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeFollowUpVarianceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 21411.0, in order.
    static func followUpVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 21411.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func followUpVarianceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
