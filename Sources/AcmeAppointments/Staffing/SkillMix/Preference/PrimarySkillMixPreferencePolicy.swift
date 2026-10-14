import AcmePlatform
import Foundation

extension Staffing {
    static func primarySkillMixPreferenceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func primarySkillMixPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a primary skill mix preference code in its canonical PSMP- form.
    static func normalizePrimarySkillMixPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PSMP-") {
            return clean
        }
        return "PSMP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
