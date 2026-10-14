import AcmePlatform
import Foundation

extension Pharmacy {
    static func manualRecallQuotaSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Puts a manual recall quota code in its canonical MRQ- form.
    static func normalizeManualRecallQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MRQ-") {
            return clean
        }
        return "MRQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func manualRecallQuotaWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.38
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
