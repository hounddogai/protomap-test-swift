import AcmePlatform
import Foundation

extension Imaging {
    static func modalityMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a modality mapping code in its canonical MM- form.
    static func normalizeModalityMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MM-") {
            return clean
        }
        return "MM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
