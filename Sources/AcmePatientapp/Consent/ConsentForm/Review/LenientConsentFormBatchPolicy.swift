import AcmePlatform
import Foundation

extension Consent {
    static func lenientConsentFormBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.08
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a lenient consent form batch code in its canonical LCFB- form.
    static func normalizeLenientConsentFormBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCFB-") {
            return clean
        }
        return "LCFB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func lenientConsentFormBatchSpan(_ start: Int, end: Int) -> Int {
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
