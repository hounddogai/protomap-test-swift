import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a formulary baseline code in its canonical FB- form.
    static func normalizeFormularyBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FB-") {
            return clean
        }
        return "FB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func formularyBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
