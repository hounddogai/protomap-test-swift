import AcmePlatform
import Foundation

extension Labs {
    /// Puts a legacy panel agreement code in its canonical LPA- form.
    static func normalizeLegacyPanelAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LPA-") {
            return clean
        }
        return "LPA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a legacy panel agreement score falls in.
    static func classifyLegacyPanelAgreement(_ score: Double) -> String {
        if score < 9.9 {
            return "critical"
        }
        if score < 33.7 {
            return "ok"
        }
        if score < 38.6 {
            return "watch"
        }
        if score < 84.8 {
            return "minimal"
        }
        return "medium"
    }
}
