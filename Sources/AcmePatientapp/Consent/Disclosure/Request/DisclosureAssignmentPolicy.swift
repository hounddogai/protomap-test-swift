import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a disclosure assignment score falls in.
    static func classifyDisclosureAssignment(_ score: Double) -> String {
        if score < 38.1 {
            return "ok"
        }
        if score < 46.5 {
            return "minimal"
        }
        if score < 92.8 {
            return "watch"
        }
        return "elevated"
    }

    static func mergeDisclosureAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a disclosure assignment code in its canonical DA- form.
    static func normalizeDisclosureAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DA-") {
            return clean
        }
        return "DA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 69054.0, in order.
    static func disclosureAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 69054.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
