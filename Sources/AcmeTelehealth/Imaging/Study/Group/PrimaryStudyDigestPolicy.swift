import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a primary study digest code in its canonical PSD- form.
    static func normalizePrimaryStudyDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PSD-") {
            return clean
        }
        return "PSD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func primaryStudyDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    static func primaryStudyDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.16
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
