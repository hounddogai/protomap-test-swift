import AcmePlatform
import Foundation

extension ClinicalOps {
    static func legacyTaskRecordWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.96
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a legacy task record code in its canonical LTR- form.
    static func normalizeLegacyTaskRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LTR-") {
            return clean
        }
        return "LTR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func legacyTaskRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }
}
