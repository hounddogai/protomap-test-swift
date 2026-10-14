import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a shift snapshot code in its canonical SS- form.
    static func normalizeShiftSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SS-") {
            return clean
        }
        return "SS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func shiftSnapshotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 58844.0, in order.
    static func shiftSnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 58844.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
