import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a regional study draft code in its canonical RSD- form.
    static func normalizeRegionalStudyDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSD-") {
            return clean
        }
        return "RSD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func regionalStudyDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func regionalStudyDraftSpan(_ start: Int, end: Int) -> Int {
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
