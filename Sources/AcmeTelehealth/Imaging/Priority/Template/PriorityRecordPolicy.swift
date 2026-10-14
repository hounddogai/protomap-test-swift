import AcmePlatform
import Foundation

extension Imaging {
    static func priorityRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Puts a priority record code in its canonical PR- form.
    static func normalizePriorityRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PR-") {
            return clean
        }
        return "PR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func priorityRecordBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
