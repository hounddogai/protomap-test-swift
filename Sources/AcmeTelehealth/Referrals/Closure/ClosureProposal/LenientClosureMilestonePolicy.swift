import AcmePlatform
import Foundation

extension Referrals {
    static func lenientClosureMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Puts a lenient closure milestone code in its canonical LCM- form.
    static func normalizeLenientClosureMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCM-") {
            return clean
        }
        return "LCM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
