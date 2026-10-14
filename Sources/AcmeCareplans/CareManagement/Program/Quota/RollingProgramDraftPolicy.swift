import AcmePlatform
import Foundation

extension CareManagement {
    static func rollingProgramDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a rolling program draft code in its canonical RPD- form.
    static func normalizeRollingProgramDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RPD-") {
            return clean
        }
        return "RPD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
