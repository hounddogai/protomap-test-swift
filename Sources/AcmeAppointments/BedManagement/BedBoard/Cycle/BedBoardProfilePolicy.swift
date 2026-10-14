import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a bed board profile code in its canonical BBP- form.
    static func normalizeBedBoardProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BBP-") {
            return clean
        }
        return "BBP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func bedBoardProfileBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
