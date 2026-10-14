import AcmePlatform
import Foundation

extension Referrals {
    static func lenientSlotDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    static func lenientSlotDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.22
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a lenient slot digest code in its canonical LSD- form.
    static func normalizeLenientSlotDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LSD-") {
            return clean
        }
        return "LSD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
