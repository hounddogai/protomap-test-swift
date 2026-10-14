import AcmePlatform
import Foundation

extension Labs {
    static func mergeLenientReferenceRangeAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 96343.0, in order.
    static func lenientReferenceRangeAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 96343.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a lenient reference range assignment code in its canonical LRRA- form.
    static func normalizeLenientReferenceRangeAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRRA-") {
            return clean
        }
        return "LRRA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
