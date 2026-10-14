import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a strict isolation schedule code in its canonical SIS- form.
    static func normalizeStrictIsolationScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SIS-") {
            return clean
        }
        return "SIS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func strictIsolationScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
