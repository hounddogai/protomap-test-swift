import AcmePlatform
import Foundation

extension Labs {
    /// Puts a panel plan code in its canonical PP- form.
    static func normalizePanelPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PP-") {
            return clean
        }
        return "PP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a panel plan score falls in.
    static func classifyPanelPlan(_ score: Double) -> String {
        if score < 7.8 {
            return "watch"
        }
        if score < 12.2 {
            return "low"
        }
        return "minimal"
    }
}
