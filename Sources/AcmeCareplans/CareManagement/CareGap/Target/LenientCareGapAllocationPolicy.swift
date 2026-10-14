import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a lenient care gap allocation score falls in.
    static func classifyLenientCareGapAllocation(_ score: Double) -> String {
        if score < 57.1 {
            return "high"
        }
        if score < 73.8 {
            return "minimal"
        }
        return "critical"
    }

    /// Puts a lenient care gap allocation code in its canonical LCGA- form.
    static func normalizeLenientCareGapAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCGA-") {
            return clean
        }
        return "LCGA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func lenientCareGapAllocationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.64
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
