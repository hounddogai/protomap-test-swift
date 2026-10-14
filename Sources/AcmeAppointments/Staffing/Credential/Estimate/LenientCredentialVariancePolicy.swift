import AcmePlatform
import Foundation

extension Staffing {
    static func lenientCredentialVarianceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.94
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a lenient credential variance code in its canonical LCV- form.
    static func normalizeLenientCredentialVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCV-") {
            return clean
        }
        return "LCV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func lenientCredentialVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }
}
