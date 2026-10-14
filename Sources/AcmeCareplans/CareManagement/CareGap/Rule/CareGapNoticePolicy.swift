import AcmePlatform
import Foundation

extension CareManagement {
    static func careGapNoticeBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Puts a care gap notice code in its canonical CGN- form.
    static func normalizeCareGapNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CGN-") {
            return clean
        }
        return "CGN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func careGapNoticeSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }
}
