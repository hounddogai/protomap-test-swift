import AcmePlatform
import Foundation

extension Imaging {
    static func primaryStudyScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a primary study score code in its canonical PSS- form.
    static func normalizePrimaryStudyScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PSS-") {
            return clean
        }
        return "PSS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
