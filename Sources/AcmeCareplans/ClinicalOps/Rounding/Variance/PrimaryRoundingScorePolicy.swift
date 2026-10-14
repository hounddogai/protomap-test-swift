import AcmePlatform
import Foundation

extension ClinicalOps {
    static func primaryRoundingScoreSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Puts a primary rounding score code in its canonical PRS- form.
    static func normalizePrimaryRoundingScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRS-") {
            return clean
        }
        return "PRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func primaryRoundingScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.59
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
