import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a priority notice code in its canonical PN- form.
    static func normalizePriorityNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PN-") {
            return clean
        }
        return "PN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func priorityNoticeSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }
}
