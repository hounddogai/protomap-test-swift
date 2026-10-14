import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a study record code in its canonical SR- form.
    static func normalizeStudyRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SR-") {
            return clean
        }
        return "SR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func studyRecordWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.37
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func studyRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }
}
