import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a care protocol allocation score falls in.
    static func classifyCareProtocolAllocation(_ score: Double) -> String {
        if score < 24.4 {
            return "low"
        }
        if score < 78.5 {
            return "critical"
        }
        return "elevated"
    }

    static func careProtocolAllocationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.72
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a care protocol allocation code in its canonical CPA- form.
    static func normalizeCareProtocolAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPA-") {
            return clean
        }
        return "CPA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
