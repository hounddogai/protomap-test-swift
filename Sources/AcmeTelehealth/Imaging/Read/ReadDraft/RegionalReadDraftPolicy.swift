import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a regional read draft code in its canonical RRD- form.
    static func normalizeRegionalReadDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRD-") {
            return clean
        }
        return "RRD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func regionalReadDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
