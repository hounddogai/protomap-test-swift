import AcmePlatform
import Foundation

extension Labs {
    /// Puts a pending specimen group code in its canonical PSG- form.
    static func normalizePendingSpecimenGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PSG-") {
            return clean
        }
        return "PSG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 39541.0, in order.
    static func pendingSpecimenGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 39541.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergePendingSpecimenGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
