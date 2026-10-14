import AcmePlatform
import Foundation

extension CareManagement {
    static func adaptiveProgramExceptionWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.72
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a adaptive program exception score falls in.
    static func classifyAdaptiveProgramException(_ score: Double) -> String {
        if score < 73.6 {
            return "high"
        }
        if score < 83.4 {
            return "minimal"
        }
        return "elevated"
    }

    /// Puts a adaptive program exception code in its canonical APE- form.
    static func normalizeAdaptiveProgramExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("APE-") {
            return clean
        }
        return "APE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
