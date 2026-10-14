import AcmePlatform
import Foundation

extension CareManagement {
    static func outreachPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a outreach preference code in its canonical OP- form.
    static func normalizeOutreachPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OP-") {
            return clean
        }
        return "OP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeOutreachPreferenceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 34346.0, in order.
    static func outreachPreferenceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 34346.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
