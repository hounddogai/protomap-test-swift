import AcmePlatform
import Foundation

extension Labs {
    /// Puts a reference range batch code in its canonical RRB- form.
    static func normalizeReferenceRangeBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRB-") {
            return clean
        }
        return "RRB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func referenceRangeBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
