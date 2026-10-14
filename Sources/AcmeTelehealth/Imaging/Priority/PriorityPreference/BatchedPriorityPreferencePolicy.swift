import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a batched priority preference code in its canonical BPP- form.
    static func normalizeBatchedPriorityPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BPP-") {
            return clean
        }
        return "BPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func batchedPriorityPreferenceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    static func batchedPriorityPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
