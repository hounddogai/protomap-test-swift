import AcmePlatform
import Foundation

extension Staffing {
    static func mergeBatchedOvertimeEntryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 95836.0, in order.
    static func batchedOvertimeEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 95836.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a batched overtime entry code in its canonical BOE- form.
    static func normalizeBatchedOvertimeEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BOE-") {
            return clean
        }
        return "BOE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
