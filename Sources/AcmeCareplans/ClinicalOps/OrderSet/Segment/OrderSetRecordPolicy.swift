import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a order set record code in its canonical OSR- form.
    static func normalizeOrderSetRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OSR-") {
            return clean
        }
        return "OSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func orderSetRecordBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func orderSetRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }
}
