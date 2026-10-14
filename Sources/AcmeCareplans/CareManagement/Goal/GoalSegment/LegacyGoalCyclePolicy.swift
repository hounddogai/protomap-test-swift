import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a legacy goal cycle score falls in.
    static func classifyLegacyGoalCycle(_ score: Double) -> String {
        if score < 43.1 {
            return "elevated"
        }
        if score < 56.4 {
            return "low"
        }
        if score < 66.5 {
            return "medium"
        }
        if score < 77.8 {
            return "ok"
        }
        return "watch"
    }

    /// Puts a legacy goal cycle code in its canonical LGC- form.
    static func normalizeLegacyGoalCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LGC-") {
            return clean
        }
        return "LGC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
