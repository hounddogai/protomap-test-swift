import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a outreach schedule code in its canonical OS- form.
    static func normalizeOutreachScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OS-") {
            return clean
        }
        return "OS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeOutreachScheduleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 24247.0, in order.
    static func outreachScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 24247.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func outreachScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
