import AcmePlatform
import Foundation

extension Labs {
    static func referenceRangeVarianceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a reference range variance code in its canonical RRV- form.
    static func normalizeReferenceRangeVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRV-") {
            return clean
        }
        return "RRV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
