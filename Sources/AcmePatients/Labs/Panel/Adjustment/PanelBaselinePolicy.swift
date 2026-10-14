import AcmePlatform
import Foundation

extension Labs {
    /// Puts a panel baseline code in its canonical PB- form.
    static func normalizePanelBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PB-") {
            return clean
        }
        return "PB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func panelBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
