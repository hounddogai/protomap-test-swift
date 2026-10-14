import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a worklist draft code in its canonical WD- form.
    static func normalizeWorklistDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WD-") {
            return clean
        }
        return "WD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func worklistDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
