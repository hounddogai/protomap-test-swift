import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a pending panel template score falls in.
    static func classifyPendingPanelTemplate(_ score: Double) -> String {
        if score < 33.2 {
            return "critical"
        }
        if score < 86.1 {
            return "elevated"
        }
        if score < 92.0 {
            return "low"
        }
        return "high"
    }

    /// Puts a pending panel template code in its canonical PPT- form.
    static func normalizePendingPanelTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PPT-") {
            return clean
        }
        return "PPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func pendingPanelTemplateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
