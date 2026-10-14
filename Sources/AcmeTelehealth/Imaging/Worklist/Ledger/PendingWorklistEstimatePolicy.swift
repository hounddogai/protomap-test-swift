import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a pending worklist estimate code in its canonical PWE- form.
    static func normalizePendingWorklistEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PWE-") {
            return clean
        }
        return "PWE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 7716.0, in order.
    static func pendingWorklistEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 7716.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergePendingWorklistEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func pendingWorklistEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
