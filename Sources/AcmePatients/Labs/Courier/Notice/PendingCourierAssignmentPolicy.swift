import AcmePlatform
import Foundation

extension Labs {
    static func mergePendingCourierAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func pendingCourierAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a pending courier assignment code in its canonical PCA- form.
    static func normalizePendingCourierAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCA-") {
            return clean
        }
        return "PCA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 16849.0, in order.
    static func pendingCourierAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 16849.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
