import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a program batch code in its canonical PB- form.
    static func normalizeProgramBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PB-") {
            return clean
        }
        return "PB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func programBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
